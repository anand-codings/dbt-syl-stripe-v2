-- models/videos/video_assets.sql
-- Asset linkage table connecting videos to their associated assets

{{ config(
    materialized='view',
    schema='staging'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'video_assets') }}
)

SELECT
    -- Primary identifiers
    CAST(id AS STRING) AS id {{ description('Unique asset linkage ID') }},
    CAST(model_type AS STRING) AS model_type {{ description('Type of model associated (e.g., \'video\')') }},
    CAST(model_id AS STRING) AS model_id {{ description('ID of the specific model instance') }},
    CAST(asset_id AS STRING) AS asset_id {{ description('Linked asset record ID') }},

    -- Asset properties
    CAST(`order` AS INT64) AS order_sequence {{ description('Sequential order within a video') }},
    CAST(active AS BOOLEAN) AS active {{ description('Flag indicating if asset is active') }},

    -- Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at {{ description('Linkage creation timestamp') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at {{ description('Last linkage update timestamp') }}

FROM raw 