-- models/videos/videos.sql
-- Main videos table containing video metadata and lifecycle information

{{ config(
    materialized='view',
    schema='staging'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'videos') }}
)

SELECT
    -- Primary identifiers
    CAST(id AS STRING) AS id {{ description('Unique video identifier') }},
    CAST(user_id AS STRING) AS user_id {{ description('Creator\'s user ID') }},
    CAST(idea_id AS STRING) AS idea_id {{ description('Linked content idea ID') }},
    CAST(scheduler_id AS STRING) AS scheduler_id {{ description('Reference to publication scheduler') }},

    -- Video metadata
    CAST(title AS STRING) AS title {{ description('Video display title') }},
    CAST(provider AS STRING) AS provider {{ description('Hosting or generation platform') }},
    CAST(type AS STRING) AS type {{ description('Video category (e.g., \'faceless\')') }},
    CAST(status AS STRING) AS status {{ description('Current video lifecycle status (e.g., \'completed\')') }},

    -- JSON data fields
    CAST(metadata AS STRING) AS metadata {{ description('Unstructured additional video data (e.g., resolution, tags)') }},
    CAST(exports AS STRING) AS exports {{ description('Info on exported video versions') }},

    -- Timestamps
    CAST(synced_at AS TIMESTAMP) AS synced_at {{ description('Last external synchronization time') }},
    CAST(created_at AS TIMESTAMP) AS created_at {{ description('Record creation timestamp') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at {{ description('Last modification timestamp') }}

FROM raw 