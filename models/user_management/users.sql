{{ config(
    materialized='view',
    schema='user_management'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'users') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS user_id {{ description('User ID. Unique identifier for the user.') }},

    -- 2) Foreign Keys
    CAST(plan_id AS STRING) AS plan_id {{ description('Reference to the subscribed plan.') }},

    -- 3) Properties
    CAST(provider AS STRING) AS account_provider {{ description("Account provider (e.g., 'google', 'email').") }},
    CAST(registration_code AS STRING) AS registration_code {{ description('The registration code used during signup, if any.') }},
    CAST(promo_code AS STRING) AS promo_code {{ description('The promotional code used by the user, if any.') }},
    CAST(user_type AS STRING) AS user_type {{ description("Type of user (e.g., 'admin', 'member').") }},
    CAST(remaining_credit_amount AS INT64) AS remaining_credit_amount {{ description("User's current balance of remaining credits.") }},
    CAST(monthly_credit_amount AS INT64) AS monthly_credit_amount {{ description('The number of credits allocated to the user each month.') }},
    CAST(extra_credits AS INT64) AS extra_credits {{ description('One-time additional credits granted to the user.') }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the user record was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the user record.') }}

FROM raw 