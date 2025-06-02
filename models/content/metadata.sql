{{ config(
    materialized='view',
    schema='content'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'metadata') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS metadata_id {{ description('Unique identifier for the metadata record.') }},

    -- 2) Properties
    CAST(type AS STRING) AS metadata_type {{ description('The type of metadata.') }},
    CAST(provider AS STRING) AS provider_name {{ description('The name of the metadata provider.') }},
    CAST("key" AS STRING) AS metadata_key {{ description('The key identifier for the metadata.') }},

    -- 3) JSON
    CAST(values AS STRING) AS values_json {{ description('The metadata values, stored as a JSON string.') }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the metadata was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update.') }}

FROM raw 