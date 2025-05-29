{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  stripe_id                                   as stripe_id,
  object                                      as object,
  
  -- Account information
  account_country                             as account_country,
  account_name                                as account_name,
  
  -- Amount fields
  amount_due                                  as amount_due,
  amount_paid                                 as amount_paid,
  amount_remaining                            as amount_remaining,
  amount_shipping                             as amount_shipping,
  
  -- Totals and subtotals
  subtotal                                    as subtotal,
  subtotal_excluding_tax                      as subtotal_excluding_tax,
  tax                                         as tax,
  total                                       as total,
  total_excluding_tax                         as total_excluding_tax,
  total_tax_amounts                           as total_tax_amounts,
  
  -- Credit notes
  post_payment_credit_notes_amount            as post_payment_credit_notes_amount,
  pre_payment_credit_notes_amount             as pre_payment_credit_notes_amount,
  
  -- Payment processing
  attempt_count                               as attempt_count,
  auto_advance                                as auto_advance,
  automatic_tax                               as automatic_tax,
  billing_reason                              as billing_reason,
  collection_method                           as collection_method,
  
  -- Customer information
  customer                                    as customer,
  customer_tax_exempt                         as customer_tax_exempt,
  customer_tax_ids                            as customer_tax_ids,
  
  -- Tax configuration
  default_tax_rates                           as default_tax_rates,
  
  -- Invoice details
  description                                 as description,
  ending_balance                              as ending_balance,
  lines_data                                  as lines_data,
  
  -- System fields
  currency                                    as currency,
  livemode                                    as livemode,
  metadata_                                   as metadata_,
  status                                      as status,
  
  -- Timestamps
  cast(created as timestamp)                  as created,
  cast(due_date as timestamp)                 as due_date,
  cast(effective_at as timestamp)             as effective_at,
  cast(next_payment_attempt as timestamp)     as next_payment_attempt,
  cast(period_end as timestamp)               as period_end,
  cast(period_start as timestamp)             as period_start,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','invoices_view') }} 