{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                  as id,
  stripe_id                           as stripe_id,
  object                              as object,
  
  -- Financial information
  balance                             as balance,
  currency                            as currency,
  default_source                      as default_source,
  delinquent                          as delinquent,
  
  -- Customer details
  description                         as description,
  discount                            as discount,
  
  -- Invoice settings
  invoice_prefix                      as invoice_prefix,
  invoice_settings                    as invoice_settings,
  next_invoice_sequence               as next_invoice_sequence,
  
  -- Preferences and shipping
  preferred_locales                   as preferred_locales,
  shipping                            as shipping,
  tax_exempt                          as tax_exempt,
  
  -- System fields
  livemode                            as livemode,
  
  -- Timestamps
  cast(created as timestamp)          as created,
  cast(received_at as timestamp)      as received_at,
  cast(updated_at as timestamp)       as updated_at

from {{ source('stripe','customers_view') }} 