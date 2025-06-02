{{ config(
    materialized='view',
    schema='content'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'keyword_user') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS keyword_user_id {{ description('Unique identifier for the keyword-user link.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('Reference to the user.') }},
    CAST(keyword_id AS STRING) AS keyword_id {{ description('Reference to the associated keyword.') }},

    -- 3) JSON
    CAST(audience AS STRING) AS audience_json {{ description('JSON containing target audience or segmentation information.') }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the link was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update.') }}

FROM raw 