-- models/videos/syllaby_avatars.sql

{{ config(
    materialized='view',
    schema='staging'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'avatars') }}
)

SELECT
    -- 1) Primary IDs
    CAST(id AS STRING) AS id {{ description('Unique avatar identifier') }},
    CAST(user_id AS STRING) AS user_id {{ description('Owner\'s user ID') }},
    CAST(provider_id AS STRING) AS provider_id {{ description('External provider\'s reference ID') }},

    -- 2) Flags / booleans
    CAST(is_active AS BOOLEAN) AS is_active {{ description('Flag indicating if avatar is active') }},

    -- 3) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at {{ description('Record creation timestamp') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at {{ description('Last modification timestamp') }},

    -- 4) JSON / details as strings
    CAST(metadata AS STRING) AS metadata {{ description('Additional avatar attributes') }},

    -- 5) Other String Fields
    CAST(name AS STRING) AS name {{ description('Avatar\'s display name') }},
    CAST(gender AS STRING) AS gender {{ description('Gender attributed to the avatar') }},
    CAST(race AS STRING) AS race {{ description('Ethnicity/race of the avatar') }},
    CAST(preview_url AS STRING) AS preview_url {{ description('URL for avatar preview') }},
    CAST(provider AS STRING) AS provider {{ description('Source or creator of the avatar') }},
    CAST(type AS STRING) AS type {{ description('Avatar category (e.g., \'real-clone\')') }}

FROM raw 