{{ config(
    materialized='view',
    schema='content'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'related_topics') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS related_topic_id {{ description('Unique identifier for the related topic.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('The user who owns the topic.') }},

    -- 3) Properties
    CAST(title AS STRING) AS topic_title {{ description('The title of the topic.') }},
    CAST(language AS STRING) AS language_code {{ description('The language code for the topic.') }},
    CAST(type AS STRING) AS topic_type {{ description('The type of topic.') }},
    CAST(provider AS STRING) AS provider {{ description('The data provider for the topic information.') }},

    -- 4) JSON
    CAST(ideas AS STRING) AS ideas_json {{ description('JSON containing linked ideas.') }},
    CAST(metadata AS STRING) AS metadata_json {{ description('JSON containing additional information.') }},

    -- 5) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the topic was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update.') }}

FROM raw 