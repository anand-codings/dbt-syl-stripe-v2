{{ config(
    materialized='view',
    schema='surveys'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'surveys') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS survey_id {{ description('Unique identifier for the survey.') }},

    -- 2) Properties
    CAST(name AS STRING) AS survey_name {{ description('The name of the survey.') }},
    CAST(slug AS STRING) AS survey_slug {{ description('URL-friendly version of the survey name.') }},
    CAST(description AS STRING) AS description {{ description('A brief description of the survey.') }},
    CAST(is_active AS BOOLEAN) AS is_active {{ description('Boolean flag indicating if the survey is currently active.') }},

    -- 3) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the survey was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the survey.') }}

FROM raw 