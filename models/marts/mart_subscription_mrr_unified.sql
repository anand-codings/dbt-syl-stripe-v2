{{ config(
    materialized='table',
    schema='marts'
) }}

/*
============================================================================================
  Unified Subscription MRR Analysis (Monthly & Annual Combined)
  ---------------------------------------------------------------
  This query provides subscription metrics and revenue breakdown for both:
    - Monthly periods (last 24 months)
    - Annual periods (last 5 years)
  
  Combined in a single table with period_type to distinguish between monthly/annual views.
  Includes active subscribers, revenue breakdown, and ARPU calculations.
  
  REFACTORED: Now uses int_customer_active_periods for DRY charge expansion logic.
  This eliminates the duplicated monthly/annual CTEs and makes the model much simpler.
============================================================================================
*/

WITH monthly_periods AS (
  -- Generate monthly periods for the last 24 months
  SELECT
    month_start AS period_start,
    'monthly' AS period_type,
    EXTRACT(YEAR FROM month_start) AS period_year,
    EXTRACT(MONTH FROM month_start) AS period_month,
    NULL AS period_quarter
  FROM 
    UNNEST(GENERATE_DATE_ARRAY(
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 24 MONTH), MONTH),
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH),
      INTERVAL 1 MONTH
    )) AS month_start
),

annual_periods AS (
  -- Generate annual periods for the last 5 years
  SELECT
    year_start AS period_start,
    'annual' AS period_type,
    EXTRACT(YEAR FROM year_start) AS period_year,
    NULL AS period_month,
    NULL AS period_quarter
  FROM 
    UNNEST(GENERATE_DATE_ARRAY(
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 5 YEAR), YEAR),
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), YEAR),
      INTERVAL 1 YEAR
    )) AS year_start
),

all_periods AS (
  SELECT * FROM monthly_periods
  UNION ALL
  SELECT * FROM annual_periods
),

charges_expanded_unified AS (
  /*
    Use the centralized charge expansion logic from intermediate model.
    Create both monthly and annual views from the same source.
  */
  SELECT
    customer_id,
    billing_cycle_type,
    activity_month AS period_start,
    'monthly' AS period_type
  FROM {{ ref('int_customer_active_periods') }}
  WHERE activity_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 24 MONTH), MONTH)
    AND activity_month < DATE_TRUNC(CURRENT_DATE(), MONTH)
  
  UNION ALL
  
  SELECT
    customer_id,
    billing_cycle_type,
    activity_year AS period_start,
    'annual' AS period_type
  FROM {{ ref('int_customer_active_periods') }}
  WHERE activity_year >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 5 YEAR), YEAR)
    AND activity_year < DATE_TRUNC(CURRENT_DATE(), YEAR)
),

revenue_unified AS (
  /*
    Calculate revenue for both monthly and annual periods from the same source
  */
  SELECT
    activity_month AS period_start,
    'monthly' AS period_type,
    billing_cycle_type,
    SUM(amount_captured / 100) AS revenue
  FROM {{ ref('int_customer_active_periods') }}
  WHERE DATE(charge_created_at) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 24 MONTH), MONTH)
    AND DATE(charge_created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
    AND activity_month = DATE_TRUNC(DATE(charge_created_at), MONTH)
  GROUP BY 1, 2, 3
  
  UNION ALL
  
  SELECT
    activity_year AS period_start,
    'annual' AS period_type,
    billing_cycle_type,
    SUM(amount_captured / 100) AS revenue
  FROM {{ ref('int_customer_active_periods') }}
  WHERE DATE(charge_created_at) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 5 YEAR), YEAR)
    AND DATE(charge_created_at) < DATE_TRUNC(CURRENT_DATE(), YEAR)
    AND activity_year = DATE_TRUNC(DATE(charge_created_at), YEAR)
  GROUP BY 1, 2, 3
)

SELECT
  ap.period_start,
  ap.period_type,
  ap.period_year,
  ap.period_month,
  
  -- Subscriber counts (formatted with commas)
  FORMAT("%'d", COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Monthly' THEN ce.customer_id END)) AS monthly_active_subscribers,
  FORMAT("%'d", COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Annual' THEN ce.customer_id END)) AS annual_active_subscribers,
  FORMAT("%'d", COUNT(DISTINCT ce.customer_id)) AS total_active_subscribers,
  
  -- Revenue (formatted with commas and rounded)
  FORMAT("$%'d", CAST(ROUND(COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Monthly' THEN ru.revenue END), 0)) AS INT64)) AS monthly_revenue,
  FORMAT("$%'d", CAST(ROUND(COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Annual' THEN ru.revenue END), 0)) AS INT64)) AS annual_revenue,
  FORMAT("$%'d", CAST(ROUND(COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Monthly' THEN ru.revenue END), 0) 
    + COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Annual' THEN ru.revenue END), 0)) AS INT64)) AS total_revenue,
  
  -- ARPU calculations - Formatted with commas and rounded
  FORMAT("$%'d", CAST(ROUND(CASE 
    WHEN COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Monthly' THEN ce.customer_id END) > 0 
    THEN COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Monthly' THEN ru.revenue END), 0) / 
         COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Monthly' THEN ce.customer_id END)
    ELSE 0 
  END) AS INT64)) AS monthly_arpu,
  
  FORMAT("$%'d", CAST(ROUND(CASE 
    WHEN COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Annual' THEN ce.customer_id END) > 0 
    THEN COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Annual' THEN ru.revenue END), 0) / 
         COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Annual' THEN ce.customer_id END)
    ELSE 0 
  END) AS INT64)) AS annual_arpu,
  
  FORMAT("$%'d", CAST(ROUND(CASE 
    WHEN COUNT(DISTINCT ce.customer_id) > 0 
    THEN (COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Monthly' THEN ru.revenue END), 0) 
          + COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Annual' THEN ru.revenue END), 0)) / 
         COUNT(DISTINCT ce.customer_id)
    ELSE 0 
  END) AS INT64)) AS total_arpu

FROM all_periods ap
LEFT JOIN charges_expanded_unified ce
  ON ce.period_start = ap.period_start
  AND ce.period_type = ap.period_type
LEFT JOIN revenue_unified ru
  ON ru.period_start = ap.period_start
  AND ru.period_type = ap.period_type

GROUP BY ap.period_start, ap.period_type, ap.period_year, ap.period_month
ORDER BY ap.period_type, ap.period_start 