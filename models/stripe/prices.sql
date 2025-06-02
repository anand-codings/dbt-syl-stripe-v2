{{ config(
    materialized='view',
    schema='stripe'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  cast(stripe_id as string)                   as stripe_id,
  cast(object as string)                      as object,
  
  -- Price status and configuration
  cast(active as boolean)                     as active,
  cast(billing_scheme as string)              as billing_scheme,
  cast(type as string)                        as type,
  
  -- Pricing information
  cast(unit_amount as int64)                  as unit_amount,
  cast(unit_amount_decimal as string)         as unit_amount_decimal,
  cast(custom_unit_amount as string)          as custom_unit_amount,
  cast(currency as string)                    as currency,
  
  -- Recurring billing configuration
  cast(recurring_aggregate_usage as string)   as recurring_aggregate_usage,
  cast(recurring_interval as string)          as recurring_interval,
  cast(recurring_interval_count as int64)     as recurring_interval_count,
  cast(recurring_trial_period_days as int64)  as recurring_trial_period_days,
  cast(recurring_usage_type as string)        as recurring_usage_type,
  
  -- Tiers and transformations
  cast(tiers_mode as string)                  as tiers_mode,
  cast(transform_quantity as string)          as transform_quantity,
  
  -- Tax and product information
  cast(tax_behavior as string)                as tax_behavior,
  cast(product as string)                     as product,
  
  -- Price details
  cast(lookup_key as string)                  as lookup_key,
  cast(nickname as string)                    as nickname,
  
  -- System fields
  cast(livemode as boolean)                   as livemode,
  cast(metadata_ as string)                   as metadata_,
  cast(raw_data as string)                    as raw_data,
  
  -- Timestamps
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','prices') }} 