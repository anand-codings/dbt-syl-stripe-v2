/*
============================================================================================
  Example Queries for Unified Subscription MRR Mart
  ---------------------------------------------------------------
  This file contains example queries demonstrating how to use the 
  mart_subscription_mrr_unified model for various analysis scenarios.
============================================================================================
*/

-- Example 1: Get all data with both monthly and annual views
SELECT 
  period_start,
  period_type,
  total_active_subscribers,
  total_revenue,
  total_arpu,
  CASE 
    WHEN period_type = 'monthly' THEN monthly_mrr
    WHEN period_type = 'annual' THEN annual_recurring_revenue
  END as recurring_revenue
FROM {{ ref('mart_subscription_mrr_unified') }}
ORDER BY period_type, period_start;

-- Example 2: Monthly MRR trend analysis
SELECT 
  period_start as month,
  total_active_subscribers,
  monthly_mrr,
  LAG(monthly_mrr) OVER (ORDER BY period_start) as prev_month_mrr,
  ROUND(
    (monthly_mrr - LAG(monthly_mrr) OVER (ORDER BY period_start)) / 
    NULLIF(LAG(monthly_mrr) OVER (ORDER BY period_start), 0) * 100, 
    2
  ) as mrr_growth_pct
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE period_type = 'monthly'
  AND period_start >= '2023-01-01'
ORDER BY period_start;

-- Example 3: Annual recurring revenue comparison
SELECT 
  period_year,
  total_active_subscribers,
  annual_recurring_revenue,
  total_arpu,
  LAG(annual_recurring_revenue) OVER (ORDER BY period_year) as prev_year_arr,
  ROUND(
    (annual_recurring_revenue - LAG(annual_recurring_revenue) OVER (ORDER BY period_year)) / 
    NULLIF(LAG(annual_recurring_revenue) OVER (ORDER BY period_year), 0) * 100, 
    2
  ) as arr_growth_pct
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE period_type = 'annual'
ORDER BY period_year;

-- Example 4: Billing cycle preference analysis
SELECT 
  period_year,
  period_type,
  monthly_active_subscribers,
  annual_active_subscribers,
  total_active_subscribers,
  ROUND(
    annual_active_subscribers * 100.0 / 
    NULLIF(total_active_subscribers, 0), 
    2
  ) as annual_subscriber_pct,
  ROUND(
    monthly_active_subscribers * 100.0 / 
    NULLIF(total_active_subscribers, 0), 
    2
  ) as monthly_subscriber_pct
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE period_start >= '2022-01-01'
ORDER BY period_year, period_type;

-- Example 5: Revenue per billing cycle comparison
SELECT 
  period_start,
  period_type,
  monthly_revenue,
  annual_revenue,
  total_revenue,
  ROUND(
    monthly_revenue * 100.0 / NULLIF(total_revenue, 0), 
    2
  ) as monthly_revenue_pct,
  ROUND(
    annual_revenue * 100.0 / NULLIF(total_revenue, 0), 
    2
  ) as annual_revenue_pct
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE total_revenue > 0
ORDER BY period_type, period_start;

-- Example 6: ARPU comparison across billing cycles
SELECT 
  period_start,
  period_type,
  monthly_arpu,
  annual_arpu,
  total_arpu,
  CASE 
    WHEN monthly_arpu > 0 AND annual_arpu > 0 
    THEN ROUND(annual_arpu / monthly_arpu, 2)
    ELSE NULL 
  END as annual_to_monthly_arpu_ratio
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE total_active_subscribers > 0
ORDER BY period_type, period_start;

-- Example 7: Recent performance summary (last 6 months + current year)
SELECT 
  'Recent 6 Months' as time_period,
  'monthly' as period_type,
  AVG(total_active_subscribers) as avg_subscribers,
  AVG(monthly_mrr) as avg_mrr,
  AVG(total_arpu) as avg_arpu
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE period_type = 'monthly'
  AND period_start >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)

UNION ALL

SELECT 
  CAST(period_year AS STRING) as time_period,
  'annual' as period_type,
  total_active_subscribers as avg_subscribers,
  annual_recurring_revenue as avg_mrr,
  total_arpu as avg_arpu
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE period_type = 'annual'
  AND period_year = EXTRACT(YEAR FROM DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR))

ORDER BY period_type, time_period;

-- Example 8: Cohort-style analysis by year
SELECT 
  period_year,
  SUM(CASE WHEN period_type = 'monthly' THEN 1 ELSE 0 END) as months_in_year,
  AVG(CASE WHEN period_type = 'monthly' THEN total_active_subscribers END) as avg_monthly_subscribers,
  AVG(CASE WHEN period_type = 'monthly' THEN monthly_mrr END) as avg_monthly_mrr,
  MAX(CASE WHEN period_type = 'annual' THEN total_active_subscribers END) as annual_subscribers,
  MAX(CASE WHEN period_type = 'annual' THEN annual_recurring_revenue END) as annual_arr
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE period_year >= 2022
GROUP BY period_year
ORDER BY period_year; 