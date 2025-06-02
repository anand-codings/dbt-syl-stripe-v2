{{ config(
    materialized='view',
    schema='surveys'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'questions') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS question_id {{ description('Unique identifier for the question.') }},

    -- 2) Foreign Keys
    CAST(survey_id AS STRING) AS survey_id {{ description('Reference to the survey this question belongs to.') }},

    -- 3) Properties
    CAST(title AS STRING) AS question_title {{ description('The title or text of the question.') }},
    CAST(slug AS STRING) AS question_slug {{ description('URL-friendly version of the question title.') }},
    CAST(type AS STRING) AS question_type {{ description("Type of question (e.g., 'text', 'multiple choice').") }},
    CAST(placeholder AS STRING) AS placeholder {{ description('Placeholder text shown in the UI for the answer.') }},
    CAST(selected AS STRING) AS preselected_answer {{ description('The pre-selected answer, if any.') }},
    CAST(is_active AS BOOLEAN) AS is_active {{ description('Boolean flag indicating if the question is active.') }},
    
    -- 4) JSON
    CAST(options AS STRING) AS options_json {{ description('JSON containing the answer options.') }},
    CAST(rules AS STRING) AS rules_json {{ description('JSON containing validation rules for the answer.') }},
    CAST(metadata AS STRING) AS metadata_json {{ description('JSON containing additional information about the question.') }},

    -- 5) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the question was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the question.') }}

FROM raw 