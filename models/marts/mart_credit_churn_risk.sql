{{ config(materialized='table', schema='marts') }}

/*
============================================================================================
  Credit Churn Risk Analysis
  --------------------------
  This model identifies customers at risk of churning based on low credit balances
  and tracks actual churn events.
  
  REFACTORED: Now uses multiple intermediate models for DRY principles:
  - int_monthly_user_balances for balance data
  - int_user_active_subscriptions for subscription context
  - int_all_churned_users for churn events
  - int_plans_with_tiers for plan tier logic
============================================================================================
*/

SELECT
  bc.user_id,
  bc.month,
  bc.end_of_month_balance,
  p.plan_tier,
  CASE
    WHEN bc.end_of_month_balance < 10 THEN TRUE
    ELSE FALSE
  END AS low_balance_flag,
  CASE
    WHEN DATE_ADD(bc.month, INTERVAL 1 MONTH) = DATE(ct.churn_month) THEN TRUE
    ELSE FALSE
  END AS next_month_churn_flag
FROM {{ ref('int_monthly_user_balances') }} bc
LEFT JOIN {{ ref('int_user_active_subscriptions') }} s
  ON bc.user_id = s.user_id
 AND bc.month   = DATE(s.as_of_month)
LEFT JOIN {{ ref('int_plans_with_tiers') }} p
  ON s.plan_stripe_id = p.plan_stripe_id
LEFT JOIN {{ ref('int_all_churned_users') }} ct
  ON bc.user_id = ct.user_id
 AND DATE_ADD(bc.month, INTERVAL 1 MONTH) = DATE(ct.churn_month)
ORDER BY bc.month DESC, low_balance_flag DESC 