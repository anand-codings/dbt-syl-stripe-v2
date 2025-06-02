{{ config(
    materialized='view',
    schema='user_management'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'industry_user') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS industry_user_id {{ description('Unique identifier for the user-industry relationship.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('The user in the relationship.') }},
    CAST(industry_id AS STRING) AS industry_id {{ description('The industry the user selected.') }},

    -- 3) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the link was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the link.') }}

FROM raw 