{{ config(materialized='table', schema='marts') }}

WITH

first_paid AS (
  SELECT
    customer                                      AS user_id,
    MIN(DATE_TRUNC(DATE(created), MONTH))         AS first_paid_month
  FROM {{ ref('charges_view') }}
  WHERE paid = TRUE
  GROUP BY customer
),

monthly_usage AS (
  SELECT
    user_id,
    month,
    SUM(credits_spent) AS total_credits_spent
  FROM {{ ref('mart_monthly_credit_usage') }}
  GROUP BY user_id, month
),

usage_with_tenure AS (
  SELECT
    mu.user_id,
    mu.month,
    mu.total_credits_spent,
    fp.first_paid_month,
    DATE_DIFF(mu.month, fp.first_paid_month, MONTH) AS tenure_in_months
  FROM monthly_usage mu
  JOIN first_paid fp
    ON mu.user_id = fp.user_id
  WHERE mu.month >= fp.first_paid_month
),

filtered_usage AS (
  SELECT
    user_id,
    month,
    total_credits_spent,
    tenure_in_months
  FROM usage_with_tenure
  WHERE tenure_in_months >= 0
)

SELECT
  month,
  tenure_in_months,
  ROUND(AVG(total_credits_spent), 1) AS avg_credits_spent,
  COUNT(DISTINCT user_id)           AS num_users_in_bucket
FROM filtered_usage
GROUP BY month, tenure_in_months
ORDER BY month DESC, tenure_in_months 