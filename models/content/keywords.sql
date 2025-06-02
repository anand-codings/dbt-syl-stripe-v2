{{ config(
    materialized='view',
    schema='seo'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'keywords') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS keyword_id {{ description('Unique identifier for the keyword.') }},

    -- 2) Properties
    CAST(name AS STRING) AS keyword_name {{ description('The actual keyword string.') }},
    CAST(slug AS STRING) AS keyword_slug {{ description('URL-friendly version of the keyword.') }},
    CAST(network AS STRING) AS network {{ description('The platform or source network for the keyword.') }},
    CAST(source AS STRING) AS source {{ description('The origin or source of the keyword data.') }},

    -- 3) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the keyword was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the keyword.') }}

FROM raw 