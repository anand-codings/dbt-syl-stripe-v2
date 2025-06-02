{{ config(
    materialized='view',
    schema='user_management'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'trackers') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS tracker_id {{ description('Unique identifier for the tracker record.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('The user associated with this tracker.') }},

    -- 3) Properties
    CAST(trackable_type AS STRING) AS trackable_type {{ description("Type of item being tracked (e.g., 'faceless', 'video_export').") }},
    CAST(trackable_id AS STRING) AS trackable_id {{ description('ID of the specific item being tracked.') }},
    CAST(name AS STRING) AS tracker_name {{ description("The common name of the tracker (e.g., 'trial-exports').") }},
    CAST(count AS INT64) AS current_count {{ description('The current usage count for this tracker.') }},
    CAST("limit" AS INT64) AS tracker_limit {{ description('The limit for this tracker.') }},

    -- 4) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the tracker was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the tracker.') }}

FROM raw 