{{ config(
    materialized='view',
    schema='staging'
) }}

select
  -- Primary identifiers
  cast(id as string)                  as id,
  cast(stripe_id as string)           as stripe_id,
  cast(object as string)              as object,
  
  -- Discount configuration
  cast(amount_off as int64)           as amount_off,
  cast(percent_off as float64)        as percent_off,
  cast(currency as string)            as currency,
  
  -- Usage and validity
  cast(duration as string)            as duration,
  cast(duration_in_months as int64)   as duration_in_months,
  cast(max_redemptions as int64)      as max_redemptions,
  cast(times_redeemed as int64)       as times_redeemed,
  cast(valid as boolean)              as valid,
  
  -- Coupon details
  cast(name as string)                as name,
  cast(metadata_ as string)           as metadata_,
  
  -- System fields
  cast(livemode as boolean)           as livemode,
  cast(raw_data as string)            as raw_data,
  
  -- Timestamps
  cast(created as timestamp)          as created,
  cast(redeem_by as timestamp)        as redeem_by,
  cast(received_at as timestamp)      as received_at,
  cast(updated_at as timestamp)       as updated_at

from {{ source('stripe','coupons') }} 