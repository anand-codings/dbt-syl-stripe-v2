{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  stripe_id                                   as stripe_id,
  object                                      as object,
  
  -- Plan status and configuration
  active                                      as active,
  billing_scheme                              as billing_scheme,
  usage_type                                  as usage_type,
  aggregate_usage                             as aggregate_usage,
  
  -- Pricing information
  amount                                      as amount,
  amount_decimal                              as amount_decimal,
  currency                                    as currency,
  
  -- Billing interval
  interval                                    as interval,
  interval_count                              as interval_count,
  
  -- Trial and tiers
  trial_period_days                           as trial_period_days,
  tiers_mode                                  as tiers_mode,
  transform_usage                             as transform_usage,
  
  -- Plan details
  nickname                                    as nickname,
  product                                     as product,
  
  -- System fields
  livemode                                    as livemode,
  metadata_                                   as metadata_,
  raw_data                                    as raw_data,
  
  -- Timestamps
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','plans') }} 