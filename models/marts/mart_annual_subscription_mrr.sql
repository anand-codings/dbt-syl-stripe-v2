{{ config(
    materialized='table',
    schema='marts'
) }}

/*
============================================================================================
  Annual Active Subscribers & Revenue Breakdown (Last 5 Years)
  ---------------------------------------------------------------
  This query provides, for each of the last 5 full years:
    - Number of active subscribers (monthly, annual, and total)
    - Total revenue, monthly-plan revenue, and annual-plan revenue
    - Average revenue per user (ARPU) by billing cycle
  The results are suitable for long-term trend analysis and strategic planning.
  
  REFACTORED: Now uses int_customer_active_periods for DRY charge expansion logic.
============================================================================================
*/

WITH years AS (
  -- 1. Create a series of yearly periods for the last 5 full years.
  SELECT
    year_start
  FROM 
    UNNEST(GENERATE_DATE_ARRAY(
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 5 YEAR), YEAR),
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR), YEAR),
      INTERVAL 1 YEAR
    )) AS year_start
),

charges_expanded AS (
  /*
    2. Use the centralized charge expansion logic from intermediate model.
       Filter for the last 5 years and get annual activity.
  */
  SELECT
    customer_id,
    billing_cycle_type,
    activity_year as year_start
  FROM {{ ref('int_customer_active_periods') }}
  WHERE activity_year >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 5 YEAR), YEAR)
    AND activity_year < DATE_TRUNC(CURRENT_DATE(), YEAR)
),

revenue_per_year AS (
  /*
    3. Calculate actual revenue recognized by the year it hit,
       broken down by plan billing cycle (Monthly/Annual).
       This is for accurate, cycle-specific financial reporting.
  */
  SELECT
    activity_year AS year_start,
    billing_cycle_type,
    SUM(amount_captured / 100) AS revenue, -- Revenue in dollars
    COUNT(DISTINCT customer_id) AS paying_customers
  FROM {{ ref('int_customer_active_periods') }}
  WHERE DATE(charge_created_at) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 5 YEAR), YEAR)
    AND DATE(charge_created_at) < DATE_TRUNC(CURRENT_DATE(), YEAR)
    AND activity_year = DATE_TRUNC(DATE(charge_created_at), YEAR) -- Only count revenue in the year it was charged
  GROUP BY 1, 2
)

SELECT
  y.year_start AS year,
  
  -- Subscriber counts (formatted with commas)
  FORMAT("%'d", COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Monthly' THEN ce.customer_id END)) AS monthly_active_subscribers,
  FORMAT("%'d", COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Annual' THEN ce.customer_id END)) AS annual_active_subscribers,
  FORMAT("%'d", COUNT(DISTINCT ce.customer_id)) AS total_active_subscribers,
  
  -- Revenue (formatted with commas and rounded)
  FORMAT("$%'d", CAST(ROUND(COALESCE(MAX(CASE WHEN rm.billing_cycle_type = 'Monthly' THEN rm.revenue END), 0)) AS INT64)) AS monthly_revenue,
  FORMAT("$%'d", CAST(ROUND(COALESCE(MAX(CASE WHEN rm.billing_cycle_type = 'Annual' THEN rm.revenue END), 0)) AS INT64)) AS annual_revenue,
  FORMAT("$%'d", CAST(ROUND(COALESCE(MAX(CASE WHEN rm.billing_cycle_type = 'Monthly' THEN rm.revenue END), 0) 
    + COALESCE(MAX(CASE WHEN rm.billing_cycle_type = 'Annual' THEN rm.revenue END), 0)) AS INT64)) AS total_revenue,
  
  -- ARPU calculations - Formatted with commas and rounded
  FORMAT("$%'d", CAST(ROUND(CASE 
    WHEN COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Monthly' THEN ce.customer_id END) > 0 
    THEN COALESCE(MAX(CASE WHEN rm.billing_cycle_type = 'Monthly' THEN rm.revenue END), 0) / 
         COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Monthly' THEN ce.customer_id END)
    ELSE 0 
  END) AS INT64)) AS monthly_arpu,
  
  FORMAT("$%'d", CAST(ROUND(CASE 
    WHEN COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Annual' THEN ce.customer_id END) > 0 
    THEN COALESCE(MAX(CASE WHEN rm.billing_cycle_type = 'Annual' THEN rm.revenue END), 0) / 
         COUNT(DISTINCT CASE WHEN ce.billing_cycle_type = 'Annual' THEN ce.customer_id END)
    ELSE 0 
  END) AS INT64)) AS annual_arpu,
  
  FORMAT("$%'d", CAST(ROUND(CASE 
    WHEN COUNT(DISTINCT ce.customer_id) > 0 
    THEN (COALESCE(MAX(CASE WHEN rm.billing_cycle_type = 'Monthly' THEN rm.revenue END), 0) 
          + COALESCE(MAX(CASE WHEN rm.billing_cycle_type = 'Annual' THEN rm.revenue END), 0)) / 
         COUNT(DISTINCT ce.customer_id)
    ELSE 0 
  END) AS INT64)) AS total_arpu

FROM years y
LEFT JOIN charges_expanded ce
  ON ce.year_start = y.year_start
LEFT JOIN revenue_per_year rm
  ON rm.year_start = y.year_start

GROUP BY y.year_start
ORDER BY y.year_start 