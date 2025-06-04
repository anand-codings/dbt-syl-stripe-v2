/*
============================================================================================
  User Segment Churn Analysis - Example Queries
  ---------------------------------------------
  This file contains example queries demonstrating how to use the 
  mart_user_segment_churn_analysis model for various analytical purposes.
============================================================================================
*/

-- Example 1: Basic Churn Rate Comparison
-- Compare churn rates between different user segments
SELECT
  segment_name,
  total_users,
  churned_users,
  churn_rate_percentage,
  retention_rate_percentage
FROM {{ ref('mart_user_segment_churn_analysis') }}
ORDER BY churn_rate_percentage DESC;

-- Example 2: Churn Rate Difference Analysis
-- Calculate the difference in churn rates between segments
WITH segment_comparison AS (
  SELECT
    segment_name,
    churn_rate_percentage,
    LAG(churn_rate_percentage) OVER (ORDER BY segment_name) AS prev_churn_rate
  FROM {{ ref('mart_user_segment_churn_analysis') }}
  WHERE segment_name != '3. All Users (Baseline)'
)
SELECT
  segment_name,
  churn_rate_percentage,
  prev_churn_rate,
  ROUND(churn_rate_percentage - prev_churn_rate, 2) AS churn_rate_difference,
  CASE 
    WHEN prev_churn_rate > 0 THEN 
      ROUND(((churn_rate_percentage - prev_churn_rate) / prev_churn_rate) * 100, 2)
    ELSE NULL
  END AS pct_change_in_churn_rate
FROM segment_comparison
WHERE prev_churn_rate IS NOT NULL;

-- Example 3: Risk Assessment
-- Identify which segment has higher churn risk compared to baseline
WITH baseline AS (
  SELECT churn_rate_percentage AS baseline_churn_rate
  FROM {{ ref('mart_user_segment_churn_analysis') }}
  WHERE segment_name = '3. All Users (Baseline)'
)
SELECT
  usa.segment_name,
  usa.churn_rate_percentage,
  b.baseline_churn_rate,
  ROUND(usa.churn_rate_percentage - b.baseline_churn_rate, 2) AS churn_rate_vs_baseline,
  CASE
    WHEN usa.churn_rate_percentage > b.baseline_churn_rate THEN 'Higher Risk'
    WHEN usa.churn_rate_percentage < b.baseline_churn_rate THEN 'Lower Risk'
    ELSE 'Same as Baseline'
  END AS risk_assessment
FROM {{ ref('mart_user_segment_churn_analysis') }} usa
CROSS JOIN baseline b
WHERE usa.segment_name != '3. All Users (Baseline)';

-- Example 4: Detailed Breakdown Analysis
-- Unpack the detailed breakdown to see granular segment performance
SELECT
  segment_name,
  breakdown.segment_detail,
  breakdown.user_count,
  breakdown.churned_count,
  breakdown.detail_churn_rate
FROM {{ ref('mart_user_segment_churn_analysis') }} usa,
UNNEST(usa.detailed_breakdown) AS breakdown
WHERE segment_name = '3. All Users (Baseline)'  -- Show detailed breakdown for all users
ORDER BY breakdown.detail_churn_rate DESC;

-- Example 5: Content Creation Impact Analysis
-- Analyze how content creation behavior affects churn
WITH content_behavior_analysis AS (
  SELECT
    breakdown.segment_detail,
    breakdown.user_count,
    breakdown.churned_count,
    breakdown.detail_churn_rate,
    CASE
      WHEN breakdown.segment_detail LIKE '%No Content%' THEN 'No Content Created'
      WHEN breakdown.segment_detail LIKE '%Only%' THEN 'Single Content Type'
      WHEN breakdown.segment_detail LIKE '%Both%' THEN 'Multiple Content Types'
      ELSE 'Other'
    END AS behavior_category
  FROM {{ ref('mart_user_segment_churn_analysis') }} usa,
  UNNEST(usa.detailed_breakdown) AS breakdown
  WHERE segment_name = '3. All Users (Baseline)'
)
SELECT
  behavior_category,
  SUM(user_count) AS total_users,
  SUM(churned_count) AS total_churned,
  ROUND(AVG(detail_churn_rate), 2) AS avg_churn_rate,
  ROUND((SUM(churned_count) * 100.0) / SUM(user_count), 2) AS overall_churn_rate
FROM content_behavior_analysis
GROUP BY behavior_category
ORDER BY overall_churn_rate DESC;

-- Example 6: Business Impact Summary
-- Create a summary for business stakeholders
SELECT
  'User Segment Churn Analysis Summary' AS analysis_type,
  CONCAT(
    'Users who only create avatars/real clones have a ',
    CAST(creators_only.churn_rate_percentage AS STRING),
    '% churn rate, while users who create faceless videos have a ',
    CAST(faceless.churn_rate_percentage AS STRING),
    '% churn rate. This represents a ',
    CAST(ROUND(faceless.churn_rate_percentage - creators_only.churn_rate_percentage, 2) AS STRING),
    ' percentage point difference.'
  ) AS key_insight,
  CASE
    WHEN faceless.churn_rate_percentage > creators_only.churn_rate_percentage THEN
      'Faceless video users are more likely to churn'
    WHEN faceless.churn_rate_percentage < creators_only.churn_rate_percentage THEN
      'Avatar/Real clone users are more likely to churn'
    ELSE
      'Both segments have similar churn rates'
  END AS recommendation
FROM 
  (SELECT churn_rate_percentage FROM {{ ref('mart_user_segment_churn_analysis') }} 
   WHERE segment_name = '1. Creators Only (Avatars/Real Clones)') creators_only
CROSS JOIN
  (SELECT churn_rate_percentage FROM {{ ref('mart_user_segment_churn_analysis') }} 
   WHERE segment_name = '2. Faceless Users') faceless; 