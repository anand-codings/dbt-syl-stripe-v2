{{ config(
    materialized='view',
    schema='content'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'answers') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS answer_id {{ description('Unique identifier for the answer.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('The user who provided the answer.') }},
    CAST(question_id AS STRING) AS question_id {{ description('The question being answered.') }},

    -- 3) Properties
    CAST(body AS STRING) AS answer_body {{ description('The text content of the answer.') }},
    CAST(type AS STRING) AS answer_type {{ description("Type of answer (e.g., 'text', 'choice', 'rating').") }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the answer was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the answer.') }}

FROM raw 