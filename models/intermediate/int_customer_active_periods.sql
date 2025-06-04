{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Customer Active Periods - Unified Charge Expansion Logic
  --------------------------------------------------------
  This intermediate model consolidates the charge expansion logic that was previously
  duplicated across multiple mart models. It expands each paid charge to determine
  all the months a subscription is considered "active" for a customer.
  
  This model is used by:
  - mart_subscription_mrr_unified
  - mart_customer_lifecycle_status
============================================================================================
*/

WITH charges_with_plans AS (
  SELECT
    cv.customer AS customer_id,
    cv.created AS charge_created_at,
    cv.amount_captured,
    cv.paid,
    CASE
      WHEN p.interval = 'year' THEN p.interval_count * 12
      WHEN p.interval = 'month' THEN p.interval_count
      ELSE 1
    END AS charge_duration_months,
    CASE 
      WHEN p.interval = 'month' THEN 'Monthly'
      WHEN p.interval = 'year' THEN 'Annual'
      ELSE INITCAP(p.interval)
    END AS billing_cycle_type,
    p.interval AS plan_interval,
    p.interval_count AS plan_interval_count
  FROM {{ ref('charges_view') }} AS cv
  JOIN {{ ref('subscriptions') }} AS s ON cv.customer = s.customer
  JOIN {{ ref('plans') }} AS p ON JSON_EXTRACT_SCALAR(s.plan_data, '$.id') = p.stripe_id
  WHERE cv.paid = TRUE
),

expanded_periods AS (
  SELECT
    customer_id,
    charge_created_at,
    amount_captured,
    billing_cycle_type,
    plan_interval,
    plan_interval_count,
    DATE_TRUNC(expanded_month, MONTH) as activity_month,
    DATE_TRUNC(expanded_month, YEAR) as activity_year
  FROM charges_with_plans
  CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(
    DATE_TRUNC(DATE(charge_created_at), MONTH),
    DATE_TRUNC(
      DATE_ADD(
        DATE(charge_created_at),
        INTERVAL charge_duration_months MONTH
      ),
      MONTH
    ),
    INTERVAL 1 MONTH
  )) AS expanded_month
)

SELECT
  customer_id,
  activity_month,
  activity_year,
  billing_cycle_type,
  plan_interval,
  plan_interval_count,
  -- Include charge details for revenue calculations
  charge_created_at,
  amount_captured
FROM expanded_periods 