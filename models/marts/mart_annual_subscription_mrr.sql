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
    2. Expand each paid charge into the years it "covers",
       tagging with its billing cycle (Monthly/Annual).
       This allows correct subscriber counts for each cycle by year.
  */
  SELECT
    cv.customer AS customer_id,
    CASE 
      WHEN p.interval = 'month' THEN 'Monthly'
      WHEN p.interval = 'year' THEN 'Annual'
      ELSE INITCAP(p.interval)
    END AS billing_cycle_type,
    year_start
  FROM {{ ref('charges_view') }} cv
  JOIN {{ ref('subscriptions') }} s ON cv.customer = s.customer
  JOIN {{ ref('plans') }} p ON JSON_EXTRACT_SCALAR(s.plan_data, '$.id') = p.stripe_id
  CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(
    DATE_TRUNC(DATE(cv.created), YEAR),
    DATE_TRUNC(
      DATE_ADD(
        DATE(cv.created),
        INTERVAL CASE 
          WHEN p.interval = 'year' THEN p.interval_count
          ELSE 1
        END YEAR
      ),
      YEAR
    ),
    INTERVAL 1 YEAR
  )) AS year_start
  WHERE
    cv.paid = TRUE
    AND DATE(cv.created) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 5 YEAR), YEAR)
),

revenue_per_year AS (
  /*
    3. Calculate actual revenue recognized by the year it hit,
       broken down by plan billing cycle (Monthly/Annual).
       This is for accurate, cycle-specific financial reporting.
  */
  SELECT
    DATE_TRUNC(DATE(cv.created), YEAR) AS year_start,
    CASE 
      WHEN p.interval = 'month' THEN 'Monthly'
      WHEN p.interval = 'year' THEN 'Annual'
      ELSE INITCAP(p.interval)
    END AS billing_cycle_type,
    SUM(cv.amount_captured / 100) AS revenue, -- Revenue in dollars
    COUNT(DISTINCT cv.customer) AS paying_customers
  FROM {{ ref('charges_view') }} cv
  JOIN {{ ref('subscriptions') }} s ON cv.customer = s.customer
  JOIN {{ ref('plans') }} p ON JSON_EXTRACT_SCALAR(s.plan_data, '$.id') = p.stripe_id
  WHERE
    cv.paid = TRUE
    AND DATE(cv.created) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 5 YEAR), YEAR)
    AND DATE(cv.created) < DATE_TRUNC(CURRENT_DATE(), YEAR)
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