{{ config(materialized='table', schema='marts') }}

/*
============================================================================================
  Monthly Credit Allocation Analysis
  ----------------------------------
  This model tracks monthly credit allocations to users based on credit_histories.
  It identifies credit allocation events (positive amounts) and aggregates them by month.
  
  REFACTORED: Now uses int_monthly_credit_transactions for DRY credit logic.
  
  Used by:
  - mart_monthly_credit_balance
  - mart_credit_churn_usage_percentage (new)
============================================================================================
*/

SELECT
  user_id,
  month,
  credits_granted,
  allocation_count
FROM {{ ref('int_monthly_credit_transactions') }}
WHERE credits_granted > 0
ORDER BY user_id, month DESC 