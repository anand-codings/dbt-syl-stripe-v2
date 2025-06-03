{{ config(materialized='table', schema='marts') }}

/*
============================================================================================
  Monthly Credit Balance Analysis
  ------------------------------
  This model tracks customer credit balances on a monthly basis, including:
  - Credits granted and spent each month
  - Running cumulative balance
  - Percentage of monthly allocation remaining
  - Months subscribed (customer tenure)
  
  REFACTORED: Now uses int_customer_tenure for DRY months_subscribed calculation.
============================================================================================
*/

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
  combined.user_id,
  combined.month,
  combined.credits_granted,
  combined.credits_spent,
  combined.net_change,

  -- Running total of net_change up to current month
  SUM(combined.net_change) OVER (
    PARTITION BY combined.user_id
    ORDER BY combined.month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_balance,

  -- % of this month's allocation that remains
  CASE
    WHEN combined.credits_granted = 0 THEN 0.0
    ELSE ROUND((combined.net_change * 1.0) / combined.credits_granted * 100, 1)
  END AS pct_remaining,

  -- Calculate months subscribed using the centralized tenure logic
  CASE
    WHEN ct.first_subscription_date IS NOT NULL THEN
      DATE_DIFF(
        DATE(combined.month),
        ct.first_subscription_date,
        MONTH
      ) + 1  -- Add 1 to include the first month
    ELSE NULL
  END AS months_subscribed

FROM combined
LEFT JOIN {{ ref('int_customer_tenure') }} ct
  ON combined.user_id = ct.customer_id
ORDER BY combined.user_id, combined.month 