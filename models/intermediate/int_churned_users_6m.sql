{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Churned Users (6-Month Lookback) - Intermediate Model
  -----------------------------------------------------
  This model identifies users who have churned (canceled their subscriptions) within
  the last 6 months and classifies whether they churned from a trial or paid status.
  This logic is extracted to be reusable across multiple churn analysis models.
  
  Time Period: Last 6 months from current date
  
  Key Logic:
  - Identifies canceled subscriptions within the 6-month lookback period
  - Determines if the churn was from Trial or Paid status based on timing
  - Provides churn date and context for further analysis
============================================================================================
*/

WITH date_filter AS (
  {{ generate_date_filter(6) }}
),

churned_users AS (
  -- Identify users who churned in the specified time period
  SELECT DISTINCT
    CAST(u.id AS STRING) AS user_id,
    s.customer,
    s.canceled_at,
    s.status,
    s.trial_start,
    s.trial_end,
    s.created AS subscription_created,
    
    -- Determine if they churned from trial or paid status
    CASE 
      WHEN s.trial_end IS NOT NULL AND s.canceled_at <= s.trial_end THEN 'Trial'
      WHEN s.trial_end IS NULL OR s.canceled_at > s.trial_end THEN 'Paid'
      ELSE 'Other'
    END AS churned_from_type,
    
    -- Additional churn context
    DATE_DIFF(DATE(s.canceled_at), DATE(s.created), DAY) AS subscription_duration_days,
    
    CASE 
      WHEN s.trial_end IS NOT NULL THEN 
        DATE_DIFF(DATE(s.trial_end), DATE(s.trial_start), DAY)
      ELSE 0
    END AS trial_duration_days,
    
    -- Churn timing relative to trial
    CASE 
      WHEN s.trial_end IS NOT NULL AND s.canceled_at <= s.trial_end THEN 
        DATE_DIFF(DATE(s.canceled_at), DATE(s.trial_start), DAY)
      WHEN s.trial_end IS NOT NULL AND s.canceled_at > s.trial_end THEN 
        DATE_DIFF(DATE(s.canceled_at), DATE(s.trial_end), DAY)
      ELSE NULL
    END AS days_from_trial_reference
    
  FROM {{ source('syllaby_v2', 'users') }} u
  INNER JOIN {{ ref('subscriptions') }} s
    ON u.stripe_id = s.customer
  CROSS JOIN date_filter df
  WHERE s.status = 'canceled'
    AND s.canceled_at IS NOT NULL
    AND DATE(s.canceled_at) >= df.lookback_start_date
)

SELECT
  user_id,
  customer,
  canceled_at,
  status,
  trial_start,
  trial_end,
  subscription_created,
  churned_from_type,
  subscription_duration_days,
  trial_duration_days,
  days_from_trial_reference,
  
  -- Time period context
  (SELECT lookback_start_date FROM date_filter) AS analysis_start_date,
  (SELECT analysis_end_date FROM date_filter) AS analysis_end_date
  
FROM churned_users 