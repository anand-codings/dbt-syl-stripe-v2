{{ config(
    materialized='view',
    schema='content'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'ideas') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS idea_id {{ description('Unique identifier for the idea.') }},

    -- 2) Foreign Keys
    CAST(keyword_id AS STRING) AS keyword_id {{ description('Reference to a related keyword.') }},

    -- 3) Properties
    CAST(title AS STRING) AS idea_title {{ description('The title of the idea.') }},
    CAST(slug AS STRING) AS idea_slug {{ description('URL-friendly identifier for the idea.') }},
    CAST(type AS STRING) AS idea_type {{ description('The type or category of the idea.') }},
    CAST(trend AS STRING) AS trend_status {{ description('The trend status of the idea.') }},
    CAST(country AS STRING) AS country_code {{ description('The country where the idea is relevant.') }},
    CAST(currency AS STRING) AS currency_code {{ description('The currency related to the idea\'s metrics.') }},
    CAST(locale AS STRING) AS locale {{ description("Locale information (e.g., 'en-US').") }},
    CAST(volume AS INT64) AS search_volume {{ description('The search volume for the keyword.') }},
    CAST(cpc AS FLOAT64) AS cost_per_click {{ description('The cost-per-click value.') }},
    CAST(competition AS FLOAT64) AS competition_score {{ description('Numeric value of the keyword competition.') }},
    CAST(competition_label AS STRING) AS competition_label {{ description('Descriptive label for the competition level.') }},
    CAST(total_results AS INT64) AS total_results {{ description('The total number of search results for the keyword.') }},
    CAST(public AS BOOLEAN) AS is_public {{ description('Boolean flag indicating if the idea is publicly visible.') }},

    -- 4) JSON
    CAST(trends AS STRING) AS trends_json {{ description('JSON containing time-based trend data.') }},

    -- 5) Timestamps
    CAST(valid_until AS TIMESTAMP) AS valid_until_ts {{ description('The expiry date for the idea data.') }},
    CAST(deleted_at AS TIMESTAMP) AS deleted_at_ts {{ description('Timestamp of deletion (if soft deleted).') }},
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the idea was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the idea.') }}

FROM raw 