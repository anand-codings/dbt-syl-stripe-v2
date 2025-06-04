{{ config(materialized='table', schema='marts') }}

/*
============================================================================================
  User Segment Churn Analysis
  ---------------------------
  This model analyzes churn rates for different user segments based on their content 
  creation activity. It compares churn rates between users who only create avatars/real 
  clones versus users who create faceless videos.
  
  REFACTORED: Now uses intermediate models for better maintainability and reusability:
  - int_content_creators_by_type for content segmentation
  - int_all_churned_users for churn identification
  - int_active_users for baseline user counts
  
  Key Segments:
  - Creators Only: Users who ONLY create avatars/real clones (and NOT faceless videos)
  - Faceless Users: Users who create faceless videos (may or may not create other types)
  - All Users: Baseline churn rate for comparison
  
  Key Metrics:
  - Total users per segment
  - Churned users per segment  
  - Churn rate percentage per segment
  - Comparative analysis between segments
============================================================================================
*/

WITH segment_creators_only AS (
  -- Define User Segment 1: Users who ONLY create avatars/real clones (and NOT faceless)
  SELECT user_id
  FROM {{ ref('int_content_creators_by_type') }}
  WHERE detailed_segment = 'creators_only'
),

segment_faceless_users AS (
  -- Define User Segment 2: Users who create faceless videos (and may or may not create other types)
  SELECT user_id
  FROM {{ ref('int_content_creators_by_type') }}
  WHERE created_faceless = 1
),

segment_metrics AS (
  -- Calculate metrics for each segment
  SELECT
    '1. Creators Only (Avatars/Real Clones)' AS segment_name,
    COUNT(DISTINCT s.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM segment_creators_only s
  LEFT JOIN {{ ref('int_all_churned_users') }} c 
    ON s.user_id = c.user_id

  UNION ALL

  SELECT
    '2. Faceless Users' AS segment_name,
    COUNT(DISTINCT s.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM segment_faceless_users s
  LEFT JOIN {{ ref('int_all_churned_users') }} c 
    ON s.user_id = c.user_id

  UNION ALL

  SELECT
    '3. All Users (Baseline)' AS segment_name,
    COUNT(DISTINCT a.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS churned_users
  FROM {{ ref('int_active_users') }} a
  LEFT JOIN {{ ref('int_all_churned_users') }} c 
    ON a.user_id = c.user_id
),

segment_breakdown AS (
  -- Additional breakdown showing overlap between segments using intermediate model
  SELECT
    'Creators Only (No Faceless)' AS segment_detail,
    COUNT(DISTINCT cc.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM {{ ref('int_content_creators_by_type') }} cc
  LEFT JOIN {{ ref('int_all_churned_users') }} c ON cc.user_id = c.user_id
  WHERE cc.detailed_segment = 'creators_only'
  
  UNION ALL
  
  SELECT
    'Faceless Only (No Avatars/Real Clones)' AS segment_detail,
    COUNT(DISTINCT cc.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM {{ ref('int_content_creators_by_type') }} cc
  LEFT JOIN {{ ref('int_all_churned_users') }} c ON cc.user_id = c.user_id
  WHERE cc.detailed_segment = 'faceless_only'
  
  UNION ALL
  
  SELECT
    'Both Faceless AND Avatars/Real Clones' AS segment_detail,
    COUNT(DISTINCT cc.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM {{ ref('int_content_creators_by_type') }} cc
  LEFT JOIN {{ ref('int_all_churned_users') }} c ON cc.user_id = c.user_id
  WHERE cc.detailed_segment = 'both_faceless_and_creators'
  
  UNION ALL
  
  SELECT
    'No Content Created' AS segment_detail,
    COUNT(DISTINCT au.user_id) AS user_count,
    COUNT(DISTINCT c.user_id) AS churned_count
  FROM {{ ref('int_active_users') }} au
  LEFT JOIN {{ ref('int_content_creators_by_type') }} cc ON au.user_id = cc.user_id
  LEFT JOIN {{ ref('int_all_churned_users') }} c ON au.user_id = c.user_id
  WHERE cc.user_id IS NULL
)

-- Final query to calculate and compare churn rates
SELECT
  segment_name,
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
  
  -- Segment breakdown as JSON for detailed analysis
  (
    SELECT ARRAY_AGG(
      STRUCT(
        sb.segment_detail,
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
ORDER BY segment_name 