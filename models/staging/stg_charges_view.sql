{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                  as id,
  stripe_id                           as stripe_id,
  
  -- Amount fields
  amount                              as amount,
  amount_captured                     as amount_captured,
  amount_refunded                     as amount_refunded,
  
  -- Transaction details
  balance_transaction                 as balance_transaction,
  captured                            as captured,
  currency                            as currency,
  customer                            as customer,
  description                         as description,
  
  -- Status and outcome fields
  disputed                            as disputed,
  paid                                as paid,
  refunded                            as refunded,
  status                              as status,
  
  -- Payment method details
  payment_intent                      as payment_intent,
  payment_method                      as payment_method,
  payment_method_details              as payment_method_details,
  
  -- Failure information
  failure_balance_transaction         as failure_balance_transaction,
  failure_code                        as failure_code,
  failure_message                     as failure_message,
  
  -- Related objects
  invoice                             as invoice,
  
  -- Risk and outcome
  outcome_network_status              as outcome_network_status,
  outcome_risk_level                  as outcome_risk_level,
  
  -- URLs and receipts
  receipt_url                         as receipt_url,
  
  -- System fields
  livemode                            as livemode,
  
  -- Timestamps
  cast(created as timestamp)          as created,
  cast(received_at as timestamp)      as received_at,
  cast(updated_at as timestamp)       as updated_at

from {{ source('stripe','charges_view') }} 