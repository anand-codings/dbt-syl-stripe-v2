{{ config(
    materialized='table',
    schema='marts'
) }}

/*
============================================================================================
  Monthly Customer Churn and Revenue Impact Analysis
  ------------------------------------------------------------------------------------------
  Description:
  Analyzes customer churn patterns over the last 6 months, segmenting by churn type 
  (voluntary vs payment failure) and quantifying the revenue impact through customer 
  lifetime value metrics.

  REFACTORED: Now uses intermediate models for better maintainability and reusability:
  - int_customer_lifetime_value for customer value calculations
  - int_all_churned_users for churn identification (with time filtering)

  Business Questions Answered:
  - What is the monthly trend in customer churn rate?
  - How much revenue is lost due to churned customers each month?
  - What proportion of churn is due to payment failures vs voluntary cancellations?
  - What is the average value of churned customers?

  Key Metrics Calculated:
  - churned_customers_count: Total number of customers who canceled in each month
  - total_churned_value: Total lifetime value of churned customers (in currency)
  - avg_customer_value: Average lifetime spend per churned customer
  - payment_failure_churns: Number of customers who churned due to payment issues
  - voluntary_churns: Number of customers who actively requested cancellation

  Data Sources (Tables Used):
  - int_customer_lifetime_value: Customer payment/revenue data
  - subscriptions: Subscription status and cancellation details

  CTEs Explanation:
  - churned_customers_6m: Identifies and categorizes churned customers in last 6 months

  Use Cases / Potential Insights:
  - Identify trends in churn reasons to guide retention strategies
  - Quantify revenue impact of churn for financial forecasting
  - Track effectiveness of payment failure prevention measures
  - Monitor voluntary churn patterns for product/service improvements

  Potential Next Steps / Further Analysis:
  - Segment churned customers by subscription plan type
  - Analyze correlation between customer tenure and churn likelihood
  - Compare churned customer value against active customer benchmarks
  - Investigate patterns in voluntary cancellation reasons
============================================================================================
*/

WITH churned_customers_6m AS (
  -- List every canceled subscription in the last 6 months
  SELECT
    s.customer             AS customer_id,
    DATE_TRUNC(DATE(s.canceled_at), MONTH) AS churn_month,
    s.cancellation_details AS cancellation_reason
  FROM {{ ref('subscriptions') }} s
  WHERE s.status = 'canceled'
    AND s.canceled_at >= TIMESTAMP(DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH), MONTH))
    AND s.canceled_at < TIMESTAMP(DATE_TRUNC(CURRENT_DATE(), MONTH)) -- Exclude current incomplete month
)

SELECT
  CASE
    WHEN churn_month IS NULL THEN 'TOTAL'
    ELSE FORMAT_DATE('%Y-%m', cc.churn_month)
  END                                   AS churn_month,
  
  COUNT(DISTINCT cc.customer_id)        AS churned_customers_count,

  -- Format total churned value with dollar sign and commas
  FORMAT("$%'d", CAST(ROUND(COALESCE(SUM(clv.lifetime_value), 0)) AS INT64)) AS total_churned_value,

  -- Format average customer value with dollar sign and commas
  FORMAT("$%'d", CAST(ROUND(COALESCE(AVG(clv.lifetime_value), 0)) AS INT64)) AS avg_customer_value,

  -- Count payment failure churns
  COUNT(DISTINCT CASE
    WHEN JSON_EXTRACT_SCALAR(cc.cancellation_reason, '$.reason') = 'payment_failed'
    THEN cc.customer_id
  END) AS payment_failure_churns,

  -- Count voluntary churns
  COUNT(DISTINCT CASE
    WHEN JSON_EXTRACT_SCALAR(cc.cancellation_reason, '$.reason') = 'cancellation_requested'
    THEN cc.customer_id
  END) AS voluntary_churns,

  -- Calculate churn percentages
  ROUND(
    COUNT(DISTINCT CASE
      WHEN JSON_EXTRACT_SCALAR(cc.cancellation_reason, '$.reason') = 'payment_failed'
      THEN cc.customer_id
    END) * 100.0 / NULLIF(COUNT(DISTINCT cc.customer_id), 0), 
    1
  ) AS payment_failure_churn_pct,

  ROUND(
    COUNT(DISTINCT CASE
      WHEN JSON_EXTRACT_SCALAR(cc.cancellation_reason, '$.reason') = 'cancellation_requested'
      THEN cc.customer_id
    END) * 100.0 / NULLIF(COUNT(DISTINCT cc.customer_id), 0), 
    1
  ) AS voluntary_churn_pct

FROM churned_customers_6m cc
LEFT JOIN {{ ref('int_customer_lifetime_value') }} clv
  ON cc.customer_id = clv.customer_id

GROUP BY
  ROLLUP(cc.churn_month)
ORDER BY
  CASE WHEN churn_month = 'TOTAL' THEN 1 ELSE 0 END,
  cc.churn_month DESC 