{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                          as id,
  stripe_id                                   as stripe_id,
  object                                      as object,
  
  -- Product status and configuration
  active                                      as active,
  type                                        as type,
  
  -- Product details
  name                                        as name,
  description                                 as description,
  statement_descriptor                        as statement_descriptor,
  unit_label                                  as unit_label,
  
  -- Product features and attributes
  attributes                                  as attributes,
  features                                    as features,
  
  -- Pricing and defaults
  default_price                               as default_price,
  
  -- Media and URLs
  images                                      as images,
  url                                         as url,
  
  -- Shipping information
  shippable                                   as shippable,
  package_dimensions                          as package_dimensions,
  
  -- Tax configuration
  tax_code                                    as tax_code,
  
  -- System fields
  livemode                                    as livemode,
  metadata_                                   as metadata_,
  raw_data                                    as raw_data,
  
  -- Timestamps
  cast(created as timestamp)                  as created,
  cast(received_at as timestamp)              as received_at,
  cast(updated_at as timestamp)               as updated_at

from {{ source('stripe','products') }} 