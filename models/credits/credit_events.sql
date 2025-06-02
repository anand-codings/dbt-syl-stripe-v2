{{ config(
    materialized='view',
    schema='credits'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'credit_events') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS credit_event_id {{ description('Unique identifier for the credit event.') }},

    -- 2) Properties
    CAST(name AS STRING) AS credit_event_name {{ description('Name of the credit event.') }},
    CAST(type AS STRING) AS event_type {{ description("Type of event (e.g., 'bonus', 'penalty', 'usage').") }},
    CAST(calculation_type AS STRING) AS calculation_type {{ description("Method of calculating credits (e.g., 'fixed', 'percentage').") }},
    CAST(value AS FLOAT64) AS value {{ description('Value associated with the event.') }},
    CAST(min_amount AS FLOAT64) AS min_amount {{ description('Minimum qualifying amount for the event.') }},

    -- 3) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the event was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the event.') }}

FROM raw 