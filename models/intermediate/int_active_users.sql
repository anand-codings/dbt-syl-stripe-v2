{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Active Users - Intermediate Model
  ---------------------------------
  This model identifies users who have been "active" within a specified time period.
  Activity is defined as either creating content OR having subscription activity.
  This provides a consistent definition of active users across different analyses.
  
  Activity Types:
  - Content creation: Created avatars, real clones, or faceless videos
  - Subscription activity: New subscriptions, cancellations, or active status
============================================================================================
*/

WITH date_filter AS (
  {{ generate_date_filter(6) }}
),

content_active_users AS (
  -- Users who created any content in the time period
  SELECT DISTINCT
    user_id,
    'content_creation' AS activity_type,
    MIN(earliest_creation_date) AS first_activity_date,
    MAX(latest_creation_date) AS last_activity_date
  FROM {{ ref('int_content_creators_by_type') }}
  GROUP BY user_id
),

subscription_active_users AS (
  -- Users with subscription activity in the time period
  SELECT DISTINCT
    user_id,
    'subscription_activity' AS activity_type,
    MIN(DATE(subscription_created)) AS first_activity_date,
    MAX(COALESCE(DATE(canceled_at), DATE(subscription_created))) AS last_activity_date
  FROM {{ ref('int_user_subscription_status') }}
  GROUP BY user_id
),

all_active_users AS (
  -- Combine all types of activity
  SELECT * FROM content_active_users
  UNION ALL
  SELECT * FROM subscription_active_users
),

user_activity_summary AS (
  -- Summarize each user's activity
  SELECT
    user_id,
    ARRAY_AGG(DISTINCT activity_type) AS activity_types,
    MIN(first_activity_date) AS earliest_activity_date,
    MAX(last_activity_date) AS latest_activity_date,
    COUNT(DISTINCT activity_type) AS activity_type_count,
    
    -- Activity type flags
    MAX(CASE WHEN activity_type = 'content_creation' THEN 1 ELSE 0 END) AS has_content_activity,
    MAX(CASE WHEN activity_type = 'subscription_activity' THEN 1 ELSE 0 END) AS has_subscription_activity,
    
    -- User activity classification
    CASE 
      WHEN MAX(CASE WHEN activity_type = 'content_creation' THEN 1 ELSE 0 END) = 1 
           AND MAX(CASE WHEN activity_type = 'subscription_activity' THEN 1 ELSE 0 END) = 1 
           THEN 'content_and_subscription'
      WHEN MAX(CASE WHEN activity_type = 'content_creation' THEN 1 ELSE 0 END) = 1 
           THEN 'content_only'
      WHEN MAX(CASE WHEN activity_type = 'subscription_activity' THEN 1 ELSE 0 END) = 1 
           THEN 'subscription_only'
      ELSE 'other'
    END AS activity_classification
    
  FROM all_active_users
  GROUP BY user_id
)

SELECT
  user_id,
  activity_types,
  earliest_activity_date,
  latest_activity_date,
  activity_type_count,
  has_content_activity,
  has_subscription_activity,
  activity_classification,
  
  -- Time period context
  (SELECT lookback_start_date FROM date_filter) AS analysis_start_date,
  (SELECT analysis_end_date FROM date_filter) AS analysis_end_date
  
FROM user_activity_summary 