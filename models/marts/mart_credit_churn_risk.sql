{{ config(materialized='table', schema='marts') }}

WITH balance_cte AS (
  SELECT
    user_id,
    DATE(month) AS month,
    cumulative_balance AS end_of_month_balance
  FROM {{ ref('mart_monthly_credit_balance') }}
),

churn_cte AS (
  SELECT
    customer       AS user_id,
    DATE_TRUNC(canceled_at, MONTH) AS churn_month
  FROM {{ ref('subscriptions') }}
  WHERE status = 'canceled'
    AND canceled_at IS NOT NULL
),

subs_cte AS (
  SELECT
    s.customer           AS user_id,
    JSON_EXTRACT_SCALAR(s.plan_data, '$.id') AS plan_stripe_id,
    DATE_TRUNC(s.current_period_end, MONTH)  AS as_of_month
  FROM {{ ref('subscriptions') }} s
  WHERE s.status = 'active'
),

plan_cte AS (
  SELECT
    stripe_id   AS plan_stripe_id,
    CASE
      WHEN amount >= 5000 AND `interval` = 'month' THEN 'Pro'
      WHEN amount < 5000 AND `interval` = 'month' THEN 'Basic'
      WHEN `interval` = 'year' THEN 'Enterprise'
      ELSE 'Other'
    END AS plan_tier
  FROM {{ ref('plans') }}
)

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
FROM balance_cte bc
LEFT JOIN subs_cte s
  ON bc.user_id = s.user_id
 AND bc.month   = DATE(s.as_of_month)
LEFT JOIN plan_cte p
  ON s.plan_stripe_id = p.plan_stripe_id
LEFT JOIN churn_cte ct
  ON bc.user_id = ct.user_id
 AND DATE_ADD(bc.month, INTERVAL 1 MONTH) = DATE(ct.churn_month)
ORDER BY bc.month DESC, low_balance_flag DESC 