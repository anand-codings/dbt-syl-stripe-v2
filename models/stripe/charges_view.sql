{{ config(
    materialized='view',
    schema='stripe'
) }}

select
  -- Primary identifiers
  cast(id as string)                  as id,
  cast(stripe_id as string)           as stripe_id,
  
  -- Amount fields
  cast(amount as int64)               as amount,
  cast(amount_captured as int64)      as amount_captured,
  cast(amount_refunded as int64)      as amount_refunded,
  
  -- Transaction details
  cast(balance_transaction as string) as balance_transaction,
  cast(captured as boolean)           as captured,
  cast(currency as string)            as currency,
  cast(customer as string)            as customer,
  cast(description as string)         as description,
  
  -- Status and outcome fields
  cast(disputed as boolean)           as disputed,
  cast(paid as boolean)               as paid,
  cast(refunded as boolean)           as refunded,
  cast(status as string)              as status,
  
  -- Payment method details
  cast(payment_intent as string)      as payment_intent,
  cast(payment_method as string)      as payment_method,
  cast(payment_method_details as string) as payment_method_details,
  
  -- Failure information
  cast(failure_balance_transaction as string) as failure_balance_transaction,
  cast(failure_code as string)        as failure_code,
  cast(failure_message as string)     as failure_message,
  
  -- Related objects
  cast(invoice as string)             as invoice,
  
  -- Risk and outcome
  cast(outcome_network_status as string) as outcome_network_status,
  cast(outcome_risk_level as string)  as outcome_risk_level,
  
  -- URLs and receipts
  cast(receipt_url as string)         as receipt_url,
  
  -- System fields
  cast(livemode as boolean)           as livemode,
  
  -- Timestamps
  cast(created as timestamp)          as created,
  cast(received_at as timestamp)      as received_at,
  cast(updated_at as timestamp)       as updated_at

from {{ source('stripe','charges_view') }} 