{{ config(materialized='table', schema='marts') }}

/*
============================================================================================
  Credits Left at Churn Analysis - DEBUG VERSION
  ------------------------------
  Temporarily simplified to debug why we're getting 0 rows
============================================================================================
*/

SELECT 
  COUNT(*) as total_churned_users,
  COUNT(DISTINCT customer) as unique_churned_customers,
  MIN(canceled_at) as earliest_churn,
  MAX(canceled_at) as latest_churn
FROM {{ ref('subscriptions') }}
WHERE status = 'canceled' 
  AND canceled_at IS NOT NULL 