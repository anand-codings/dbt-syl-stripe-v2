-- models/videos/facelesses.sql

{{ config(
    materialized='view',
    schema='staging'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'facelesses') }}
)

SELECT
    -- 1) Primary IDs
    CAST(id AS STRING) AS id {{ description('Unique faceless video instance ID') }},
    CAST(user_id AS STRING) AS user_id {{ description('Creator\'s user ID') }},
    CAST(video_id AS STRING) AS video_id {{ description('Associated video ID') }},
    CAST(voice_id AS STRING) AS voice_id {{ description('Voice used in the video') }},
    CAST(background_id AS STRING) AS background_id {{ description('Background media used') }},
    CAST(music_id AS STRING) AS music_id {{ description('Music track used') }},
    CAST(watermark_id AS STRING) AS watermark_id {{ description('Applied watermark ID') }},

    -- 2) Metrics / amounts
    CAST(estimated_duration AS INT64) AS estimated_duration {{ description('Estimated video length in seconds') }},

    -- 3) Flags / booleans
    CAST(is_transcribed AS BOOLEAN) AS is_transcribed {{ description('Flag if audio is transcribed') }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at {{ description('Entry creation timestamp') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at {{ description('Last entry update timestamp') }},

    -- 5) JSON / details as strings
    CAST(options AS STRING) AS options {{ description('Configuration options') }},
    CAST(script AS STRING) AS script {{ description('Script text for narration') }},

    -- 6) Other String Fields
    CAST(type AS STRING) AS type {{ description('Creation method (e.g., \'AI-generated\')') }},
    CAST(genre AS STRING) AS genre {{ description('Content genre/theme') }}

FROM raw 