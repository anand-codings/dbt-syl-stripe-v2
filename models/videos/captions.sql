-- models/videos/syllaby_captions.sql

{{ config(
    materialized='view',
    schema='staging'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'captions') }}
)

SELECT
    -- 1) Primary IDs
    CAST(id AS STRING) AS id {{ description('Unique caption ID') }},
    CAST(user_id AS STRING) AS user_id {{ description('Caption creator\'s user ID') }},
    CAST(model_id AS STRING) AS model_id {{ description('ID of the associated model instance') }},

    -- 2) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at {{ description('Caption creation timestamp') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at {{ description('Last caption update timestamp') }},

    -- 3) JSON / details as strings
    CAST(content AS STRING) AS content {{ description('JSON representation of caption text') }},

    -- 4) Other String Fields
    CAST(model_type AS STRING) AS model_type {{ description('Model type linked to caption (e.g., \'video\')') }},
    CAST(provider AS STRING) AS provider {{ description('Caption generation service (e.g., \'ElevenLabs\')') }}

FROM raw 