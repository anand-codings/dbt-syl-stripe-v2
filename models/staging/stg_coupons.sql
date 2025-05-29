{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                  as id,
  stripe_id                           as stripe_id,
  object                              as object,
  
  -- Discount configuration
  amount_off                          as amount_off,
  percent_off                         as percent_off,
  currency                            as currency,
  
  -- Usage and validity
  duration                            as duration,
  duration_in_months                  as duration_in_months,
  max_redemptions                     as max_redemptions,
  times_redeemed                      as times_redeemed,
  valid                               as valid,
  
  -- Coupon details
  name                                as name,
  metadata_                           as metadata_,
  
  -- System fields
  livemode                            as livemode,
  raw_data                            as raw_data,
  
  -- Timestamps
  cast(created as timestamp)          as created,
  cast(redeem_by as timestamp)        as redeem_by,
  cast(received_at as timestamp)      as received_at,
  cast(updated_at as timestamp)       as updated_at

from {{ source('stripe','coupons') }} 