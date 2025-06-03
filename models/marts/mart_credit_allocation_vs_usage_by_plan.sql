{{ config(materialized='table', schema='marts') }}

/*
============================================================================================
  Credit Allocation vs Usage by Plan Tier
  ---------------------------------------
  This model compares credit allocation and usage across different plan tiers.
  
  REFACTORED: Now uses int_plans_with_tiers for DRY plan tier logic.
============================================================================================
*/

WITH alloc_by_tier AS (
  SELECT
    plan_tier,
    month,
    SUM(credits_granted) AS sum_credits_granted
  FROM {{ ref('mart_monthly_credit_allocation') }}
  GROUP BY plan_tier, month
),

usage_with_plan AS (
  SELECT
    cmu.user_id,
    cmu.month,
    cmu.credits_spent,
    pl.plan_tier
  FROM {{ ref('mart_monthly_credit_usage') }} cmu
  JOIN {{ ref('subscriptions') }} s
    ON cmu.user_id = s.customer
   AND DATE_TRUNC(s.current_period_start, MONTH) = cmu.month
   AND s.status = 'active'
  JOIN {{ ref('int_plans_with_tiers') }} pl
    ON COALESCE(
      JSON_EXTRACT_SCALAR(s.plan_data, '$.id'),
      JSON_EXTRACT_SCALAR(s.items_data, '$[0].plan.id'),
      JSON_EXTRACT_SCALAR(s.items_data, '$[0].price.id')
    ) = pl.plan_stripe_id
),

usage_by_tier AS (
  SELECT
    plan_tier,
    month,
    SUM(credits_spent) AS sum_credits_spent
  FROM usage_with_plan
  GROUP BY plan_tier, month
)

SELECT
  abt.plan_tier,
  abt.month,
  abt.sum_credits_granted,
  COALESCE(ubt.sum_credits_spent, 0) AS sum_credits_spent,
  SAFE_DIVIDE(
    COALESCE(ubt.sum_credits_spent, 0),
    abt.sum_credits_granted
  ) * 100 AS pct_credits_spent
FROM alloc_by_tier abt
LEFT JOIN usage_by_tier ubt
  ON abt.plan_tier = ubt.plan_tier
 AND abt.month     = ubt.month
ORDER BY abt.month DESC, abt.plan_tier 