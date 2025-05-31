{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  cast(stripe_id as string)                   as stripe_id,
  cast(object as string)                      as object,
  
  -- Product status and configuration
  cast(active as boolean)                     as active,
  cast(type as string)                        as type,
  
  -- Product details
  cast(name as string)                        as name,
  cast(description as string)                 as description,
  cast(statement_descriptor as string)        as statement_descriptor,
  cast(unit_label as string)                  as unit_label,
  
  -- Product features and attributes
  cast(attributes as string)                  as attributes,
  cast(features as string)                    as features,
  
  -- Pricing and defaults
  cast(default_price as string)               as default_price,
  
  -- Media and URLs
  cast(images as string)                      as images,
  cast(url as string)                         as url,
  
  -- Shipping information
  cast(shippable as boolean)                  as shippable,
  cast(package_dimensions as string)          as package_dimensions,
  
  -- Tax configuration
  cast(tax_code as string)                    as tax_code,
  
  -- System fields
  cast(livemode as boolean)                   as livemode,
  cast(metadata_ as string)                   as metadata_,
  cast(raw_data as string)                    as raw_data,
  
  -- Timestamps
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','products') }} 