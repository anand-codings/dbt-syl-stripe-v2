{{ config(materialized='table', schema='marts') }}

WITH alloc AS (
  SELECT
    user_id,
    month,
    credits_granted
  FROM {{ ref('mart_monthly_credit_allocation') }}
),

spent AS (
  SELECT
    user_id,
    month,
    SUM(credits_spent) AS credits_spent
  FROM {{ ref('mart_monthly_credit_usage') }}
  GROUP BY user_id, month
),

combined AS (
  SELECT
    COALESCE(a.user_id, s.user_id) AS user_id,
    COALESCE(a.month, s.month)       AS month,
    COALESCE(a.credits_granted, 0)    AS credits_granted,
    COALESCE(s.credits_spent, 0)      AS credits_spent,
    COALESCE(a.credits_granted, 0) - COALESCE(s.credits_spent, 0) AS net_change
  FROM alloc a
  FULL OUTER JOIN spent s
    ON a.user_id = s.user_id
   AND a.month   = s.month
)

SELECT
  user_id,
  month,
  credits_granted,
  credits_spent,
  net_change,

  -- Running total of net_change up to current month
  SUM(net_change) OVER (
    PARTITION BY user_id
    ORDER BY month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_balance,

  -- % of this month's allocation that remains
  CASE
    WHEN credits_granted = 0 THEN 0.0
    ELSE ROUND((net_change * 1.0) / credits_granted * 100, 1)
  END AS pct_remaining

FROM combined
ORDER BY user_id, month 