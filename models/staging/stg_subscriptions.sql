{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  stripe_id                                   as stripe_id,
  
  -- Customer and product information
  customer                                    as customer,
  product                                     as product,
  quantity                                    as quantity,
  
  -- Subscription configuration
  currency                                    as currency,
  description                                 as description,
  status                                      as status,
  collection_method                           as collection_method,
  interval                                    as interval,
  
  -- Subscription data
  items_data                                  as items_data,
  plan_data                                   as plan_data,
  
  -- Cancellation information
  cancellation_details                        as cancellation_details,
  
  -- System fields
  livemode                                    as livemode,
  metadata_                                   as metadata_,
  raw_data                                    as raw_data,
  
  -- Timestamps - subscription lifecycle
  cast(created as timestamp)                  as created,
  cast(start_date as timestamp)               as start_date,
  cast(current_period_start as timestamp)     as current_period_start,
  cast(current_period_end as timestamp)       as current_period_end,
  
  -- Timestamps - trial period
  cast(trial_start as timestamp)              as trial_start,
  cast(trial_end as timestamp)                as trial_end,
  
  -- Timestamps - cancellation
  cast(cancel_at as timestamp)                as cancel_at,
  cast(canceled_at as timestamp)              as canceled_at,
  
  -- Timestamps - system
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','subscriptions') }} 