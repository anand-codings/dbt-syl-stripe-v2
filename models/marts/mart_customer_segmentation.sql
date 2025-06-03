{{ config(
    materialized='table',
    schema='marts'
) }}

/*
============================================================================================
  Customer Segmentation Analysis
  ------------------------------
  This model groups customers based on various attributes including:
    - Latest subscription plan and billing interval
    - Customer tenure (time since first paid charge)
    - Last Twelve Months (LTM) revenue tiers
    - Geographic location (from invoice data)
    - Custom metadata segments
  
  The results provide a comprehensive view of customer segments for targeted analysis.
  
  REFACTORED: Now uses int_customer_latest_subscription and int_customer_tenure 
  for DRY reusable logic.
============================================================================================
*/

WITH customers AS (
    SELECT
        id AS customer_id,
        created AS customer_created_at
        -- Note: metadata_ column not available in customers_view
        -- shipping -- JSON field, could be parsed for detailed geo-segmentation if needed
    FROM {{ ref('customers_view') }}
),

customer_ltm_revenue AS (
    -- Calculate Last Twelve Months (LTM) revenue for each customer
    SELECT
        customer AS customer_id,
        SUM(amount_captured / 100.0) AS ltm_revenue -- Assuming amount is in cents
    FROM {{ ref('charges_view') }}
    WHERE
        paid = TRUE
        AND DATE(created) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
        AND DATE(created) < CURRENT_DATE() -- Up to yesterday
    GROUP BY 1
),

customer_latest_invoice_geo AS (
    -- Attempt to get geographic information from the customer's latest invoice's account_country
    SELECT
        customer AS customer_id,
        account_country,
        ROW_NUMBER() OVER (PARTITION BY customer ORDER BY created DESC) as rn
    FROM {{ ref('invoices_view') }}
    WHERE account_country IS NOT NULL
),

final_segmentation AS (
    SELECT
        c.customer_id,

        -- Subscription Plan Segments (using int_customer_latest_subscription)
        COALESCE(lcsp.plan_name, 'Unknown') AS segment_plan_name,
        COALESCE(lcsp.plan_billing_interval, 'Unknown') AS segment_billing_interval,
        COALESCE(lcsp.subscription_status, 'No Subscription Info') AS segment_current_subscription_status,

        -- Tenure Segments (using int_customer_tenure)
        ct.first_paid_charge_date,
        COALESCE(ct.tenure_segment, 'No Paid Charges') AS segment_customer_tenure,

        -- Revenue Segments
        COALESCE(cltm.ltm_revenue, 0) AS ltm_revenue,
        CASE
            WHEN COALESCE(cltm.ltm_revenue, 0) <= 0 THEN 'No LTM Revenue'
            WHEN cltm.ltm_revenue < 100 THEN 'LTM Revenue < $100'
            WHEN cltm.ltm_revenue < 500 THEN 'LTM Revenue $100-$499'
            WHEN cltm.ltm_revenue < 1000 THEN 'LTM Revenue $500-$999'
            ELSE 'LTM Revenue $1000+'
        END AS segment_ltm_revenue_tier,

        -- Geographic Segments
        COALESCE(clig.account_country, 'Unknown') AS segment_geo_country,

        -- Custom Metadata Segments (not available in current customers_view)
        -- Note: These would need to be added if metadata_ column becomes available
        NULL AS segment_metadata_tier,
        NULL AS segment_metadata_industry,

        -- Timestamps
        c.customer_created_at

        -- Developer Notes:
        -- To add 'Acquisition Source' or 'Usage Pattern' segments, relevant data sources
        -- would need to be staged and then incorporated into this model.
        -- Example: segment_acquisition_source (e.g., 'Organic', 'Paid Search', 'Referral')
        -- Example: segment_usage_metric_tier (e.g., 'Low Usage', 'Medium Usage', 'High Usage')

    FROM customers c
    LEFT JOIN {{ ref('int_customer_latest_subscription') }} lcsp ON c.customer_id = lcsp.customer_id
    LEFT JOIN {{ ref('int_customer_tenure') }} ct ON c.customer_id = ct.customer_id
    LEFT JOIN customer_ltm_revenue cltm ON c.customer_id = cltm.customer_id
    LEFT JOIN (SELECT customer_id, account_country FROM customer_latest_invoice_geo WHERE rn = 1) clig
        ON c.customer_id = clig.customer_id
)

SELECT * FROM final_segmentation 