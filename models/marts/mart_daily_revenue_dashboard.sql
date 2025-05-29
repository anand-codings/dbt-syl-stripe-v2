{{ config(
    materialized='table',
    schema='marts'
) }}

select
    date(created) as revenue_date,
    currency,
    
    -- Daily transaction metrics
    count(*) as total_charges,
    count(distinct customer) as unique_customers,
    
    -- Revenue metrics
    sum(amount) as gross_revenue,
    sum(amount_refunded) as total_refunds,
    sum(amount - amount_refunded) as net_revenue,
    
    -- Success and failure rates
    count(case when paid = true and status = 'succeeded' then 1 end) as successful_charges,
    count(case when paid = false or status != 'succeeded' then 1 end) as failed_charges,
    
    safe_divide(
        count(case when paid = true and status = 'succeeded' then 1 end),
        count(*)
    ) * 100 as success_rate_percent,
    
    safe_divide(
        count(case when paid = false or status != 'succeeded' then 1 end),
        count(*)
    ) * 100 as failure_rate_percent,
    
    -- Payment method breakdown
    count(case when payment_method_details like '%card%' then 1 end) as card_payments,
    count(case when payment_method_details like '%bank%' then 1 end) as bank_payments,
    count(case when payment_method_details like '%wallet%' then 1 end) as wallet_payments,
    
    -- Risk analysis
    count(case when outcome_risk_level = 'high' then 1 end) as high_risk_charges,
    count(case when disputed = true then 1 end) as disputed_charges,
    
    -- Refund analysis
    count(case when amount_refunded > 0 then 1 end) as charges_with_refunds,
    safe_divide(
        count(case when amount_refunded > 0 then 1 end),
        count(*)
    ) * 100 as daily_refund_rate_percent,
    
    -- Average transaction values
    avg(amount) as avg_transaction_value,
    percentile_cont(amount, 0.5) over (partition by date(created), currency) as median_transaction_value,
    
    -- 7-day rolling averages
    avg(sum(amount - amount_refunded)) over (
        partition by currency
        order by date(created)
        rows between 6 preceding and current row
    ) as rolling_7day_net_revenue,
    
    avg(count(*)) over (
        partition by currency
        order by date(created)
        rows between 6 preceding and current row
    ) as rolling_7day_transaction_count

from {{ ref('stg_charges_view') }}
group by 
    date(created),
    currency
order by 
    revenue_date desc,
    currency 