{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  cast(stripe_id as string)                   as stripe_id,
  cast(object as string)                      as object,
  
  -- Refund amount and currency
  cast(amount as int64)                       as amount,
  cast(currency as string)                    as currency,
  
  -- Related transactions
  cast(balance_transaction as string)         as balance_transaction,
  cast(charge as string)                      as charge,
  cast(payment_intent as string)              as payment_intent,
  
  -- Transfer reversals
  cast(source_transfer_reversal as string)    as source_transfer_reversal,
  cast(transfer_reversal as string)           as transfer_reversal,
  
  -- Refund details
  cast(reason as string)                      as reason,
  cast(status as string)                      as status,
  cast(receipt_number as string)              as receipt_number,
  
  -- System fields
  cast(metadata_ as string)                   as metadata_,
  cast(raw_data as string)                    as raw_data,
  
  -- Timestamps
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','refunds') }} 