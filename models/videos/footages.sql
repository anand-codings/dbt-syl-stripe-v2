-- models/videos/footages.sql
-- Footage records containing user-owned video footage and preferences

{{ config(
    materialized='view',
    schema='staging'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'footages') }}
)

SELECT
    -- Primary identifiers
    CAST(id AS STRING) AS id {{ description('Unique footage record ID') }},
    CAST(user_id AS STRING) AS user_id {{ description('User ID of footage owner') }},
    CAST(video_id AS STRING) AS video_id {{ description('Associated video ID') }},

    -- Footage configuration
    CAST(preference AS STRING) AS preference {{ description('User settings for footage use') }},

    -- Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at {{ description('Footage creation timestamp') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at {{ description('Last footage update timestamp') }}

FROM raw 