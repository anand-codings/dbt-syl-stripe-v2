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

charges_expanded_monthly AS (
  /*
    Expand charges for monthly analysis
  */
  SELECT
    cv.customer AS customer_id,
    CASE 
      WHEN p.interval = 'month' THEN 'Monthly'
      WHEN p.interval = 'year' THEN 'Annual'
      ELSE INITCAP(p.interval)
    END AS billing_cycle_type,
    month_start AS period_start,
    'monthly' AS period_type
  FROM {{ ref('charges_view') }} cv
  JOIN {{ ref('subscriptions') }} s ON cv.customer = s.customer
  JOIN {{ ref('plans') }} p ON JSON_EXTRACT_SCALAR(s.plan_data, '$.id') = p.stripe_id
  CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(
    DATE_TRUNC(DATE(cv.created), MONTH),
    DATE_TRUNC(
      DATE_ADD(
        DATE(cv.created),
        INTERVAL CASE 
          WHEN p.interval = 'year' THEN p.interval_count * 12
          WHEN p.interval = 'month' THEN p.interval_count
          ELSE 1
        END MONTH
      ),
      MONTH
    ),
    INTERVAL 1 MONTH
  )) AS month_start
  WHERE
    cv.paid = TRUE
    AND DATE(cv.created) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 24 MONTH), MONTH)
),

charges_expanded_annual AS (
  /*
    Expand charges for annual analysis
  */
  SELECT
    cv.customer AS customer_id,
    CASE 
      WHEN p.interval = 'month' THEN 'Monthly'
      WHEN p.interval = 'year' THEN 'Annual'
      ELSE INITCAP(p.interval)
    END AS billing_cycle_type,
    year_start AS period_start,
    'annual' AS period_type
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

charges_expanded_unified AS (
  SELECT * FROM charges_expanded_monthly
  UNION ALL
  SELECT * FROM charges_expanded_annual
),

revenue_monthly AS (
  /*
    Calculate monthly revenue
  */
  SELECT
    DATE_TRUNC(DATE(cv.created), MONTH) AS period_start,
    'monthly' AS period_type,
    CASE 
      WHEN p.interval = 'month' THEN 'Monthly'
      WHEN p.interval = 'year' THEN 'Annual'
      ELSE INITCAP(p.interval)
    END AS billing_cycle_type,
    SUM(cv.amount_captured / 100) AS revenue
  FROM {{ ref('charges_view') }} cv
  JOIN {{ ref('subscriptions') }} s ON cv.customer = s.customer
  JOIN {{ ref('plans') }} p ON JSON_EXTRACT_SCALAR(s.plan_data, '$.id') = p.stripe_id
  WHERE
    cv.paid = TRUE
    AND DATE(cv.created) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 24 MONTH), MONTH)
    AND DATE(cv.created) < DATE_TRUNC(CURRENT_DATE(), MONTH)
  GROUP BY 1, 2, 3
),

revenue_annual AS (
  /*
    Calculate annual revenue
  */
  SELECT
    DATE_TRUNC(DATE(cv.created), YEAR) AS period_start,
    'annual' AS period_type,
    CASE 
      WHEN p.interval = 'month' THEN 'Monthly'
      WHEN p.interval = 'year' THEN 'Annual'
      ELSE INITCAP(p.interval)
    END AS billing_cycle_type,
    SUM(cv.amount_captured / 100) AS revenue
  FROM {{ ref('charges_view') }} cv
  JOIN {{ ref('subscriptions') }} s ON cv.customer = s.customer
  JOIN {{ ref('plans') }} p ON JSON_EXTRACT_SCALAR(s.plan_data, '$.id') = p.stripe_id
  WHERE
    cv.paid = TRUE
    AND DATE(cv.created) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 5 YEAR), YEAR)
    AND DATE(cv.created) < DATE_TRUNC(CURRENT_DATE(), YEAR)
  GROUP BY 1, 2, 3
),

revenue_unified AS (
  SELECT * FROM revenue_monthly
  UNION ALL
  SELECT * FROM revenue_annual
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
  END) AS INT64)) AS total_arpu,
  
  -- Additional calculated metrics - Formatted with commas
  CASE 
    WHEN ap.period_type = 'monthly' THEN 
      FORMAT("$%'d", CAST(ROUND(COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Monthly' THEN ru.revenue END), 0) 
        + COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Annual' THEN ru.revenue END), 0)) AS INT64))
    ELSE NULL 
  END AS monthly_mrr,
  
  CASE 
    WHEN ap.period_type = 'annual' THEN 
      FORMAT("$%'d", CAST(ROUND((COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Monthly' THEN ru.revenue END), 0) * 12)
        + COALESCE(MAX(CASE WHEN ru.billing_cycle_type = 'Annual' THEN ru.revenue END), 0)) AS INT64))
    ELSE NULL 
  END AS annual_recurring_revenue

FROM all_periods ap
LEFT JOIN charges_expanded_unified ce
  ON ce.period_start = ap.period_start 
  AND ce.period_type = ap.period_type
LEFT JOIN revenue_unified ru
  ON ru.period_start = ap.period_start 
  AND ru.period_type = ap.period_type

GROUP BY 
  ap.period_start, 
  ap.period_type, 
  ap.period_year, 
  ap.period_month
ORDER BY 
  ap.period_type, 
  ap.period_start 