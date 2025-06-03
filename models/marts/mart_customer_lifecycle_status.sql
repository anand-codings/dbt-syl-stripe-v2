{{ config(
    materialized='table',
    schema='marts'
) }}

/*
============================================================================================
  Customer Lifecycle Status Analysis
  ----------------------------------
  This model tracks customer transitions through key lifecycle stages on a monthly basis:
    - Trial: Customer has an active trial subscription during the month
    - New: First month of paid activity
    - Active: Continuing paid activity from previous month
    - Reactivated: Returned to paid activity after being inactive
    - Churned: Became inactive after being active the previous month
  
  The results provide insights into customer acquisition, retention, and churn patterns.
  
  REFACTORED: Now uses int_customer_active_periods for DRY charge expansion logic.
============================================================================================
*/

WITH date_spine AS (
    -- Generate a series of months for the analysis window.
    -- Adjust the interval for your desired lookback period.
    SELECT
        month_start
    FROM
        UNNEST(GENERATE_DATE_ARRAY(
            DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 36 MONTH), MONTH), -- Lookback window: e.g., 36 months
            DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH), -- Up to the end of the last full month
            INTERVAL 1 MONTH
        )) AS month_start
),

customer_monthly_trial_activity AS (
    -- Determine each month a customer had trial activity, based on trial periods covering that month.
    SELECT DISTINCT
        s.customer AS customer_id,
        expanded_months AS covered_month
    FROM {{ ref('subscriptions') }} s
    CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(
        DATE_TRUNC(DATE(s.trial_start), MONTH), -- Start month of trial coverage
        DATE_TRUNC(DATE(s.trial_end), MONTH), -- End month of trial coverage (inclusive)
        INTERVAL 1 MONTH
    )) AS expanded_months
    WHERE
        s.trial_start IS NOT NULL
        AND s.trial_end IS NOT NULL
        AND s.trial_start < s.trial_end -- Valid trial period
        -- Optimization: Only process trials that could fall into the date_spine range + buffer
        AND DATE(s.trial_start) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 38 MONTH), MONTH) -- Lookback + buffer
        AND DATE(s.trial_start) < DATE_TRUNC(CURRENT_DATE(), MONTH) -- Exclude trials from the current, incomplete month
),

customer_monthly_activity AS (
    /*
      REFACTORED: Use the centralized charge expansion logic from intermediate model.
      Filter for the analysis window and get monthly activity.
    */
    SELECT DISTINCT
        customer_id,
        activity_month AS covered_month
    FROM {{ ref('int_customer_active_periods') }}
    WHERE activity_month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 38 MONTH), MONTH) -- Lookback + buffer
      AND activity_month < DATE_TRUNC(CURRENT_DATE(), MONTH) -- Exclude current incomplete month
),

customer_first_active_month AS (
    -- Find the very first month each customer had paid activity.
    SELECT
        customer_id,
        MIN(covered_month) AS first_ever_active_month
    FROM customer_monthly_activity
    GROUP BY 1
),

customer_activity_state AS (
    -- For each customer (who has ever been active or trialing) and each month in the date_spine,
    -- determine if they were active, trialing, if they were active in the previous month, and their first active month.
    SELECT
        ds.month_start,
        c.customer_id,
        cfa.first_ever_active_month,
        act_this_month.customer_id IS NOT NULL AS is_active_this_month,
        trial_this_month.customer_id IS NOT NULL AS is_trialing_this_month,
        LAG(act_this_month.customer_id IS NOT NULL, 1, FALSE) OVER (PARTITION BY c.customer_id ORDER BY ds.month_start) AS was_active_last_month
    FROM date_spine ds
    CROSS JOIN ( -- Consider all customers who have ever shown paid activity or trial activity
        SELECT DISTINCT customer_id FROM customer_monthly_activity
        UNION DISTINCT
        SELECT DISTINCT customer_id FROM customer_monthly_trial_activity
    ) c
    LEFT JOIN customer_monthly_activity act_this_month
        ON c.customer_id = act_this_month.customer_id AND ds.month_start = act_this_month.covered_month
    LEFT JOIN customer_monthly_trial_activity trial_this_month
        ON c.customer_id = trial_this_month.customer_id AND ds.month_start = trial_this_month.covered_month
    LEFT JOIN customer_first_active_month cfa
        ON c.customer_id = cfa.customer_id
),

customer_lifecycle_stages AS (
    -- Assign a lifecycle stage to each customer for each month based on their activity state.
    SELECT
        month_start,
        customer_id,
        first_ever_active_month, -- Retain for filtering in the final step
        CASE
            -- Trial State: Customer is trialing (takes precedence over paid activity)
            WHEN is_trialing_this_month THEN 'Trial'
            -- Active States are determined next for the current month
            WHEN is_active_this_month THEN
                CASE
                    WHEN month_start = first_ever_active_month THEN 'New'
                    WHEN NOT was_active_last_month AND month_start > first_ever_active_month THEN 'Reactivated' -- Implies they were inactive previously but not their first month
                    ELSE 'Active' -- Was active last month and it's not their first or reactivation month
                END
            -- Inactive State: specifically, identifying when they churned
            WHEN NOT is_active_this_month AND was_active_last_month THEN 'Churned' -- Became inactive this month but was active last month
            ELSE NULL -- Represents other states like 'Inactive for >1 month' or 'Never Active during spine'
        END AS lifecycle_stage
    FROM customer_activity_state
)

-- Final aggregation to count customers in each lifecycle stage per month.
SELECT
    cls.month_start,
    cls.lifecycle_stage,
    COUNT(DISTINCT cls.customer_id) AS customer_count
FROM customer_lifecycle_stages cls
WHERE
    cls.lifecycle_stage IS NOT NULL -- Exclude months where customer is in a non-reportable state (e.g. inactive beyond the churn month)
    -- Ensure we only report on or after a customer's first activity (paid or trial),
    -- or for the specific month they are marked as 'Churned'.
    AND (cls.first_ever_active_month <= cls.month_start OR cls.lifecycle_stage IN ('Churned', 'Trial'))
GROUP BY 1, 2
ORDER BY 1, 2 