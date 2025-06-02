{{ config(
    materialized='view',
    schema='user_management'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'social_accounts') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS social_account_id {{ description('Unique identifier for the social account connection.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('The user who owns this social account.') }},

    -- 3) Properties
    CAST(provider AS STRING) AS provider_name {{ description("The social platform name (e.g., 'facebook', 'tiktok').") }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the account was linked.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the account link.') }}

FROM raw 