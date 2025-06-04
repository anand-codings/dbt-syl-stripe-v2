{{ config(materialized='table', schema='marts') }}

/*
============================================================================================
  User Segment Churn Analysis - Last 6 Months (Enhanced with Trial vs Paid Buckets)
  ---------------------------------------------------------------------------------
  This model analyzes churn rates for different user segments based on their content 
  creation activity AND subscription type, focusing only on the last 6 months of data. 
  It compares churn rates between users who only create avatars/real clones versus users 
  who create faceless videos, further segmented by trial vs active/paying status.
  
  REFACTORED: Now uses intermediate models for better maintainability and reusability.
  
  Time Filter: Only includes data from the last 6 months
  - Churn events: Only subscriptions canceled in the last 6 months
  - Content creation: Only content created in the last 6 months
  
  Key Segments (with Trial vs Paid breakdown):
  - Creators Only: Users who ONLY create avatars/real clones (and NOT faceless videos)
    - Trial Creators Only
    - Paid Creators Only
  - Faceless Users: Users who create faceless videos (may or may not create other types)
    - Trial Faceless Users
    - Paid Faceless Users
  - All Users: Baseline churn rate for comparison
    - Trial Users (All)
    - Paid Users (All)
  
  Key Metrics:
  - Total users per segment (active in last 6 months)
  - Churned users per segment (churned in last 6 months)
  - Churn rate percentage per segment
  - Comparative analysis between segments and subscription types
============================================================================================
*/

WITH date_filter AS (
  {{ generate_date_filter(6) }}
),

-- Use intermediate models for clean data access
user_subscription_status AS (
  SELECT * FROM {{ ref('int_user_subscription_status') }}
),

content_creators AS (
  SELECT * FROM {{ ref('int_content_creators_by_type') }}
),

churned_users AS (
  SELECT * FROM {{ ref('int_churned_users_6m') }}
),

active_users AS (
  SELECT * FROM {{ ref('int_active_users') }}
),

-- Define user segments based on content creation patterns
segment_creators_only AS (
  -- Users who ONLY create avatars/real clones (and NOT faceless videos)
  SELECT user_id
  FROM content_creators
  WHERE detailed_segment = 'creators_only'
),

segment_faceless_users AS (
  -- Users who create faceless videos (may or may not create other types)
  SELECT user_id
  FROM content_creators
  WHERE created_faceless = 1
),

