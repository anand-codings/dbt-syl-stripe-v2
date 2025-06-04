-- Check subscription statuses to understand why no churn data
SELECT 
  status,
  COUNT(*) as subscription_count,
  COUNT(DISTINCT customer) as unique_customers,
  MIN(created_at) as earliest_subscription,
  MAX(created_at) as latest_subscription,
  COUNT(CASE WHEN canceled_at IS NOT NULL THEN 1 END) as has_canceled_at
FROM {{ ref('subscriptions') }}
GROUP BY status
ORDER BY subscription_count DESC 