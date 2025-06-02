{{ config(materialized='table', schema='marts') }}

WITH credit_by_service AS (
  SELECT
    service_type,
    month,
    SUM(credits_spent) AS total_credits_spent
  FROM {{ ref('mart_monthly_credit_usage') }}
  GROUP BY service_type, month
),

service_counts AS (
  SELECT
    'faceless'      AS service_type,
    DATE_TRUNC(created_at, MONTH) AS month,
    COUNT(*)         AS service_count
  FROM {{ ref('facelesses') }}
  GROUP BY DATE_TRUNC(created_at, MONTH)

  UNION ALL

  SELECT
    'real_clone'    AS service_type,
    DATE_TRUNC(created_at, MONTH) AS month,
    COUNT(*)         AS service_count
  FROM {{ ref('real_clones') }}
  GROUP BY DATE_TRUNC(created_at, MONTH)

  UNION ALL

  SELECT
    'caption'       AS service_type,
    DATE_TRUNC(created_at, MONTH) AS month,
    COUNT(*)         AS service_count
  FROM {{ ref('captions') }}
  GROUP BY DATE_TRUNC(created_at, MONTH)

  -- Add other service types similarly…
)

SELECT
  cbs.service_type,
  cbs.month,
  cbs.total_credits_spent,
  sc.service_count,
  SAFE_DIVIDE(cbs.total_credits_spent, sc.service_count) AS avg_credits_per_unit
FROM credit_by_service cbs
LEFT JOIN service_counts sc
  ON cbs.service_type = sc.service_type
 AND cbs.month        = sc.month
ORDER BY cbs.month DESC, cbs.service_type 