segment_metrics AS (
  -- Calculate metrics for each segment with trial vs paid breakdown
  
  -- Creators Only - Trial Users
  SELECT
    '1a. Creators Only (Avatars/Real Clones) - Trial - Last 6M' AS segment_name,
    'Trial' AS user_type,
    'Creators Only' AS content_segment,
    COUNT(DISTINCT s.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM segment_creators_only s
  INNER JOIN user_subscription_status uss ON s.user_id = uss.user_id
  LEFT JOIN churned_users c ON s.user_id = c.user_id AND c.churned_from_type = 'Trial'
  WHERE uss.user_type = 'Trial'

  UNION ALL

  -- Creators Only - Paid Users
  SELECT
    '1b. Creators Only (Avatars/Real Clones) - Paid - Last 6M' AS segment_name,
    'Paid' AS user_type,
    'Creators Only' AS content_segment,
    COUNT(DISTINCT s.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM segment_creators_only s
  INNER JOIN user_subscription_status uss ON s.user_id = uss.user_id
  LEFT JOIN churned_users c ON s.user_id = c.user_id AND c.churned_from_type = 'Paid'
  WHERE uss.user_type = 'Paid'

  UNION ALL

  -- Faceless Users - Trial Users
  SELECT
    '2a. Faceless Users - Trial - Last 6M' AS segment_name,
    'Trial' AS user_type,
    'Faceless Users' AS content_segment,
    COUNT(DISTINCT s.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM segment_faceless_users s
  INNER JOIN user_subscription_status uss ON s.user_id = uss.user_id
  LEFT JOIN churned_users c ON s.user_id = c.user_id AND c.churned_from_type = 'Trial'
  WHERE uss.user_type = 'Trial'

  UNION ALL

  -- Faceless Users - Paid Users
  SELECT
    '2b. Faceless Users - Paid - Last 6M' AS segment_name,
    'Paid' AS user_type,
    'Faceless Users' AS content_segment,
    COUNT(DISTINCT s.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM segment_faceless_users s
  INNER JOIN user_subscription_status uss ON s.user_id = uss.user_id
  LEFT JOIN churned_users c ON s.user_id = c.user_id AND c.churned_from_type = 'Paid'
  WHERE uss.user_type = 'Paid'

  UNION ALL

  -- All Active Users - Trial Users (Baseline)
  SELECT
    '3a. All Active Users - Trial (Baseline) - Last 6M' AS segment_name,
    'Trial' AS user_type,
    'All Users' AS content_segment,
    COUNT(DISTINCT a.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM active_users a
  INNER JOIN user_subscription_status uss ON a.user_id = uss.user_id
  LEFT JOIN churned_users c ON a.user_id = c.user_id AND c.churned_from_type = 'Trial'
  WHERE uss.user_type = 'Trial'

  UNION ALL

  -- All Active Users - Paid Users (Baseline)
  SELECT
    '3b. All Active Users - Paid (Baseline) - Last 6M' AS segment_name,
    'Paid' AS user_type,
    'All Users' AS content_segment,
    COUNT(DISTINCT a.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM active_users a
  INNER JOIN user_subscription_status uss ON a.user_id = uss.user_id
  LEFT JOIN churned_users c ON a.user_id = c.user_id AND c.churned_from_type = 'Paid'
  WHERE uss.user_type = 'Paid'
),

segment_breakdown AS (
  -- Additional breakdown showing overlap between segments with trial/paid split
  SELECT
    'Creators Only (No Faceless) - Trial - Last 6M' AS segment_detail,
    'Trial' AS user_type,
    COUNT(DISTINCT cc.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM content_creators cc
  INNER JOIN user_subscription_status uss ON cc.user_id = uss.user_id
  LEFT JOIN churned_users c ON cc.user_id = c.user_id AND c.churned_from_type = 'Trial'
  WHERE cc.detailed_segment = 'creators_only' AND uss.user_type = 'Trial'
  
  UNION ALL
  
  SELECT
    'Creators Only (No Faceless) - Paid - Last 6M' AS segment_detail,
    'Paid' AS user_type,
    COUNT(DISTINCT cc.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM content_creators cc
  INNER JOIN user_subscription_status uss ON cc.user_id = uss.user_id
  LEFT JOIN churned_users c ON cc.user_id = c.user_id AND c.churned_from_type = 'Paid'
  WHERE cc.detailed_segment = 'creators_only' AND uss.user_type = 'Paid'
  
  UNION ALL
  
  SELECT
    'Faceless Only (No Avatars/Real Clones) - Trial - Last 6M' AS segment_detail,
    'Trial' AS user_type,
    COUNT(DISTINCT cc.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM content_creators cc
  INNER JOIN user_subscription_status uss ON cc.user_id = uss.user_id
  LEFT JOIN churned_users c ON cc.user_id = c.user_id AND c.churned_from_type = 'Trial'
  WHERE cc.detailed_segment = 'faceless_only' AND uss.user_type = 'Trial'
  
  UNION ALL
  
  SELECT
    'Faceless Only (No Avatars/Real Clones) - Paid - Last 6M' AS segment_detail,
    'Paid' AS user_type,
    COUNT(DISTINCT cc.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM content_creators cc
  INNER JOIN user_subscription_status uss ON cc.user_id = uss.user_id
  LEFT JOIN churned_users c ON cc.user_id = c.user_id AND c.churned_from_type = 'Paid'
  WHERE cc.detailed_segment = 'faceless_only' AND uss.user_type = 'Paid'
  
  UNION ALL
  
  SELECT
    'Both Faceless AND Avatars/Real Clones - Trial - Last 6M' AS segment_detail,
    'Trial' AS user_type,
    COUNT(DISTINCT cc.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM content_creators cc
  INNER JOIN user_subscription_status uss ON cc.user_id = uss.user_id
  LEFT JOIN churned_users c ON cc.user_id = c.user_id AND c.churned_from_type = 'Trial'
  WHERE cc.detailed_segment = 'both_faceless_and_creators' AND uss.user_type = 'Trial'
  
  UNION ALL
  
  SELECT
    'Both Faceless AND Avatars/Real Clones - Paid - Last 6M' AS segment_detail,
    'Paid' AS user_type,
    COUNT(DISTINCT cc.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM content_creators cc
  INNER JOIN user_subscription_status uss ON cc.user_id = uss.user_id
  LEFT JOIN churned_users c ON cc.user_id = c.user_id AND c.churned_from_type = 'Paid'
  WHERE cc.detailed_segment = 'both_faceless_and_creators' AND uss.user_type = 'Paid'
  
  UNION ALL
  
  SELECT
    'Active Users with No Content Created - Trial - Last 6M' AS segment_detail,
    'Trial' AS user_type,
    COUNT(DISTINCT au.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM active_users au
  LEFT JOIN content_creators cc ON au.user_id = cc.user_id
  INNER JOIN user_subscription_status uss ON au.user_id = uss.user_id
  LEFT JOIN churned_users c ON au.user_id = c.user_id AND c.churned_from_type = 'Trial'
  WHERE cc.user_id IS NULL AND uss.user_type = 'Trial'
  
  UNION ALL
  
  SELECT
    'Active Users with No Content Created - Paid - Last 6M' AS segment_detail,
    'Paid' AS user_type,
    COUNT(DISTINCT au.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM active_users au
  LEFT JOIN content_creators cc ON au.user_id = cc.user_id
  INNER JOIN user_subscription_status uss ON au.user_id = uss.user_id
  LEFT JOIN churned_users c ON au.user_id = c.user_id AND c.churned_from_type = 'Paid'
  WHERE cc.user_id IS NULL AND uss.user_type = 'Paid'
)

-- Final query to calculate and compare churn rates for the last 6 months with trial vs paid breakdown
SELECT
  segment_name,
  user_type,
  content_segment,
  total_users,
  churned_users,
  CASE 
    WHEN total_users > 0 THEN 
      ROUND((churned_users * 100.0) / total_users, 2)
    ELSE 0.0
  END AS churn_rate_percentage,
  
  -- Additional context metrics
  CASE 
    WHEN total_users > 0 THEN 
      ROUND(((total_users - churned_users) * 100.0) / total_users, 2)
    ELSE 0.0
  END AS retention_rate_percentage,
  
  -- Time period context
  (SELECT lookback_start_date FROM date_filter) AS analysis_start_date,
  (SELECT analysis_end_date FROM date_filter) AS analysis_end_date,
  
  -- Segment breakdown as JSON for detailed analysis
  (
    SELECT ARRAY_AGG(
      STRUCT(
        sb.segment_detail,
        sb.user_type AS detail_user_type,
        sb.user_count,
        sb.churned_count,
        CASE 
          WHEN sb.user_count > 0 THEN 
            ROUND((sb.churned_count * 100.0) / sb.user_count, 2)
          ELSE 0.0
        END AS detail_churn_rate
      )
    )
    FROM segment_breakdown sb
  ) AS detailed_breakdown

FROM segment_metrics
ORDER BY content_segment, user_type, segment_name 