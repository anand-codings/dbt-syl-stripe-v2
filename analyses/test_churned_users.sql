-- Test query to check for churned users
SELECT 
  COUNT(*) as total_churned_users,
  MIN(canceled_at) as earliest_churn,
  MAX(canceled_at) as latest_churn
FROM {{ ref('subscriptions') }}
WHERE status = 'canceled' 
  AND canceled_at IS NOT NULL

UNION ALL

SELECT 
  COUNT(*) as total_users_with_credits,
  MIN(created_at_ts) as earliest_user,
  MAX(created_at_ts) as latest_user
FROM {{ ref('users') }}
WHERE remaining_credit_amount IS NOT NULL

UNION ALL

SELECT 
  COUNT(*) as total_credit_transactions,
  MIN(created_at_ts) as earliest_transaction,
  MAX(created_at_ts) as latest_transaction
FROM {{ ref('credit_histories') }} 