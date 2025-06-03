{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Plans with Tiers - Centralized Plan Tier Definition
  ---------------------------------------------------
  This intermediate model consolidates the plan tier categorization logic that was
  previously duplicated across multiple credit-related mart models.
  
  Plan tiers are defined as:
  - Pro: Monthly plans >= $50.00
  - Basic: Monthly plans < $50.00  
  - Enterprise: Annual plans
  - Other: All other plans
  
  This model is used by:
  - mart_credit_allocation_vs_usage_by_plan
  - mart_credit_churn_risk
  - mart_monthly_credit_allocation
============================================================================================
*/

WITH all_plans_and_prices AS (
  -- from plans table
  SELECT
    stripe_id AS plan_stripe_id,
    CASE
      WHEN amount >= 5000 AND "interval" = 'month' THEN 'Pro'
      WHEN amount < 5000 AND "interval" = 'month' THEN 'Basic'
      WHEN "interval" = 'year' THEN 'Enterprise'
      ELSE 'Other'
    END AS plan_tier,
    amount,
    "interval" as billing_interval,
    interval_count,
    'plans' as source_table
  FROM {{ ref('plans') }}

  UNION ALL

  -- from prices table for modern Stripe
  SELECT
    stripe_id AS plan_stripe_id,
    CASE
      WHEN unit_amount >= 5000 AND recurring_interval = 'month' THEN 'Pro'
      WHEN unit_amount < 5000 AND recurring_interval = 'month' THEN 'Basic'
      WHEN recurring_interval = 'year' THEN 'Enterprise'
      ELSE 'Other'
    END AS plan_tier,
    unit_amount as amount,
    recurring_interval as billing_interval,
    recurring_interval_count as interval_count,
    'prices' as source_table
  FROM {{ ref('prices') }}
  WHERE unit_amount IS NOT NULL
)

SELECT 
  plan_stripe_id,
  plan_tier,
  amount,
  billing_interval,
  interval_count,
  source_table
FROM all_plans_and_prices 