{{ config(materialized='table', schema='marts') }}

/*
============================================================================================
  Monthly Credit Usage Analysis
  -----------------------------
  This model tracks monthly credit usage by users and service types based on 
  credit_histories. It identifies credit usage events (negative amounts) and 
  aggregates them by month and service type.
  
  REFACTORED: Now uses int_monthly_credit_transactions for DRY credit logic.
  
  Used by:
  - mart_monthly_credit_balance
  - mart_service_credit_efficiency
============================================================================================
*/

WITH usage_by_service AS (
  -- Unnest the service type breakdown from the intermediate model
  SELECT
    user_id,
    month,
    service_detail.service_type,
    service_detail.credits_spent,
    service_detail.transaction_count AS usage_count
  FROM {{ ref('int_monthly_credit_transactions') }} mct
  CROSS JOIN UNNEST(mct.usage_by_service_type) AS service_detail
  WHERE ARRAY_LENGTH(mct.usage_by_service_type) > 0
)

SELECT
  user_id,
  month,
  service_type,
  credits_spent,
  usage_count
FROM usage_by_service
ORDER BY user_id, month DESC, credits_spent DESC 