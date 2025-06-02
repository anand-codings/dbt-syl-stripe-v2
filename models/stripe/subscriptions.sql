{{ config(
    materialized='view',
    schema='stripe'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  cast(stripe_id as string)                   as stripe_id,
  
  -- Customer and product information
  cast(customer as string)                    as customer,
  cast(product as string)                     as product,
  cast(quantity as int64)                     as quantity,
  
  -- Subscription configuration
  cast(currency as string)                    as currency,
  cast(description as string)                 as description,
  cast(status as string)                      as status,
  cast(collection_method as string)           as collection_method,
  cast(`interval` as string)                  as `interval`,
  
  -- Subscription data
  cast(items_data as string)                  as items_data,
  cast(plan_data as string)                   as plan_data,
  
  -- Cancellation information
  cast(cancellation_details as string)        as cancellation_details,
  
  -- System fields
  cast(livemode as boolean)                   as livemode,
  cast(metadata_ as string)                   as metadata_,
  cast(raw_data as string)                    as raw_data,
  
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