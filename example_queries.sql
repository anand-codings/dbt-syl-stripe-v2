-- Example Queries for Credit Churn Usage Percentage Analysis
-- ===========================================================

-- 1. Basic monthly churn credit usage overview
SELECT 
  churn_month,
  churned_users_count,
  avg_pct_allocation_used,
  median_pct_allocation_used,
  total_pct_credits_used,
  avg_cumulative_balance_at_churn
FROM {{ ref('mart_credit_churn_usage_percentage') }}
ORDER BY churn_month DESC;

-- 2. Identify months with high credit usage before churn
SELECT 
  churn_month,
  churned_users_count,
  avg_pct_allocation_used,
  CASE 
    WHEN avg_pct_allocation_used > 80 THEN 'High Usage Churn'
    WHEN avg_pct_allocation_used > 50 THEN 'Medium Usage Churn'
    ELSE 'Low Usage Churn'
  END as usage_category
FROM {{ ref('mart_credit_churn_usage_percentage') }}
WHERE churned_users_count > 0
ORDER BY churn_month DESC;

-- 3. Analyze plan tier differences in churn credit usage
SELECT 
  churn_month,
  tier.plan_tier,
  tier.tier_churned_count,
  tier.tier_avg_pct_used
FROM {{ ref('mart_credit_churn_usage_percentage') }} ccup
CROSS JOIN UNNEST(ccup.plan_tier_breakdown) as tier
WHERE tier.tier_churned_count > 0
ORDER BY churn_month DESC, tier.tier_avg_pct_used DESC;

-- 4. Compare credit usage patterns between churned and active users
WITH churned_usage AS (
  SELECT 
    AVG(avg_pct_allocation_used) as avg_churned_usage,
    AVG(median_pct_allocation_used) as median_churned_usage
  FROM {{ ref('mart_credit_churn_usage_percentage') }}
  WHERE churned_users_count > 0
),
active_usage AS (
  SELECT 
    AVG(CASE 
      WHEN credits_granted > 0 THEN (credits_spent * 100.0) / credits_granted 
      ELSE 0 
    END) as avg_active_usage
  FROM {{ ref('mart_monthly_credit_balance') }}
  WHERE month >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
    AND credits_granted > 0
)
SELECT 
  'Churned Users' as user_type,
  avg_churned_usage as avg_usage_pct,
  median_churned_usage as median_usage_pct
FROM churned_usage
UNION ALL
SELECT 
  'Active Users' as user_type,
  avg_active_usage as avg_usage_pct,
  NULL as median_usage_pct
FROM active_usage;

-- 5. Monthly trend analysis of credit usage before churn
SELECT 
  churn_month,
  churned_users_count,
  avg_pct_allocation_used,
  LAG(avg_pct_allocation_used) OVER (ORDER BY churn_month) as prev_month_avg_usage,
  avg_pct_allocation_used - LAG(avg_pct_allocation_used) OVER (ORDER BY churn_month) as usage_change
FROM {{ ref('mart_credit_churn_usage_percentage') }}
WHERE churned_users_count > 0
ORDER BY churn_month;

-- 6. Distribution analysis of credit usage at churn
SELECT 
  churn_month,
  churned_users_count,
  min_pct_allocation_used,
  avg_pct_allocation_used,
  median_pct_allocation_used,
  max_pct_allocation_used,
  (max_pct_allocation_used - min_pct_allocation_used) as usage_range
FROM {{ ref('mart_credit_churn_usage_percentage') }}
WHERE churned_users_count > 0
ORDER BY churn_month DESC; 