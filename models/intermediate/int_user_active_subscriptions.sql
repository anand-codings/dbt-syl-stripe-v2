{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  User Active Subscriptions - Intermediate Model
  ----------------------------------------------
  This model provides active subscription context for users, extracted from the
  credit churn risk analysis for reuse across multiple subscription-related models.
  
  Key Logic:
  - Gets active subscriptions with plan information
  - Provides monthly context for subscription status
  - Standardized date format for consistent joins
  
  This model is used by:
  - mart_credit_churn_risk
  - Any other models needing active subscription context
============================================================================================
*/

SELECT
  s.customer           AS user_id,
  JSON_EXTRACT_SCALAR(s.plan_data, '$.id') AS plan_stripe_id,
  DATE_TRUNC(s.current_period_end, MONTH)  AS as_of_month
FROM {{ ref('subscriptions') }} s
WHERE s.status = 'active' 