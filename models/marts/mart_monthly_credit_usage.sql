{{ config(materialized='table', schema='marts') }}

WITH usage_events AS (
  SELECT
    ch.user_id,
    DATE_TRUNC(ch.created_at_ts, MONTH) AS month,
    ch.creditable_type      AS service_type,
    SUM(ch.amount * -1)     AS credits_spent,
    COUNT(*)                AS usage_count
  FROM {{ ref('credit_histories') }} ch
  JOIN {{ ref('credit_events') }} ce
    ON ch.credit_event_id = ce.credit_event_id
  WHERE ce.event_type = 'usage'
  GROUP BY ch.user_id, DATE_TRUNC(ch.created_at_ts, MONTH), ch.creditable_type
)

SELECT
  ue.user_id,
  ue.month,
  ue.service_type,
  ue.credits_spent,
  ue.usage_count
FROM usage_events ue
ORDER BY ue.user_id, ue.month DESC, ue.credits_spent DESC 