{{ config(materialized='table', schema='marts') }}

WITH alloc AS (
  SELECT user_id, month, credits_granted
  FROM {{ ref('mart_monthly_credit_allocation') }}
),

spent AS (
  SELECT user_id, month, SUM(credits_spent) AS credits_spent
  FROM {{ ref('mart_monthly_credit_usage') }}
  GROUP BY user_id, month
),

balance AS (
  SELECT user_id, month, cumulative_balance
  FROM {{ ref('mart_monthly_credit_balance') }}
),

video_counts AS (
  SELECT
    v.user_id,
    DATE_TRUNC(v.created_at, MONTH) AS month,
    COUNT(*) FILTER (WHERE v.type = 'faceless')       AS faceless_count,
    COUNT(*) FILTER (WHERE v.type = 'real_clone')     AS real_clone_count,
    COUNT(*) FILTER (WHERE v.type NOT IN ('faceless','real_clone')) AS other_videos,
    COUNT(*) AS total_video_count
  FROM {{ ref('videos') }} v
  GROUP BY v.user_id, DATE_TRUNC(v.created_at, MONTH)
),

subs_cte AS (
  SELECT
    s.customer                           AS user_id,
    DATE_TRUNC(s.current_period_end, MONTH) AS as_of_month,
    JSON_EXTRACT_SCALAR(s.plan_data, '$.id')  AS plan_stripe_id
  FROM {{ ref('subscriptions') }} s
  WHERE s.status = 'active'
),

plan_cte AS (
  SELECT
    stripe_id   AS plan_stripe_id,
    CASE
      WHEN amount >= 5000 AND interval = 'month' THEN 'Pro'
      WHEN amount < 5000 AND interval = 'month' THEN 'Basic'
      WHEN interval = 'year' THEN 'Enterprise'
      ELSE 'Other'
    END AS plan_tier
  FROM {{ ref('plans') }}
),

churn_cte AS (
  SELECT
    s.customer                     AS user_id,
    DATE_TRUNC(s.canceled_at, MONTH) AS churn_month
  FROM {{ ref('subscriptions') }} s
  WHERE s.status = 'canceled'
    AND s.canceled_at IS NOT NULL
)

SELECT
  COALESCE(a.user_id, s.user_id, b.user_id, v.user_id) AS user_id,
  COALESCE(a.month, s.as_of_month, b.month, v.month)   AS month,

  p.plan_tier,

  COALESCE(a.credits_granted, 0)    AS credits_granted,
  COALESCE(sp.credits_spent, 0)      AS credits_spent,
  COALESCE(b.cumulative_balance, 0)  AS cumulative_balance,

  COALESCE(v.total_video_count, 0)   AS total_video_count,
  COALESCE(v.faceless_count, 0)      AS faceless_count,
  COALESCE(v.real_clone_count, 0)    AS real_clone_count,
  COALESCE(v.other_videos, 0)        AS other_video_count,

  CASE
    WHEN DATE_ADD(COALESCE(a.month, s.as_of_month, b.month, v.month), INTERVAL 1 MONTH) = c.churn_month
    THEN TRUE
    ELSE FALSE
  END AS next_month_churn_flag
FROM alloc a
FULL OUTER JOIN subs_cte s
  ON a.user_id = s.user_id
 AND a.month   = s.as_of_month

FULL OUTER JOIN balance b
  ON COALESCE(a.user_id, s.user_id) = b.user_id
 AND COALESCE(a.month, s.as_of_month) = b.month

FULL OUTER JOIN video_counts v
  ON COALESCE(a.user_id, s.user_id, b.user_id) = v.user_id
 AND COALESCE(a.month, s.as_of_month, b.month) = v.month

FULL OUTER JOIN spent sp
  ON COALESCE(a.user_id, s.user_id, b.user_id, v.user_id) = sp.user_id
 AND COALESCE(a.month, s.as_of_month, b.month, v.month) = sp.month

LEFT JOIN plan_cte p
  ON s.plan_stripe_id = p.plan_stripe_id

LEFT JOIN churn_cte c
  ON COALESCE(a.user_id, s.user_id, b.user_id, v.user_id) = c.user_id
 AND DATE_ADD(COALESCE(a.month, s.as_of_month, b.month, v.month), INTERVAL 1 MONTH) = c.churn_month 