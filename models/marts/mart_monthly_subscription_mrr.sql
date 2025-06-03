{{ config(
    materialized='table',
    schema='marts'
) }}

/*
============================================================================================
  Monthly Active Subscribers & Revenue Breakdown (Last 12 Months)
  ---------------------------------------------------------------
  This query provides, for each of the last 12 full months:
    - Number of active subscribers (monthly, annual, and total)
    - Total revenue, monthly-plan revenue, and annual-plan revenue
  The results are suitable for time series analysis, dashboards, or financial reporting.
  
  REFACTORED: Now uses int_customer_active_periods for DRY charge expansion logic.
============================================================================================
*/

WITH months AS (
  -- 1. Create a series of monthly periods for the last 12 full months.
  SELECT
    month_start
  FROM 
    UNNEST(GENERATE_DATE_ARRAY(
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH),
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH),
      INTERVAL 1 MONTH
    )) AS month_start
),

charges_expanded AS (
  /*
    2. Use the centralized charge expansion logic from intermediate model.
       Filter for the last 12 months and get monthly activity.
  */
  SELECT
    customer_id,
    billing_cycle_type,
    activity_month as month_start
  FROM {{ ref('int_customer_active_periods') }}
  WHERE activity_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH)
    AND activity_month < DATE_TRUNC(CURRENT_DATE(), MONTH)
),

revenue_per_month AS (
  /*
    3. Calculate actual revenue recognized by the month it hit,
       broken down by plan billing cycle (Monthly/Annual).
       This is for accurate, cycle-specific financial reporting.
  */
  SELECT
    activity_month AS month_start,
    billing_cycle_type,
    SUM(amount_captured / 100) AS revenue -- Revenue in dollars
  FROM {{ ref('int_customer_active_periods') }}
  WHERE DATE(charge_created_at) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH), MONTH)
    AND DATE(charge_created_at) < DATE_TRUNC(CURRENT_DATE(), MONTH)
    AND activity_month = DATE_TRUNC(DATE(charge_created_at), MONTH) -- Only count revenue in the month it was charged
  GROUP BY 1, 2
)

SELECT
  m.month_start AS month,
  
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

FROM months m
LEFT JOIN charges_expanded ce
  ON ce.month_start = m.month_start
LEFT JOIN revenue_per_month rm
  ON rm.month_start = m.month_start

GROUP BY m.month_start
ORDER BY m.month_start 