{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  stripe_id                                   as stripe_id,
  object                                      as object,
  
  -- Price status and configuration
  active                                      as active,
  billing_scheme                              as billing_scheme,
  type                                        as type,
  
  -- Pricing information
  unit_amount                                 as unit_amount,
  unit_amount_decimal                         as unit_amount_decimal,
  custom_unit_amount                          as custom_unit_amount,
  currency                                    as currency,
  
  -- Recurring billing configuration
  recurring_aggregate_usage                   as recurring_aggregate_usage,
  recurring_interval                          as recurring_interval,
  recurring_interval_count                    as recurring_interval_count,
  recurring_trial_period_days                 as recurring_trial_period_days,
  recurring_usage_type                        as recurring_usage_type,
  
  -- Tiers and transformations
  tiers_mode                                  as tiers_mode,
  transform_quantity                          as transform_quantity,
  
  -- Tax and product information
  tax_behavior                                as tax_behavior,
  product                                     as product,
  
  -- Price details
  lookup_key                                  as lookup_key,
  nickname                                    as nickname,
  
  -- System fields
  livemode                                    as livemode,
  metadata_                                   as metadata_,
  raw_data                                    as raw_data,
  
  -- Timestamps
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','prices') }} 