{{ config(
    materialized='view',
    schema='content'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'bookmarks') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS bookmark_id {{ description('Unique identifier for the bookmark.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('The user who created the bookmark.') }},

    -- 3) Polymorphic Relationship
    CAST(model_type AS STRING) AS bookmarked_model_type {{ description("Type of model bookmarked (e.g., 'asset', 'video').") }},
    CAST(model_id AS STRING) AS bookmarked_model_id {{ description('The ID of the model that is bookmarked.') }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the bookmark was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the bookmark.') }}

FROM raw 