{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Customer Latest Subscription
  ----------------------------
  This intermediate model provides each customer's latest/primary subscription
  information, extracted from the customer segmentation logic for reuse across
  multiple mart models.
  
  The ranking prioritizes:
  1. Active subscriptions first
  2. Most recent start date
  3. Most recent creation date
  
  This model is used by:
  - mart_customer_segmentation
  - Any other marts needing current subscription info
============================================================================================
*/

WITH subscriptions_ranked AS (
  -- Get all subscriptions and rank them to find the latest/primary one
  SELECT
    s.id AS subscription_id,
    s.customer AS customer_id,
    JSON_EXTRACT_SCALAR(s.plan_data, '$.id') AS plan_id,
    s.status AS subscription_status,
    s.start_date AS subscription_start_date,
    s.created AS subscription_created_at,
    s.current_period_start,
    s.current_period_end,
    ROW_NUMBER() OVER (
      PARTITION BY s.customer
      ORDER BY
        CASE s.status
          WHEN 'active' THEN 1
          WHEN 'trialing' THEN 2
          WHEN 'past_due' THEN 3
          ELSE 4 -- canceled, incomplete, incomplete_expired, unpaid
        END,
        s.start_date DESC,
        s.created DESC
    ) AS rn
  FROM {{ ref('subscriptions') }} s
),

latest_customer_subscription_plan AS (
  -- Select the #1 ranked subscription for each customer and join to get plan details
  SELECT
    sr.customer_id,
    sr.subscription_id,
    sr.subscription_status,
    sr.subscription_start_date,
    sr.current_period_start,
    sr.current_period_end,
    p.stripe_id AS plan_stripe_id,
    COALESCE(p.nickname, p.stripe_id) AS plan_name,
    p.interval AS plan_billing_interval,
    p.amount AS plan_amount_cents
  FROM subscriptions_ranked sr
  LEFT JOIN {{ ref('plans') }} p ON sr.plan_id = p.stripe_id
  WHERE sr.rn = 1
)

SELECT * FROM latest_customer_subscription_plan 