{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                  as id,
  cast(stripe_id as string)           as stripe_id,
  cast(object as string)              as object,
  
  -- Financial information
  cast(balance as int64)              as balance,
  cast(currency as string)            as currency,
  cast(default_source as string)      as default_source,
  cast(delinquent as boolean)         as delinquent,
  
  -- Customer details
  cast(description as string)         as description,
  cast(discount as string)            as discount,
  
  -- Invoice settings
  cast(invoice_prefix as string)      as invoice_prefix,
  cast(invoice_settings as string)    as invoice_settings,
  cast(next_invoice_sequence as int64) as next_invoice_sequence,
  
  -- Preferences and shipping
  cast(preferred_locales as string)   as preferred_locales,
  cast(shipping as string)            as shipping,
  cast(tax_exempt as string)          as tax_exempt,
  
  -- System fields
  cast(livemode as boolean)           as livemode,
  
  -- Timestamps
  cast(created as timestamp)          as created,
  cast(received_at as timestamp)      as received_at,
  cast(updated_at as timestamp)       as updated_at

from {{ source('stripe','customers_view') }} 