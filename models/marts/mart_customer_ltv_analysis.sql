{{ config(
    materialized='table',
    schema='marts'
) }}

with customer_transactions as (
    select 
        c.stripe_id as customer_id,
        c.created as customer_created,
        ch.created as transaction_date,
        ch.amount,
        ch.amount_refunded,
        ch.amount - ch.amount_refunded as net_amount,
        ch.currency,
        ch.paid,
        ch.status
    from {{ ref('stg_customers_view') }} c
    left join {{ ref('stg_charges_view') }} ch 
        on c.stripe_id = ch.customer
    where ch.paid = true and ch.status = 'succeeded'
),

customer_metrics as (
    select 
        customer_id,
        customer_created as first_seen,
        min(transaction_date) as first_purchase_date,
        max(transaction_date) as last_purchase_date,
        count(*) as total_transactions,
        count(distinct date(transaction_date)) as unique_purchase_days,
        sum(net_amount) as total_spent,
        avg(net_amount) as avg_order_value,
        stddev(net_amount) as order_value_stddev,
        
        -- Recency (days since last purchase)
        date_diff(current_date(), date(max(transaction_date)), day) as days_since_last_purchase,
        
        -- Customer lifespan
        date_diff(
            date(max(transaction_date)), 
            date(min(transaction_date)), 
            day
        ) + 1 as customer_lifespan_days,
        
        -- Purchase frequency
        safe_divide(
            count(*),
            date_diff(
                date(max(transaction_date)), 
                date(min(transaction_date)), 
                day
            ) + 1
        ) as avg_purchases_per_day,
        
        -- Currency preference
        array_agg(distinct currency ignore nulls) as currencies_used
        
    from customer_transactions
    where customer_id is not null
    group by customer_id, customer_created
)

select
    customer_id,
    first_seen,
    first_purchase_date,
    last_purchase_date,
    total_transactions,
    unique_purchase_days,
    total_spent,
    avg_order_value,
    order_value_stddev,
    days_since_last_purchase,
    customer_lifespan_days,
    avg_purchases_per_day,
    currencies_used,
    
    -- RFM Analysis components
    case 
        when days_since_last_purchase <= 30 then 'Recent'
        when days_since_last_purchase <= 90 then 'Moderate'
        when days_since_last_purchase <= 180 then 'At Risk'
        else 'Lost'
    end as recency_segment,
    
    case 
        when total_transactions >= 10 then 'High Frequency'
        when total_transactions >= 5 then 'Medium Frequency'
        when total_transactions >= 2 then 'Low Frequency'
        else 'One-time'
    end as frequency_segment,
    
    case 
        when total_spent >= 1000 then 'High Value'
        when total_spent >= 500 then 'Medium Value'
        when total_spent >= 100 then 'Low Value'
        else 'Minimal Value'
    end as monetary_segment,
    
    -- Customer lifetime value prediction (simple model)
    case 
        when customer_lifespan_days > 0 then
            safe_divide(total_spent, customer_lifespan_days) * 365
        else total_spent
    end as predicted_annual_value,
    
    -- Customer health score (0-100)
    least(100, greatest(0,
        (case when days_since_last_purchase <= 30 then 25 else 0 end) +
        (case when total_transactions >= 5 then 25 else total_transactions * 5 end) +
        (case when total_spent >= 500 then 25 else total_spent / 20 end) +
        (case when customer_lifespan_days >= 90 then 25 else customer_lifespan_days / 3.6 end)
    )) as customer_health_score,
    
    -- Customer type classification
    case 
        when total_transactions = 1 then 'One-time Customer'
        when avg_purchases_per_day >= 0.1 then 'Frequent Buyer'
        when customer_lifespan_days >= 365 then 'Long-term Customer'
        when total_spent >= 1000 then 'High-value Customer'
        else 'Regular Customer'
    end as customer_type

from customer_metrics
order by total_spent desc 