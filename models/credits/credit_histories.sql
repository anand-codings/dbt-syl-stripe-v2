{{ config(
    materialized='view',
    schema='credits'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'credit_histories') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS credit_history_id {{ description('Unique identifier for the credit history entry.') }},

    -- 2) Foreign Keys
    CAST(user_id AS STRING) AS user_id {{ description('User associated with the credit event.') }},
    CAST(credit_events_id AS STRING) AS credit_event_id {{ description('Reference to the credit event that triggered this history.') }},

    -- 3) Polymorphic Relationship
    CAST(creditable_type AS STRING) AS creditable_type {{ description("Type of the related resource (e.g., 'video', 'purchase').") }},
    CAST(creditable_id AS STRING) AS creditable_id {{ description('ID of the related resource.') }},

    -- 4) Properties
    CAST(description AS STRING) AS description {{ description('Description of the credit event in context.') }},
    CAST(label AS STRING) AS label {{ description('Label for UI display.') }},
    CAST(calculative_index AS INT64) AS calculative_index {{ description('Index used for internal credit calculation logic.') }},
    CAST(event_value AS STRING) AS event_value {{ description("Value of the event (e.g., '+10', '-5').") }},
    CAST(amount AS FLOAT64) AS amount {{ description('Amount of credits added or deducted.') }},
    CAST(previous_amount AS FLOAT64) AS previous_amount {{ description('Balance before the event occurred.') }},
    CAST(event_type AS STRING) AS credit_history_event_type {{ description("Type of the event (e.g., 'debit', 'credit').") }},

    -- 5) JSON
    CAST(meta AS STRING) AS meta_data {{ description('Additional metadata or notes.') }},

    -- 6) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp when the credit history entry was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp when the entry was last modified.') }}

FROM raw 