{{ config(
    materialized='view',
    schema='user_management'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'user_feedback') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS user_feedback_id {{ description('Unique identifier for this piece of feedback.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('The user who submitted the feedback.') }},

    -- 3) Properties
    CAST(reason AS STRING) AS reason {{ description('The high-level reason or category for the feedback.') }},
    CAST(details AS STRING) AS details_text {{ description("The full text content of the user's feedback.") }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the feedback was submitted.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the feedback.') }}

FROM raw 