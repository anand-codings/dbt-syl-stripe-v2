{{ config(
    materialized='table',
    schema='marts'
) }}

with subscription_base as (
    select 
        s.*,
        p.name as product_name,
        c.created as customer_created,
        
        -- Calculate subscription age
        date_diff(current_date(), date(s.created), day) as subscription_age_days,
        
        -- Trial information
        case when s.trial_start is not null then true else false end as had_trial,
        case when s.trial_start is not null and s.trial_end is not null 
             then date_diff(date(s.trial_end), date(s.trial_start), day) 
             else null end as trial_duration_days,
        
        -- Billing cycle length
        date_diff(date(s.current_period_end), date(s.current_period_start), day) as billing_cycle_days,
        
        -- Cancellation analysis
        case when s.canceled_at is not null 
             then date_diff(date(s.canceled_at), date(s.created), day)
             else null end as days_to_cancellation,
             
        -- Status categorization
        case 
            when s.status = 'active' then 'Active'
            when s.status = 'trialing' then 'Trial'
            when s.status = 'canceled' then 'Canceled'
            when s.status = 'past_due' then 'Past Due'
            when s.status = 'unpaid' then 'Unpaid'
            else 'Other'
        end as status_category
        
    from {{ ref('stg_subscriptions') }} s
    left join {{ ref('stg_products') }} p on s.product = p.stripe_id
    left join {{ ref('stg_customers_view') }} c on s.customer = c.stripe_id
)

select
    date_trunc('month', created) as period_month,
    product_name,
    status_category,
    
    -- Subscription counts
    count(*) as subscription_count,
    count(distinct customer) as unique_subscribers,
    
    -- Trial analysis
    count(case when had_trial then 1 end) as trial_subscriptions,
    count(case when had_trial and status_category = 'Active' then 1 end) as trial_conversions,
    safe_divide(
        count(case when had_trial and status_category = 'Active' then 1 end),
        count(case when had_trial then 1 end)
    ) * 100 as trial_conversion_rate_percent,
    
    avg(case when had_trial then trial_duration_days end) as avg_trial_duration_days,
    
    -- Cancellation analysis
    count(case when status_category = 'Canceled' then 1 end) as canceled_subscriptions,
    safe_divide(
        count(case when status_category = 'Canceled' then 1 end),
        count(*)
    ) * 100 as cancellation_rate_percent,
    
    avg(case when status_category = 'Canceled' then days_to_cancellation end) as avg_days_to_cancellation,
    
    -- Billing cycle analysis
    avg(billing_cycle_days) as avg_billing_cycle_days,
    count(case when billing_cycle_days <= 31 then 1 end) as monthly_subscriptions,
    count(case when billing_cycle_days between 85 and 95 then 1 end) as quarterly_subscriptions,
    count(case when billing_cycle_days >= 360 then 1 end) as annual_subscriptions,
    
    -- Subscription health
    count(case when status_category = 'Active' then 1 end) as active_subscriptions,
    count(case when status_category = 'Past Due' then 1 end) as past_due_subscriptions,
    count(case when status_category = 'Unpaid' then 1 end) as unpaid_subscriptions,
    
    safe_divide(
        count(case when status_category in ('Past Due', 'Unpaid') then 1 end),
        count(case when status_category = 'Active' then 1 end)
    ) * 100 as at_risk_rate_percent,
    
    -- Quantity metrics
    sum(quantity) as total_quantity,
    avg(quantity) as avg_quantity_per_subscription,
    
    -- Age analysis
    avg(subscription_age_days) as avg_subscription_age_days,
    count(case when subscription_age_days <= 30 then 1 end) as new_subscriptions_last_30_days,
    count(case when subscription_age_days >= 365 then 1 end) as subscriptions_over_1_year,
    
    -- Growth metrics
    lag(count(*)) over (
        partition by product_name, status_category 
        order by date_trunc('month', created)
    ) as prev_month_count,
    
    safe_divide(
        count(*) - lag(count(*)) over (
            partition by product_name, status_category 
            order by date_trunc('month', created)
        ),
        lag(count(*)) over (
            partition by product_name, status_category 
            order by date_trunc('month', created)
        )
    ) * 100 as month_over_month_growth_percent

from subscription_base
group by 
    date_trunc('month', created),
    product_name,
    status_category
order by 
    period_month desc,
    product_name,
    status_category 