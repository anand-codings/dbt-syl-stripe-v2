{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  All Churned Users - Intermediate Model (No Time Filter)
  -------------------------------------------------------
  This model identifies all users who have churned (canceled their subscriptions)
  without any time period filtering, complementing int_churned_users_6m which has a
  6-month lookback filter.
  
  Key Logic:
  - Identifies all canceled subscriptions (no time filter)
  - Provides churn month for temporal analysis
  - Simplified version focused on churn timing
  
  This model is used by:
  - mart_credit_churn_risk
  - Any other models needing all-time churn data
============================================================================================
*/

SELECT
  customer       AS user_id,
  DATE_TRUNC(canceled_at, MONTH) AS churn_month,
  canceled_at,
  status
FROM {{ ref('subscriptions') }}
WHERE status = 'canceled'
  AND canceled_at IS NOT NULL 