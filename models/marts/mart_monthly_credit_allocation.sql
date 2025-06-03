{{ config(materialized='table', schema='marts') }}

/*
============================================================================================
  Monthly Credit Allocation by Plan Tier
  --------------------------------------
  This model tracks credit allocations on a monthly basis, categorized by plan tier.
  
  REFACTORED: Now uses int_plans_with_tiers for DRY plan tier logic.
============================================================================================
*/

WITH allocation_events AS (
  SELECT
    ch.user_id,
    DATE_TRUNC(ch.created_at_ts, MONTH) AS month,
    SUM(ch.amount) AS credits_granted,
    COUNT(*) AS allocation_count
  FROM {{ ref('credit_histories') }} ch
  JOIN {{ ref('credit_events') }} ce
    ON ch.credit_event_id = ce.credit_event_id
  WHERE ce.event_type = '1'  -- Assuming '1' is for credit allocations/bonuses
    AND ch.amount > 0  -- Only positive amounts (credits granted)
  GROUP BY ch.user_id, DATE_TRUNC(ch.created_at_ts, MONTH)
),

-- Get user subscription and plan information for each month
user_subscriptions AS (
  SELECT
    s.customer AS user_id,
    DATE_TRUNC(s.current_period_start, MONTH) AS month,
    JSON_EXTRACT_SCALAR(s.plan_data, '$.id') AS plan_stripe_id,
    s.status AS subscription_status
  FROM {{ ref('subscriptions') }} s
  WHERE s.current_period_start IS NOT NULL
)

SELECT
  COALESCE(ae.user_id, us.user_id) AS user_id,
  COALESCE(ae.month, us.month) AS month,
  COALESCE(ae.credits_granted, 0) AS credits_granted,
  COALESCE(ae.allocation_count, 0) AS allocation_count,
  pt.plan_tier,
  us.subscription_status
FROM allocation_events ae
FULL OUTER JOIN user_subscriptions us
  ON ae.user_id = us.user_id
  AND ae.month = us.month
LEFT JOIN {{ ref('int_plans_with_tiers') }} pt
  ON us.plan_stripe_id = pt.plan_stripe_id
ORDER BY user_id, month 