{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Monthly Credit Transactions - Intermediate Model
  ------------------------------------------------
  This model provides a unified view of monthly credit transactions (both allocations
  and usage) for users. It consolidates logic that was previously duplicated across
  multiple credit-related mart models.
  
  Transaction Types:
  - Allocations: Positive credit amounts (event_type '1' and 'bonus')
  - Usage: Negative credit amounts (event_type '2')
  
  Key Metrics:
  - Monthly credits granted per user
  - Monthly credits spent per user by service type
  - Net credit change per user per month
  - Transaction counts for activity analysis
  
  This model is used by:
  - mart_monthly_credit_allocation (can be refactored to use this)
  - mart_monthly_credit_usage (can be refactored to use this)
  - mart_credit_churn_usage_percentage
  - Any other models needing monthly credit transaction data
============================================================================================
*/

WITH credit_allocations AS (
  -- Get credit allocations (positive amounts) by user and month
  SELECT
    ch.user_id,
    DATE_TRUNC(ch.created_at_ts, MONTH) AS month,
    'allocation' AS transaction_type,
    NULL AS service_type, -- Allocations don't have service types
    SUM(ch.amount) AS credit_amount,
    COUNT(*) AS transaction_count
  FROM {{ ref('credit_histories') }} ch
  JOIN {{ ref('credit_events') }} ce
    ON ch.credit_event_id = ce.credit_event_id
  WHERE ch.amount > 0  -- Only positive amounts (allocations)
    AND ce.event_type IN ('1', 'bonus')  -- Allocation and bonus events
  GROUP BY ch.user_id, DATE_TRUNC(ch.created_at_ts, MONTH)
),

credit_usage AS (
  -- Get credit usage (negative amounts) by user, month, and service type
  SELECT
    ch.user_id,
    DATE_TRUNC(ch.created_at_ts, MONTH) AS month,
    'usage' AS transaction_type,
    ch.creditable_type AS service_type,
    SUM(ch.amount) AS credit_amount, -- Keep as negative for usage
    COUNT(*) AS transaction_count
  FROM {{ ref('credit_histories') }} ch
  JOIN {{ ref('credit_events') }} ce
    ON ch.credit_event_id = ce.credit_event_id
  WHERE ch.amount < 0  -- Only negative amounts (usage)
    AND ce.event_type = '2'  -- Usage events
  GROUP BY ch.user_id, DATE_TRUNC(ch.created_at_ts, MONTH), ch.creditable_type
),

all_credit_transactions AS (
  -- Combine allocations and usage
  SELECT * FROM credit_allocations
  UNION ALL
  SELECT * FROM credit_usage
),

monthly_credit_summary AS (
  -- Create summary metrics per user per month
  SELECT
    user_id,
    month,
    
    -- Allocation metrics
    SUM(CASE WHEN transaction_type = 'allocation' THEN credit_amount ELSE 0 END) AS credits_granted,
    SUM(CASE WHEN transaction_type = 'allocation' THEN transaction_count ELSE 0 END) AS allocation_count,
    
    -- Usage metrics (convert negative to positive for easier interpretation)
    SUM(CASE WHEN transaction_type = 'usage' THEN credit_amount * -1 ELSE 0 END) AS credits_spent,
    SUM(CASE WHEN transaction_type = 'usage' THEN transaction_count ELSE 0 END) AS usage_count,
    
    -- Net change
    SUM(credit_amount) AS net_credit_change,
    
    -- Service type breakdown for usage (as JSON for flexibility)
    ARRAY_AGG(
      CASE 
        WHEN transaction_type = 'usage' THEN 
          STRUCT(
            service_type,
            credit_amount * -1 AS credits_spent,
            transaction_count
          )
        ELSE NULL
      END 
      IGNORE NULLS
    ) AS usage_by_service_type,
    
    -- Calculate percentage of monthly allocation used
    CASE
      WHEN SUM(CASE WHEN transaction_type = 'allocation' THEN credit_amount ELSE 0 END) > 0 THEN 
        ROUND(
          (SUM(CASE WHEN transaction_type = 'usage' THEN credit_amount * -1 ELSE 0 END) * 100.0) / 
          SUM(CASE WHEN transaction_type = 'allocation' THEN credit_amount ELSE 0 END), 
          2
        )
      ELSE 0.0
    END AS pct_monthly_allocation_used
    
  FROM all_credit_transactions
  GROUP BY user_id, month
)

SELECT
  user_id,
  month,
  credits_granted,
  credits_spent,
  net_credit_change,
  allocation_count,
  usage_count,
  pct_monthly_allocation_used,
  usage_by_service_type
FROM monthly_credit_summary
WHERE credits_granted > 0 OR credits_spent > 0 -- Only include months with actual credit activity 