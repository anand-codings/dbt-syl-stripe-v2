{{ config(
    materialized='view',
    schema='tagging'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'tags') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS tag_id {{ description('Unique identifier for the tag.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('The user who created the tag.') }},

    -- 3) Properties
    CAST(name AS STRING) AS tag_name {{ description('The name of the tag.') }},
    CAST(slug AS STRING) AS tag_slug {{ description('URL-friendly version of the tag name.') }},
    CAST(color AS STRING) AS color_hex {{ description('The color assigned to the tag for UI display.') }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the tag was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the tag.') }}

FROM raw 