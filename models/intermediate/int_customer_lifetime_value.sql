{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Customer Lifetime Value - Intermediate Model
  --------------------------------------------
  This model calculates customer lifetime value metrics based on their payment history.
  It provides a centralized calculation that can be reused across multiple churn and
  customer analysis models.
  
  Key Metrics:
  - Total captured revenue per customer (lifetime value)
  - Number of successful payments
  - Average payment amount
  - First and last payment dates
  - Customer payment tenure
  
  This model is used by:
  - mart_customer_churn_analysis
  - Any other models needing customer value calculations
============================================================================================
*/

WITH customer_payment_history AS (
  -- Get all successful payments for each customer
  SELECT
    customer AS customer_id,
    amount_captured / 100 AS payment_amount, -- Convert from cents to dollars
    DATE(created) AS payment_date,
    created AS payment_timestamp
  FROM {{ ref('charges_view') }}
  WHERE captured = TRUE
),

customer_lifetime_metrics AS (
  -- Calculate comprehensive lifetime value metrics
  SELECT
    customer_id,
    
    -- Core lifetime value metrics
    SUM(payment_amount) AS lifetime_value,
    COUNT(*) AS total_payments,
    ROUND(AVG(payment_amount), 2) AS avg_payment_amount,
    
    -- Payment timing metrics
    MIN(payment_date) AS first_payment_date,
    MAX(payment_date) AS last_payment_date,
    
    -- Customer payment tenure
    DATE_DIFF(MAX(payment_date), MIN(payment_date), DAY) AS payment_tenure_days,
    
    -- Payment frequency (payments per month for customers with >30 days tenure)
    CASE 
      WHEN DATE_DIFF(MAX(payment_date), MIN(payment_date), DAY) >= 30 THEN
        ROUND(COUNT(*) * 30.0 / DATE_DIFF(MAX(payment_date), MIN(payment_date), DAY), 2)
      ELSE NULL
    END AS avg_payments_per_month,
    
    -- Value segmentation
    CASE
      WHEN SUM(payment_amount) >= 1000 THEN 'High Value (>=$1000)'
      WHEN SUM(payment_amount) >= 500 THEN 'Medium Value ($500-$999)'
      WHEN SUM(payment_amount) >= 100 THEN 'Low Value ($100-$499)'
      ELSE 'Minimal Value (<$100)'
    END AS value_segment
    
  FROM customer_payment_history
  GROUP BY customer_id
)

SELECT * FROM customer_lifetime_metrics 