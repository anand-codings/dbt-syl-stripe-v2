{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  stripe_id                                   as stripe_id,
  object                                      as object,
  
  -- Refund amount and currency
  amount                                      as amount,
  currency                                    as currency,
  
  -- Related transactions
  balance_transaction                         as balance_transaction,
  charge                                      as charge,
  payment_intent                              as payment_intent,
  
  -- Transfer reversals
  source_transfer_reversal                    as source_transfer_reversal,
  transfer_reversal                           as transfer_reversal,
  
  -- Refund details
  reason                                      as reason,
  status                                      as status,
  receipt_number                              as receipt_number,
  
  -- System fields
  metadata_                                   as metadata_,
  raw_data                                    as raw_data,
  
  -- Timestamps
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','refunds') }} 