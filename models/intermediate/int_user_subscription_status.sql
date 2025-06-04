{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  User Subscription Status - Intermediate Model
  --------------------------------------------
  This model determines each user's subscription status and categorizes them as 
  Trial vs Paid based on their latest subscription activity. This logic is extracted
  to be reusable across multiple churn and user analysis models.
  
  Key Logic:
  - Gets latest subscription for each user
  - Determines if user is Trial or Paid based on subscription status and timing
  - Handles edge cases for canceled subscriptions (trial vs paid cancellations)
============================================================================================
*/

WITH date_filter AS (
  {{ generate_date_filter(6) }}
),

user_subscription_status AS (
  -- Get each user's subscription history with status categorization
  SELECT DISTINCT
    CAST(u.id AS STRING) AS user_id,
    s.customer,
    s.status AS subscription_status,
    s.trial_start,
    s.trial_end,
    s.created AS subscription_created,
    s.canceled_at,
    -- Determine if user is currently or was recently in trial vs paid status
    CASE 
      WHEN s.status = 'trialing' THEN 'Trial'
      WHEN s.status IN ('active', 'past_due') THEN 'Paid'
      WHEN s.status = 'canceled' AND s.trial_end IS NOT NULL 
           AND s.canceled_at <= s.trial_end THEN 'Trial' -- Canceled during trial
      WHEN s.status = 'canceled' AND (s.trial_end IS NULL 
           OR s.canceled_at > s.trial_end) THEN 'Paid' -- Canceled after trial
      ELSE 'Other'
    END AS user_type,
    ROW_NUMBER() OVER (
      PARTITION BY CAST(u.id AS STRING) 
      ORDER BY s.created DESC
    ) AS rn
  FROM {{ source('syllaby_v2', 'users') }} u
  INNER JOIN {{ ref('subscriptions') }} s
    ON u.stripe_id = s.customer
  CROSS JOIN date_filter df
  WHERE (
    DATE(s.created) >= df.lookback_start_date
    OR DATE(s.canceled_at) >= df.lookback_start_date
    OR s.status IN ('active', 'trialing', 'past_due')
  )
)

-- Get the latest subscription status for each user
SELECT
  user_id,
  customer,
  subscription_status,
  user_type,
  trial_start,
  trial_end,
  subscription_created,
  canceled_at
FROM user_subscription_status
WHERE rn = 1 