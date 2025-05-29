{{ config(
    materialized='table',
    schema='marts'
) }}

with payment_analysis as (
    select 
        date_trunc('month', created) as period_month,
        date(created) as payment_date,
        currency,
        
        -- Extract payment method type from payment_method_details
        case 
            when payment_method_details like '%card%' then 'Card'
            when payment_method_details like '%bank%' then 'Bank Transfer'
            when payment_method_details like '%wallet%' then 'Digital Wallet'
            when payment_method_details like '%ach%' then 'ACH'
            when payment_method_details like '%sepa%' then 'SEPA'
            else 'Other'
        end as payment_method_type,
        
        -- Payment outcome
        case 
            when paid = true and status = 'succeeded' then 'Success'
            when paid = false or status = 'failed' then 'Failed'
            when status = 'pending' then 'Pending'
            else 'Other'
        end as payment_outcome,
        
        -- Risk assessment
        case 
            when outcome_risk_level = 'high' then 'High Risk'
            when outcome_risk_level = 'medium' then 'Medium Risk'
            when outcome_risk_level = 'low' then 'Low Risk'
            else 'Unknown Risk'
        end as risk_category,
        
        -- Failure categorization
        case 
            when failure_code like '%card%' then 'Card Issue'
            when failure_code like '%insufficient%' then 'Insufficient Funds'
            when failure_code like '%expired%' then 'Expired Card'
            when failure_code like '%declined%' then 'Declined'
            when failure_code like '%fraud%' then 'Fraud Prevention'
            when failure_code is not null then 'Other Failure'
            else 'No Failure'
        end as failure_category,
        
        amount,
        amount_refunded,
        disputed,
        customer,
        outcome_network_status
        
    from {{ ref('stg_charges_view') }}
)

select
    period_month,
    currency,
    payment_method_type,
    risk_category,
    failure_category,
    
    -- Volume metrics
    count(*) as total_payments,
    count(distinct customer) as unique_customers,
    
    -- Success metrics
    count(case when payment_outcome = 'Success' then 1 end) as successful_payments,
    count(case when payment_outcome = 'Failed' then 1 end) as failed_payments,
    count(case when payment_outcome = 'Pending' then 1 end) as pending_payments,
    
    -- Success rates
    safe_divide(
        count(case when payment_outcome = 'Success' then 1 end),
        count(*)
    ) * 100 as success_rate_percent,
    
    safe_divide(
        count(case when payment_outcome = 'Failed' then 1 end),
        count(*)
    ) * 100 as failure_rate_percent,
    
    -- Revenue metrics
    sum(case when payment_outcome = 'Success' then amount else 0 end) as successful_revenue,
    sum(case when payment_outcome = 'Failed' then amount else 0 end) as failed_revenue,
    avg(case when payment_outcome = 'Success' then amount end) as avg_successful_amount,
    
    -- Risk analysis
    count(case when risk_category = 'High Risk' then 1 end) as high_risk_payments,
    safe_divide(
        count(case when risk_category = 'High Risk' and payment_outcome = 'Success' then 1 end),
        count(case when risk_category = 'High Risk' then 1 end)
    ) * 100 as high_risk_success_rate_percent,
    
    -- Dispute analysis
    count(case when disputed = true then 1 end) as disputed_payments,
    safe_divide(
        count(case when disputed = true then 1 end),
        count(case when payment_outcome = 'Success' then 1 end)
    ) * 100 as dispute_rate_percent,
    
    -- Refund analysis
    count(case when amount_refunded > 0 then 1 end) as payments_with_refunds,
    sum(amount_refunded) as total_refunded_amount,
    safe_divide(
        sum(amount_refunded),
        sum(case when payment_outcome = 'Success' then amount else 0 end)
    ) * 100 as refund_rate_percent,
    
    -- Network status analysis
    count(case when outcome_network_status = 'approved_by_network' then 1 end) as network_approved,
    count(case when outcome_network_status = 'declined_by_network' then 1 end) as network_declined,
    
    -- Performance benchmarks
    case 
        when safe_divide(
            count(case when payment_outcome = 'Success' then 1 end),
            count(*)
        ) >= 0.95 then 'Excellent'
        when safe_divide(
            count(case when payment_outcome = 'Success' then 1 end),
            count(*)
        ) >= 0.90 then 'Good'
        when safe_divide(
            count(case when payment_outcome = 'Success' then 1 end),
            count(*)
        ) >= 0.80 then 'Fair'
        else 'Poor'
    end as performance_rating,
    
    -- Month-over-month comparison
    lag(safe_divide(
        count(case when payment_outcome = 'Success' then 1 end),
        count(*)
    )) over (
        partition by currency, payment_method_type, risk_category, failure_category
        order by period_month
    ) as prev_month_success_rate,
    
    safe_divide(
        count(case when payment_outcome = 'Success' then 1 end),
        count(*)
    ) - lag(safe_divide(
        count(case when payment_outcome = 'Success' then 1 end),
        count(*)
    )) over (
        partition by currency, payment_method_type, risk_category, failure_category
        order by period_month
    ) as success_rate_change

from payment_analysis
group by 
    period_month,
    currency,
    payment_method_type,
    risk_category,
    failure_category
order by 
    period_month desc,
    total_payments desc 