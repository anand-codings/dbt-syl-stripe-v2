{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  cast(stripe_id as string)                   as stripe_id,
  cast(object as string)                      as object,
  
  -- Account information
  cast(account_country as string)             as account_country,
  cast(account_name as string)                as account_name,
  
  -- Amount fields
  cast(amount_due as int64)                   as amount_due,
  cast(amount_paid as int64)                  as amount_paid,
  cast(amount_remaining as int64)             as amount_remaining,
  cast(amount_shipping as int64)              as amount_shipping,
  
  -- Totals and subtotals
  cast(subtotal as int64)                     as subtotal,
  cast(subtotal_excluding_tax as int64)       as subtotal_excluding_tax,
  cast(tax as int64)                          as tax,
  cast(total as int64)                        as total,
  cast(total_excluding_tax as int64)          as total_excluding_tax,
  cast(total_tax_amounts as string)           as total_tax_amounts,
  
  -- Credit notes
  cast(post_payment_credit_notes_amount as int64) as post_payment_credit_notes_amount,
  cast(pre_payment_credit_notes_amount as int64)  as pre_payment_credit_notes_amount,
  
  -- Payment processing
  cast(attempt_count as int64)                as attempt_count,
  cast(auto_advance as boolean)               as auto_advance,
  cast(automatic_tax as string)               as automatic_tax,
  cast(billing_reason as string)              as billing_reason,
  cast(collection_method as string)           as collection_method,
  
  -- Customer information
  cast(customer as string)                    as customer,
  cast(customer_tax_exempt as string)         as customer_tax_exempt,
  cast(customer_tax_ids as string)            as customer_tax_ids,
  
  -- Tax configuration
  cast(default_tax_rates as string)           as default_tax_rates,
  
  -- Invoice details
  cast(description as string)                 as description,
  cast(ending_balance as int64)               as ending_balance,
  cast(lines_data as string)                  as lines_data,
  
  -- System fields
  cast(currency as string)                    as currency,
  cast(livemode as boolean)                   as livemode,
  cast(metadata_ as string)                   as metadata_,
  cast(status as string)                      as status,
  
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