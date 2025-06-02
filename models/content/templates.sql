{{ config(
    materialized='view',
    schema='content'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'templates') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS template_id {{ description('Unique identifier for the template.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('The user who created the template.') }},

    -- 3) Properties
    CAST(name AS STRING) AS template_name {{ description('The name of the template.') }},
    CAST(slug AS STRING) AS template_slug {{ description('URL-friendly version of the template name.') }},
    CAST(description AS STRING) AS description {{ description('A brief description of the template.') }},
    CAST(type AS STRING) AS template_type {{ description('The type or category of the template.') }},
    CAST(is_active AS BOOLEAN) AS is_active {{ description('Boolean flag indicating if the template is active.') }},

    -- 4) JSON
    CAST(metadata AS STRING) AS metadata_json {{ description('JSON containing additional information about the template.') }},

    -- 5) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the template was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the template.') }}

FROM raw 