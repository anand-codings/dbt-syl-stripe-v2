{{ config(
    materialized='view',
    schema='tagging'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'taggables') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS taggable_record_id {{ description('Unique identifier for the tagging record.') }},

    -- 2) Foreign Keys
    CAST(tag_id AS STRING) AS tag_id {{ description('Reference to the associated tag.') }},

    -- 3) Polymorphic Relationship
    CAST(taggable_type AS STRING) AS taggable_type {{ description('The type of entity being tagged.') }},
    CAST(taggable_id AS STRING) AS taggable_id {{ description('The ID of the entity being tagged.') }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the tag was applied.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the record.') }}

FROM raw 