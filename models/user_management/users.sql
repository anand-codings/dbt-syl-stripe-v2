{{ config(
    materialized='view',
    schema='user_management'
) }}

WITH raw AS (
    SELECT *
    FROM {{ source('syllaby_v2', 'users') }}
)

SELECT
    -- 1) Primary Key
    CAST(id AS STRING) AS user_id {{ description('User ID. Unique identifier for the user.') }},

    -- 2) Foreign Keys
    CAST(plan_id AS STRING) AS plan_id {{ description('Reference to the subscribed plan.') }},
    CAST(provider_id AS STRING) AS provider_id {{ description('Reference to the provider.') }},

    -- 3) User Information
    CAST(name AS STRING) AS name {{ description('Full name of the user.') }},
    CAST(email AS STRING) AS email {{ description('Email address of the user.') }},
    CAST(pm_type AS STRING) AS payment_method_type {{ description('Type of payment method used by the user.') }},
    CAST(stripe_id AS STRING) AS stripe_customer_id {{ description('Stripe customer ID for payment processing.') }},

    -- 4) User Properties
    CAST(provider AS STRING) AS account_provider {{ description("Account provider (e.g., 'google', 'email').") }},
    CAST(registration_code AS STRING) AS registration_code {{ description('The registration code used during signup, if any.') }},
    CAST(promo_code AS STRING) AS promo_code {{ description('The promotional code used by the user, if any.') }},
    CAST(user_type AS STRING) AS user_type {{ description("Type of user (e.g., 'admin', 'member').") }},
    CAST(settings AS STRING) AS user_settings {{ description('JSON string containing user preferences and settings.') }},
    CAST(notifications AS STRING) AS notification_preferences {{ description('User notification preferences and settings.') }},
    CAST(remember_token AS STRING) AS remember_token {{ description('Token used for remember me functionality.') }},

    -- 5) Credits and Billing
    CAST(remaining_credit_amount AS INT64) AS remaining_credit_amount {{ description("User's current balance of remaining credits.") }},
    CAST(monthly_credit_amount AS INT64) AS monthly_credit_amount {{ description('The number of credits allocated to the user each month.') }},
    CAST(extra_credits AS INT64) AS extra_credits {{ description('One-time additional credits granted to the user.') }},

    -- 6) Subscription and Trial Information
    CAST(trial_ends_at AS TIMESTAMP) AS trial_ends_at_ts {{ description('Timestamp when the user trial period ends.') }},
    CAST(subscription_ends_at AS TIMESTAMP) AS subscription_ends_at_ts {{ description('Timestamp when the user subscription ends.') }},

    -- 7) Verification and Communication
    CAST(email_verified_at AS DATETIME) AS email_verified_at_dt {{ description('Date and time when the user email was verified.') }},
    CAST(mailing_list AS BOOLEAN) AS is_subscribed_to_mailing_list {{ description('Whether the user is subscribed to the mailing list.') }},

    -- 8) Timestamps
    CAST(created_at AS TIMESTAMP) AS created_at_ts {{ description('Timestamp of when the user record was created.') }},
    CAST(updated_at AS TIMESTAMP) AS updated_at_ts {{ description('Timestamp of the last update to the user record.') }}

FROM raw 