-- models/videos/syllaby_real_clones.sql

{{ config(
    materialized='view',
    schema='staging'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'real_clones') }}
)

SELECT
    -- 1) Primary IDs
    CAST(id AS STRING) AS id {{ description('Unique real clone ID') }},
    CAST(user_id AS STRING) AS user_id {{ description('Associated user ID') }},
    CAST(footage_id AS STRING) AS footage_id {{ description('Source footage ID for cloning') }},
    CAST(voice_id AS STRING) AS voice_id {{ description('Voice model used') }},
    CAST(avatar_id AS STRING) AS avatar_id {{ description('Linked avatar ID') }},

    -- 2) Metrics / amounts
    CAST(retries AS INT64) AS retries {{ description('Number of generation attempts') }},

    -- 3) Timestamps
    CAST(synced_at AS TIMESTAMP) AS synced_at {{ description('Synchronization timestamp') }},
    CAST(created_at AS TIMESTAMP) AS created_at {{ description('Record creation timestamp') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at {{ description('Last modification timestamp') }},

    -- 4) JSON / details as strings
    CAST(background AS STRING) AS background {{ description('Background settings for the clone') }},

    -- 5) Other String Fields
    CAST(provider AS STRING) AS provider {{ description('Service provider for generation') }},
    CAST(script AS STRING) AS script {{ description('Text script used in the clone') }},
    CAST(status AS STRING) AS status {{ description('Generation process status') }}

FROM raw 