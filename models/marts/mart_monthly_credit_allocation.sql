{{ config(materialized='table', schema='marts') }}

WITH credit_allocations AS (
  SELECT
    ch.user_id,
    DATE_TRUNC(ch.created_at_ts, MONTH) AS month,
    ch.amount
  FROM {{ ref('credit_histories') }} ch
  JOIN {{ ref('credit_events') }} ce
    ON ch.credit_event_id = ce.credit_event_id
  WHERE ch.credit_history_event_type = 'credit'  -- Only credit allocations, not debits
    AND ch.amount > 0  -- Only positive amounts (allocations)
    AND ce.event_type != 'usage'  -- Exclude usage events
)

SELECT
  user_id,
  month,
  SUM(amount) AS credits_granted,
  'Unknown' AS plan_tier  -- Simplified for now
FROM credit_allocations
GROUP BY user_id, month
ORDER BY user_id, month 