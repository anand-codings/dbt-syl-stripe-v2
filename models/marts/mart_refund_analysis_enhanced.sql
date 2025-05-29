{{ config(
    materialized='table',
    schema='marts'
) }}

with refund_base as (
    select 
        r.stripe_id as refund_id,
        r.charge as charge_id,
        r.amount as refund_amount,
        r.currency,
        r.reason,
        r.status as refund_status,
        r.created as refund_created,
        date_trunc('month', r.created) as refund_month,
        
        -- Link to charge information
        ch.amount as original_charge_amount,
        ch.customer,
        ch.created as charge_created,
        ch.payment_method_details,
        
        -- Calculate refund timing
        date_diff(date(r.created), date(ch.created), day) as days_to_refund,
        
        -- Refund type
        case 
            when r.amount = ch.amount then 'Full Refund'
            when r.amount < ch.amount then 'Partial Refund'
            else 'Over Refund'
        end as refund_type,
        
        -- Refund reason categorization
        case 
            when r.reason = 'duplicate' then 'Duplicate Charge'
            when r.reason = 'fraudulent' then 'Fraudulent'
            when r.reason = 'requested_by_customer' then 'Customer Request'
            when r.reason = 'expired_uncaptured_charge' then 'Expired Charge'
            else 'Other'
        end as refund_reason_category
        
    from {{ ref('stg_refunds') }} r
    left join {{ ref('stg_charges_view') }} ch on r.charge = ch.stripe_id
),

customer_refund_patterns as (
    select 
        customer,
        count(*) as total_refunds,
        sum(refund_amount) as total_refund_amount,
        avg(refund_amount) as avg_refund_amount,
        min(refund_created) as first_refund_date,
        max(refund_created) as last_refund_date,
        count(distinct refund_reason_category) as unique_refund_reasons
    from refund_base
    where customer is not null
    group by customer
)

select
    refund_month as period_month,
    currency,
    refund_reason_category,
    refund_type,
    
    -- Volume metrics
    count(*) as total_refunds,
    count(distinct customer) as unique_customers_with_refunds,
    count(distinct charge_id) as unique_charges_refunded,
    
    -- Amount metrics
    sum(refund_amount) as total_refund_amount,
    sum(original_charge_amount) as total_original_charge_amount,
    avg(refund_amount) as avg_refund_amount,
    avg(original_charge_amount) as avg_original_charge_amount,
    
    -- Refund rates
    safe_divide(sum(refund_amount), sum(original_charge_amount)) * 100 as refund_rate_by_amount_percent,
    
    -- Timing analysis
    avg(days_to_refund) as avg_days_to_refund,
    percentile_cont(days_to_refund, 0.5) over (
        partition by refund_month, currency, refund_reason_category, refund_type
    ) as median_days_to_refund,
    
    count(case when days_to_refund <= 1 then 1 end) as same_day_refunds,
    count(case when days_to_refund <= 7 then 1 end) as refunds_within_week,
    count(case when days_to_refund <= 30 then 1 end) as refunds_within_month,
    
    -- Refund type distribution
    count(case when refund_type = 'Full Refund' then 1 end) as full_refunds,
    count(case when refund_type = 'Partial Refund' then 1 end) as partial_refunds,
    
    safe_divide(
        count(case when refund_type = 'Full Refund' then 1 end),
        count(*)
    ) * 100 as full_refund_rate_percent,
    
    -- Payment method analysis
    count(case when payment_method_details like '%card%' then 1 end) as card_refunds,
    count(case when payment_method_details like '%bank%' then 1 end) as bank_refunds,
    count(case when payment_method_details like '%wallet%' then 1 end) as wallet_refunds,
    
    -- Customer behavior analysis
    avg(case when customer is not null then crp.total_refunds end) as avg_customer_total_refunds,
    count(case when crp.total_refunds = 1 then 1 end) as first_time_refund_customers,
    count(case when crp.total_refunds >= 3 then 1 end) as frequent_refund_customers,
    
    -- Seasonal patterns
    extract(dayofweek from refund_created) as refund_day_of_week,
    extract(hour from refund_created) as refund_hour,
    
    -- Growth analysis
    lag(count(*)) over (
        partition by currency, refund_reason_category, refund_type
        order by refund_month
    ) as prev_month_refunds,
    
    safe_divide(
        count(*) - lag(count(*)) over (
            partition by currency, refund_reason_category, refund_type
            order by refund_month
        ),
        lag(count(*)) over (
            partition by currency, refund_reason_category, refund_type
            order by refund_month
        )
    ) * 100 as month_over_month_growth_percent,
    
    -- Risk indicators
    case 
        when safe_divide(sum(refund_amount), sum(original_charge_amount)) > 0.1 then 'High Risk'
        when safe_divide(sum(refund_amount), sum(original_charge_amount)) > 0.05 then 'Medium Risk'
        else 'Low Risk'
    end as refund_risk_level,
    
    -- Business impact
    case 
        when refund_reason_category = 'Fraudulent' then 'Security Issue'
        when refund_reason_category = 'Customer Request' then 'Service Issue'
        when refund_reason_category = 'Duplicate Charge' then 'Process Issue'
        else 'Technical Issue'
    end as business_impact_category

from refund_base rb
left join customer_refund_patterns crp on rb.customer = crp.customer
group by 
    refund_month,
    currency,
    refund_reason_category,
    refund_type,
    extract(dayofweek from refund_created),
    extract(hour from refund_created)
order by 
    period_month desc,
    total_refund_amount desc 