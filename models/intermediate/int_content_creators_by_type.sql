{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Content Creators by Type - Intermediate Model
  ---------------------------------------------
  This model identifies users based on their content creation activity across different
  content types (avatars, real clones, faceless videos). It's parameterized to work
  with different time periods and provides a foundation for user segmentation.
  
  Content Types:
  - Avatar creators: Users who created avatars
  - Real clone creators: Users who created real clones  
  - Faceless creators: Users who created faceless videos
  - Avatar or real clone creators: Combined avatar/real clone creators
  - All content creators: Users who created any type of content
============================================================================================
*/

WITH date_filter AS (
  {{ generate_date_filter(6) }}
),

avatar_creators AS (
  -- Users who created avatars in the specified time period
  SELECT DISTINCT
    user_id,
    'avatar' AS content_type,
    COUNT(*) AS content_count,
    MIN(DATE(created_at)) AS first_creation_date,
    MAX(DATE(created_at)) AS last_creation_date
  FROM {{ ref('avatars') }}
  CROSS JOIN date_filter df
  WHERE DATE(created_at) >= df.lookback_start_date
  GROUP BY user_id
),

real_clone_creators AS (
  -- Users who created real clones in the specified time period
  SELECT DISTINCT
    user_id,
    'real_clone' AS content_type,
    COUNT(*) AS content_count,
    MIN(DATE(created_at)) AS first_creation_date,
    MAX(DATE(created_at)) AS last_creation_date
  FROM {{ ref('real_clones') }}
  CROSS JOIN date_filter df
  WHERE DATE(created_at) >= df.lookback_start_date
  GROUP BY user_id
),

faceless_creators AS (
  -- Users who created faceless videos in the specified time period
  SELECT DISTINCT
    user_id,
    'faceless' AS content_type,
    COUNT(*) AS content_count,
    MIN(DATE(created_at)) AS first_creation_date,
    MAX(DATE(created_at)) AS last_creation_date
  FROM {{ ref('facelesses') }}
  CROSS JOIN date_filter df
  WHERE DATE(created_at) >= df.lookback_start_date
  GROUP BY user_id
),

all_content_creators AS (
  -- Combine all content creators with their activity
  SELECT * FROM avatar_creators
  UNION ALL
  SELECT * FROM real_clone_creators  
  UNION ALL
  SELECT * FROM faceless_creators
),

user_content_summary AS (
  -- Summarize each user's content creation activity
  SELECT
    user_id,
    ARRAY_AGG(DISTINCT content_type) AS content_types_created,
    SUM(content_count) AS total_content_count,
    MIN(first_creation_date) AS earliest_creation_date,
    MAX(last_creation_date) AS latest_creation_date,
    
    -- Content type flags for easy filtering
    MAX(CASE WHEN content_type = 'avatar' THEN 1 ELSE 0 END) AS created_avatars,
    MAX(CASE WHEN content_type = 'real_clone' THEN 1 ELSE 0 END) AS created_real_clones,
    MAX(CASE WHEN content_type = 'faceless' THEN 1 ELSE 0 END) AS created_faceless,
    
    -- Segment classifications
    CASE 
      WHEN MAX(CASE WHEN content_type = 'faceless' THEN 1 ELSE 0 END) = 1 THEN 'faceless_user'
      WHEN MAX(CASE WHEN content_type IN ('avatar', 'real_clone') THEN 1 ELSE 0 END) = 1 THEN 'creator_only'
      ELSE 'other'
    END AS primary_segment,
    
    CASE
      WHEN MAX(CASE WHEN content_type = 'faceless' THEN 1 ELSE 0 END) = 1 
           AND MAX(CASE WHEN content_type IN ('avatar', 'real_clone') THEN 1 ELSE 0 END) = 1 
           THEN 'both_faceless_and_creators'
      WHEN MAX(CASE WHEN content_type = 'faceless' THEN 1 ELSE 0 END) = 1 
           AND MAX(CASE WHEN content_type IN ('avatar', 'real_clone') THEN 1 ELSE 0 END) = 0 
           THEN 'faceless_only'
      WHEN MAX(CASE WHEN content_type = 'faceless' THEN 1 ELSE 0 END) = 0 
           AND MAX(CASE WHEN content_type IN ('avatar', 'real_clone') THEN 1 ELSE 0 END) = 1 
           THEN 'creators_only'
      ELSE 'no_content'
    END AS detailed_segment
    
  FROM all_content_creators
  GROUP BY user_id
)

SELECT
  user_id,
  content_types_created,
  total_content_count,
  earliest_creation_date,
  latest_creation_date,
  created_avatars,
  created_real_clones,
  created_faceless,
  primary_segment,
  detailed_segment,
  
  -- Time period context
  (SELECT lookback_start_date FROM date_filter) AS analysis_start_date,
  (SELECT analysis_end_date FROM date_filter) AS analysis_end_date
  
FROM user_content_summary 