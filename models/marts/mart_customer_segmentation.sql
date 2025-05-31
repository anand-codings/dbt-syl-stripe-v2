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

subscriptions_ranked AS (
    -- Get all subscriptions and rank them to find the latest/primary one for segmentation
    SELECT
        s.id AS subscription_id,
        s.customer AS customer_id,
        JSON_EXTRACT_SCALAR(s.plan_data, '$.id') AS plan_id, -- As per existing mart patterns
        s.status AS subscription_status,
        s.start_date AS subscription_start_date,
        s.created AS subscription_created_at,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer
            ORDER BY
                CASE s.status
                    WHEN 'active' THEN 1
                    WHEN 'trialing' THEN 2       -- Included for completeness, but most segments focus on paid
                    WHEN 'past_due' THEN 3
                    ELSE 4                      -- canceled, incomplete, incomplete_expired, unpaid
                END,
                s.start_date DESC,              -- Most recent start date
                s.created DESC                  -- Fallback to creation date
        ) AS rn
    FROM {{ ref('subscriptions') }} s
),

latest_customer_subscription_plan AS (
    -- Select the #1 ranked subscription for each customer and join to get plan details
    SELECT
        sr.customer_id,
        sr.subscription_id,
        sr.subscription_status,
        sr.subscription_start_date,
        p.stripe_id AS plan_stripe_id,
        COALESCE(p.nickname, p.stripe_id) AS plan_name, -- Using p.nickname; fallback to id. Adjust if product name needed via products
        p.interval AS plan_billing_interval,
        p.amount AS plan_amount_cents -- Amount in cents
    FROM subscriptions_ranked sr
    LEFT JOIN {{ ref('plans') }} p ON sr.plan_id = p.stripe_id
    WHERE sr.rn = 1
),

customer_first_paid_charge AS (
    -- Determine the first date a customer had a paid charge for tenure calculation
    SELECT
        customer AS customer_id,
        MIN(DATE(created)) AS first_paid_charge_date
    FROM {{ ref('charges_view') }}
    WHERE paid = TRUE
    GROUP BY 1
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

        -- Subscription Plan Segments
        COALESCE(lcsp.plan_name, 'Unknown') AS segment_plan_name,
        COALESCE(lcsp.plan_billing_interval, 'Unknown') AS segment_billing_interval,
        COALESCE(lcsp.subscription_status, 'No Subscription Info') AS segment_current_subscription_status,

        -- Tenure Segments
        cfpc.first_paid_charge_date,
        CASE
            WHEN cfpc.first_paid_charge_date IS NULL THEN 'No Paid Charges'
            ELSE
                CASE
                    WHEN DATE_DIFF(CURRENT_DATE(), cfpc.first_paid_charge_date, MONTH) < 6 THEN '0-5 Months Tenure'
                    WHEN DATE_DIFF(CURRENT_DATE(), cfpc.first_paid_charge_date, MONTH) < 12 THEN '6-11 Months Tenure'
                    WHEN DATE_DIFF(CURRENT_DATE(), cfpc.first_paid_charge_date, MONTH) < 24 THEN '12-23 Months Tenure' -- 1 to <2 years
                    ELSE '24+ Months Tenure' -- 2+ years
                END
        END AS segment_customer_tenure,

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
    LEFT JOIN latest_customer_subscription_plan lcsp ON c.customer_id = lcsp.customer_id
    LEFT JOIN customer_first_paid_charge cfpc ON c.customer_id = cfpc.customer_id
    LEFT JOIN customer_ltm_revenue cltm ON c.customer_id = cltm.customer_id
    LEFT JOIN (SELECT customer_id, account_country FROM customer_latest_invoice_geo WHERE rn = 1) clig
        ON c.customer_id = clig.customer_id
)

SELECT * FROM final_segmentation 