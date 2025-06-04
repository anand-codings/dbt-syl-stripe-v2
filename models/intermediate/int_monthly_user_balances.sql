{{ config(materialized='table', schema='intermediate') }}

/*
============================================================================================
  Monthly User Balances - Intermediate Model
  ------------------------------------------
  This model provides monthly credit balance data for users, extracted from the
  credit churn risk analysis for reuse across multiple balance-related models.
  
  Key Logic:
  - Provides end-of-month balance for each user by month
  - Sourced from mart_monthly_credit_balance
  - Standardized date format for consistent joins
  
  This model is used by:
  - mart_credit_churn_risk
  - Any other models needing monthly balance data
============================================================================================
*/

SELECT
  user_id,
  DATE(month) AS month,
  cumulative_balance AS end_of_month_balance
FROM {{ ref('mart_monthly_credit_balance') }} 