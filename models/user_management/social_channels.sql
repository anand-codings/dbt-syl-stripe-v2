{{ config(
    materialized='view',
    schema='user_management'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'social_channels') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS social_channel_id {{ description('Unique identifier for the social channel.') }},

    -- 2) Foreign Keys
    CAST(social_account_id AS STRING) AS social_account_id {{ description('The parent social account this channel belongs to.') }},

    -- 3) Properties
    CAST(type AS STRING) AS channel_type {{ description("The type of channel (e.g., 'page', 'individual', 'group').") }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the channel was added.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the channel.') }}

FROM raw 