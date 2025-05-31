{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  cast(stripe_id as string)                   as stripe_id,
  cast(object as string)                      as object,
  
  -- Amount fields
  cast(amount as int64)                       as amount,
  cast(amount_capturable as int64)            as amount_capturable,
  cast(amount_received as int64)              as amount_received,
  cast(application_fee_amount as int64)       as application_fee_amount,
  
  -- Payment configuration
  cast(capture_method as string)              as capture_method,
  cast(confirmation_method as string)         as confirmation_method,
  cast(payment_method as string)              as payment_method,
  
  -- Related objects
  cast(application as string)                 as application,
  cast(customer as string)                    as customer,
  cast(invoice as string)                     as invoice,
  cast(latest_charge as string)               as latest_charge,
  
  -- Payment details
  cast(currency as string)                    as currency,
  cast(description as string)                 as description,
  cast(status as string)                      as status,
  
  -- System fields
  cast(livemode as boolean)                   as livemode,
  cast(metadata_ as string)                   as metadata_,
  
  -- Timestamps
  cast(canceled_at as timestamp)              as canceled_at,
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','payment_intents_view') }} 