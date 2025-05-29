{{ config(
    materialized='table',
    schema='marts'
) }}

with product_subscriptions as (
    select 
        p.stripe_id as product_id,
        p.name as product_name,
        p.description as product_description,
        p.active as product_active,
        s.customer,
        s.status as subscription_status,
        s.quantity,
        s.created as subscription_created,
        s.canceled_at,
        s.trial_start,
        s.trial_end,
        date_trunc('month', s.created) as subscription_month
    from {{ ref('stg_products') }} p
    left join {{ ref('stg_subscriptions') }} s on p.stripe_id = s.product
),

product_charges as (
    select 
        ch.customer,
        ch.amount,
        ch.amount_refunded,
        ch.amount - ch.amount_refunded as net_amount,
        ch.currency,
        ch.created as charge_created,
        ch.paid,
        ch.status as charge_status,
        date_trunc('month', ch.created) as charge_month,
        -- Try to link charges to products via invoices/subscriptions
        ch.invoice
    from {{ ref('stg_charges_view') }} ch
    where ch.paid = true and ch.status = 'succeeded'
)

select
    product_id,
    product_name,
    product_description,
    product_active,
    subscription_month as period_month,
    
    -- Subscription metrics
    count(distinct case when subscription_status is not null then customer end) as unique_subscribers,
    count(case when subscription_status is not null then 1 end) as total_subscriptions,
    count(case when subscription_status = 'active' then 1 end) as active_subscriptions,
    count(case when subscription_status = 'canceled' then 1 end) as canceled_subscriptions,
    count(case when subscription_status = 'trialing' then 1 end) as trial_subscriptions,
    
    -- Trial conversion analysis
    count(case when trial_start is not null then 1 end) as subscriptions_with_trial,
    count(case when trial_start is not null and subscription_status = 'active' then 1 end) as trial_conversions,
    safe_divide(
        count(case when trial_start is not null and subscription_status = 'active' then 1 end),
        count(case when trial_start is not null then 1 end)
    ) * 100 as trial_conversion_rate_percent,
    
    -- Quantity metrics
    sum(case when subscription_status = 'active' then quantity else 0 end) as active_quantity,
    sum(quantity) as total_quantity,
    avg(quantity) as avg_quantity_per_subscription,
    
    -- Churn analysis
    safe_divide(
        count(case when subscription_status = 'canceled' then 1 end),
        count(case when subscription_status is not null then 1 end)
    ) * 100 as subscription_churn_rate_percent,
    
    -- Customer acquisition
    count(distinct case 
        when subscription_created >= date_sub(current_date(), interval 30 day) 
        then customer 
    end) as new_customers_last_30_days,
    
    count(distinct case 
        when subscription_created >= date_sub(current_date(), interval 90 day) 
        then customer 
    end) as new_customers_last_90_days,
    
    -- Growth metrics
    lag(count(case when subscription_status = 'active' then 1 end)) over (
        partition by product_id 
        order by subscription_month
    ) as prev_month_active_subscriptions,
    
    safe_divide(
        count(case when subscription_status = 'active' then 1 end) - 
        lag(count(case when subscription_status = 'active' then 1 end)) over (
            partition by product_id 
            order by subscription_month
        ),
        lag(count(case when subscription_status = 'active' then 1 end)) over (
            partition by product_id 
            order by subscription_month
        )
    ) * 100 as month_over_month_growth_percent,
    
    -- Product health score (0-100)
    least(100, greatest(0,
        -- Active subscription weight (40%)
        (safe_divide(
            count(case when subscription_status = 'active' then 1 end),
            count(case when subscription_status is not null then 1 end)
        ) * 40) +
        -- Trial conversion weight (30%)
        (safe_divide(
            count(case when trial_start is not null and subscription_status = 'active' then 1 end),
            count(case when trial_start is not null then 1 end)
        ) * 30) +
        -- Growth weight (20%)
        (case when 
            safe_divide(
                count(case when subscription_status = 'active' then 1 end) - 
                lag(count(case when subscription_status = 'active' then 1 end)) over (
                    partition by product_id 
                    order by subscription_month
                ),
                lag(count(case when subscription_status = 'active' then 1 end)) over (
                    partition by product_id 
                    order by subscription_month
                )
            ) > 0 then 20 else 0 end) +
        -- Customer acquisition weight (10%)
        (case when count(distinct case 
            when subscription_created >= date_sub(current_date(), interval 30 day) 
            then customer 
        end) > 0 then 10 else 0 end)
    )) as product_health_score,
    
    -- Product lifecycle stage
    case 
        when count(case when subscription_status = 'active' then 1 end) = 0 then 'Discontinued'
        when subscription_month >= date_sub(current_date(), interval 3 month) then 'New'
        when count(case when subscription_status = 'active' then 1 end) >= 100 then 'Mature'
        when safe_divide(
            count(case when subscription_status = 'active' then 1 end) - 
            lag(count(case when subscription_status = 'active' then 1 end)) over (
                partition by product_id 
                order by subscription_month
            ),
            lag(count(case when subscription_status = 'active' then 1 end)) over (
                partition by product_id 
                order by subscription_month
            )
        ) > 0.1 then 'Growing'
        else 'Stable'
    end as product_lifecycle_stage

from product_subscriptions
where subscription_month is not null
group by 
    product_id,
    product_name,
    product_description,
    product_active,
    subscription_month
order by 
    period_month desc,
    active_subscriptions desc 