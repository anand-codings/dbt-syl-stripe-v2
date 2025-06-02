{{ config(
    materialized='view',
    schema='stripe'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  cast(stripe_id as string)                   as stripe_id,
  cast(object as string)                      as object,
  
  -- Plan status and configuration
  cast(active as boolean)                     as active,
  cast(billing_scheme as string)              as billing_scheme,
  cast(usage_type as string)                  as usage_type,
  cast(aggregate_usage as string)             as aggregate_usage,
  
  -- Pricing information
  cast(amount as int64)                       as amount,
  cast(amount_decimal as string)              as amount_decimal,
  cast(currency as string)                    as currency,
  
  -- Billing interval
  cast(`interval` as string)                  as `interval`,
  cast(interval_count as int64)               as interval_count,
  
  -- Trial and tiers
  cast(trial_period_days as int64)            as trial_period_days,
  cast(tiers_mode as string)                  as tiers_mode,
  cast(transform_usage as string)             as transform_usage,
  
  -- Plan details
  cast(nickname as string)                    as nickname,
  cast(product as string)                     as product,
  
  -- System fields
  cast(livemode as boolean)                   as livemode,
  cast(metadata_ as string)                   as metadata_,
  cast(raw_data as string)                    as raw_data,
  
  -- Timestamps
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','plans') }} 