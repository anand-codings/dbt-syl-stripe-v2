{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Customer Tenure
  ---------------
  This intermediate model provides customer tenure calculations based on their
  first paid charge date, extracted from the customer segmentation logic for
  reuse across multiple mart models.
  
  This model is used by:
  - mart_customer_segmentation
  - mart_monthly_credit_balance (months_subscribed calculation)
  - Any other marts needing customer tenure info
============================================================================================
*/

WITH customer_first_paid_charge AS (
  -- Determine the first date a customer had a paid charge for tenure calculation
  SELECT
    customer AS customer_id,
    MIN(DATE(created)) AS first_paid_charge_date
  FROM {{ ref('charges_view') }}
  WHERE paid = TRUE
  GROUP BY 1
),

customer_first_subscription AS (
  -- Also track first subscription start date as an alternative tenure measure
  SELECT
    customer AS customer_id,
    MIN(DATE(start_date)) AS first_subscription_date
  FROM {{ ref('subscriptions') }}
  WHERE start_date IS NOT NULL
  GROUP BY 1
),

customer_tenure_calculations AS (
  SELECT
    COALESCE(cfpc.customer_id, cfs.customer_id) AS customer_id,
    cfpc.first_paid_charge_date,
    cfs.first_subscription_date,
    
    -- Tenure based on first paid charge
    CASE
      WHEN cfpc.first_paid_charge_date IS NULL THEN 'No Paid Charges'
      ELSE
        CASE
          WHEN DATE_DIFF(CURRENT_DATE(), cfpc.first_paid_charge_date, MONTH) < 6 THEN '0-5 Months Tenure'
          WHEN DATE_DIFF(CURRENT_DATE(), cfpc.first_paid_charge_date, MONTH) < 12 THEN '6-11 Months Tenure'
          WHEN DATE_DIFF(CURRENT_DATE(), cfpc.first_paid_charge_date, MONTH) < 24 THEN '12-23 Months Tenure'
          ELSE '24+ Months Tenure'
        END
    END AS tenure_segment,
    
    -- Months since first paid charge
    CASE
      WHEN cfpc.first_paid_charge_date IS NOT NULL THEN
        DATE_DIFF(CURRENT_DATE(), cfpc.first_paid_charge_date, MONTH)
      ELSE NULL
    END AS months_since_first_charge,
    
    -- Months since first subscription (for credit balance calculations)
    CASE
      WHEN cfs.first_subscription_date IS NOT NULL THEN
        DATE_DIFF(CURRENT_DATE(), cfs.first_subscription_date, MONTH) + 1
      ELSE NULL
    END AS months_subscribed
    
  FROM customer_first_paid_charge cfpc
  FULL OUTER JOIN customer_first_subscription cfs
    ON cfpc.customer_id = cfs.customer_id
)

SELECT * FROM customer_tenure_calculations 