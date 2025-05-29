{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  stripe_id                                   as stripe_id,
  object                                      as object,
  
  -- Amount fields
  amount                                      as amount,
  amount_capturable                           as amount_capturable,
  amount_received                             as amount_received,
  application_fee_amount                      as application_fee_amount,
  
  -- Payment configuration
  capture_method                              as capture_method,
  confirmation_method                         as confirmation_method,
  payment_method                              as payment_method,
  
  -- Related objects
  application                                 as application,
  customer                                    as customer,
  invoice                                     as invoice,
  latest_charge                               as latest_charge,
  
  -- Payment details
  currency                                    as currency,
  description                                 as description,
  status                                      as status,
  
  -- System fields
  livemode                                    as livemode,
  metadata_                                   as metadata_,
  
  -- Timestamps
  cast(canceled_at as timestamp)              as canceled_at,
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','payment_intents_view') }} 