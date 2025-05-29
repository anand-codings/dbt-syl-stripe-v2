{{ config(
    materialized='table',
    schema='marts'
) }}

select
    date_trunc('month', created) as period_month,
    currency,
    
    -- Transaction counts
    count(*) as total_charges,
    count(distinct customer) as unique_customers,
    
    -- Revenue metrics
    sum(amount) as gross_revenue,
    sum(amount_refunded) as total_refunds,
    sum(amount - amount_refunded) as net_revenue,
    
    -- Average metrics
    avg(amount) as avg_transaction_value,
    avg(amount - amount_refunded) as avg_net_transaction_value,
    
    -- Success metrics
    count(case when paid = true and status = 'succeeded' then 1 end) as successful_charges,
    count(case when paid = false or status != 'succeeded' then 1 end) as failed_charges,
    
    -- Refund metrics
    count(case when amount_refunded > 0 then 1 end) as charges_with_refunds,
    safe_divide(
        count(case when amount_refunded > 0 then 1 end),
        count(*)
    ) * 100 as refund_rate_percent,
    
    -- Growth calculations (month-over-month)
    lag(sum(amount - amount_refunded)) over (
        partition by currency 
        order by date_trunc('month', created)
    ) as prev_month_net_revenue,
    
    safe_divide(
        sum(amount - amount_refunded) - lag(sum(amount - amount_refunded)) over (
            partition by currency 
            order by date_trunc('month', created)
        ),
        lag(sum(amount - amount_refunded)) over (
            partition by currency 
            order by date_trunc('month', created)
        )
    ) * 100 as revenue_growth_percent

from {{ ref('stg_charges_view') }}
where paid = true 
    and status = 'succeeded'
group by 
    date_trunc('month', created),
    currency
order by 
    period_month desc,
    currency 