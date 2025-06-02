{{ config(
    materialized='view',
    schema='user_management'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'industries') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS industry_id {{ description('Unique identifier for the industry.') }},

    -- 2) Properties
    CAST(name AS STRING) AS industry_name {{ description('The name of the industry.') }},
    CAST(slug AS STRING) AS industry_slug {{ description('The URL-friendly version of the industry name.') }},

    -- 3) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the industry was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the industry.') }}

FROM raw 