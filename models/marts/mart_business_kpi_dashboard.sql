{{ config(
    materialized='table',
    schema='marts'
) }}

with monthly_revenue as (
    select 
        period_month,
        sum(net_revenue) as total_net_revenue,
        sum(gross_revenue) as total_gross_revenue,
        sum(total_refunds) as total_refunds,
        sum(unique_customers) as total_unique_customers,
        sum(total_charges) as total_charges,
        avg(avg_transaction_value) as avg_transaction_value
    from {{ ref('mart_monthly_revenue') }}
    group by period_month
),

subscription_metrics as (
    select 
        period_month,
        sum(case when status_category = 'Active' then subscription_count else 0 end) as active_subscriptions,
        sum(case when status_category = 'Canceled' then subscription_count else 0 end) as canceled_subscriptions,
        sum(case when status_category = 'Trial' then subscription_count else 0 end) as trial_subscriptions,
        avg(trial_conversion_rate_percent) as avg_trial_conversion_rate,
        avg(cancellation_rate_percent) as avg_cancellation_rate
    from {{ ref('mart_subscription_metrics_enhanced') }}
    group by period_month
),

customer_health as (
    select 
        date_trunc('month', first_purchase_date) as period_month,
        count(*) as new_customers,
        avg(customer_health_score) as avg_customer_health_score,
        count(case when segment_priority = 'High Value' then 1 end) as high_value_customers,
        count(case when segment_priority = 'At Risk' then 1 end) as at_risk_customers,
        count(case when segment_priority = 'Critical' then 1 end) as critical_customers
    from {{ ref('mart_customer_segmentation') }}
    group by date_trunc('month', first_purchase_date)
),

payment_performance as (
    select 
        period_month,
        avg(success_rate_percent) as avg_payment_success_rate,
        sum(total_payments) as total_payment_attempts,
        sum(failed_payments) as total_failed_payments,
        avg(dispute_rate_percent) as avg_dispute_rate,
        sum(disputed_payments) as total_disputes
    from {{ ref('mart_payment_success_analysis') }}
    group by period_month
),

refund_summary as (
    select 
        period_month,
        sum(total_refunds) as total_refunds,
        sum(total_refund_amount) as total_refund_amount,
        avg(refund_rate_by_amount_percent) as avg_refund_rate,
        count(case when refund_risk_level = 'High Risk' then 1 end) as high_risk_refund_periods
    from {{ ref('mart_refund_analysis_enhanced') }}
    group by period_month
)

select
    coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month) as period_month,
    
    -- Revenue KPIs
    mr.total_net_revenue,
    mr.total_gross_revenue,
    mr.total_refunds as revenue_refunds,
    mr.total_unique_customers,
    mr.total_charges,
    mr.avg_transaction_value,
    
    -- Revenue growth
    lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month)) as prev_month_revenue,
    safe_divide(
        mr.total_net_revenue - lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month)),
        lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month))
    ) * 100 as revenue_growth_percent,
    
    -- Subscription KPIs
    sm.active_subscriptions,
    sm.canceled_subscriptions,
    sm.trial_subscriptions,
    sm.avg_trial_conversion_rate,
    sm.avg_cancellation_rate,
    
    -- Subscription health
    safe_divide(sm.active_subscriptions, sm.active_subscriptions + sm.canceled_subscriptions) * 100 as subscription_retention_rate,
    
    -- Customer KPIs
    ch.new_customers,
    ch.avg_customer_health_score,
    ch.high_value_customers,
    ch.at_risk_customers,
    ch.critical_customers,
    
    -- Customer health ratios
    safe_divide(ch.high_value_customers, ch.new_customers) * 100 as high_value_customer_rate,
    safe_divide(ch.at_risk_customers + ch.critical_customers, ch.new_customers) * 100 as customer_risk_rate,
    
    -- Payment KPIs
    pp.avg_payment_success_rate,
    pp.total_payment_attempts,
    pp.total_failed_payments,
    pp.avg_dispute_rate,
    pp.total_disputes,
    
    -- Refund KPIs
    rs.total_refunds as refund_count,
    rs.total_refund_amount,
    rs.avg_refund_rate,
    rs.high_risk_refund_periods,
    
    -- Operational efficiency metrics
    safe_divide(mr.total_net_revenue, pp.total_payment_attempts) as revenue_per_payment_attempt,
    safe_divide(mr.total_net_revenue, mr.total_unique_customers) as revenue_per_customer,
    safe_divide(sm.active_subscriptions, ch.new_customers) as subscription_conversion_rate,
    
    -- Overall business health score (0-100)
    least(100, greatest(0,
        -- Revenue growth weight (25%)
        (case when safe_divide(
            mr.total_net_revenue - lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month)),
            lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month))
        ) > 0.05 then 25 else 0 end) +
        
        -- Payment success weight (25%)
        (case when pp.avg_payment_success_rate >= 95 then 25
              when pp.avg_payment_success_rate >= 90 then 20
              when pp.avg_payment_success_rate >= 85 then 15
              else 0 end) +
        
        -- Customer health weight (25%)
        (case when ch.avg_customer_health_score >= 75 then 25
              when ch.avg_customer_health_score >= 60 then 20
              when ch.avg_customer_health_score >= 45 then 15
              else 0 end) +
        
        -- Subscription health weight (25%)
        (case when sm.avg_cancellation_rate <= 5 then 25
              when sm.avg_cancellation_rate <= 10 then 20
              when sm.avg_cancellation_rate <= 15 then 15
              else 0 end)
    )) as business_health_score,
    
    -- Business health category
    case 
        when least(100, greatest(0,
            (case when safe_divide(
                mr.total_net_revenue - lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month)),
                lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month))
            ) > 0.05 then 25 else 0 end) +
            (case when pp.avg_payment_success_rate >= 95 then 25 when pp.avg_payment_success_rate >= 90 then 20 when pp.avg_payment_success_rate >= 85 then 15 else 0 end) +
            (case when ch.avg_customer_health_score >= 75 then 25 when ch.avg_customer_health_score >= 60 then 20 when ch.avg_customer_health_score >= 45 then 15 else 0 end) +
            (case when sm.avg_cancellation_rate <= 5 then 25 when sm.avg_cancellation_rate <= 10 then 20 when sm.avg_cancellation_rate <= 15 then 15 else 0 end)
        )) >= 80 then 'Excellent'
        when least(100, greatest(0,
            (case when safe_divide(
                mr.total_net_revenue - lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month)),
                lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month))
            ) > 0.05 then 25 else 0 end) +
            (case when pp.avg_payment_success_rate >= 95 then 25 when pp.avg_payment_success_rate >= 90 then 20 when pp.avg_payment_success_rate >= 85 then 15 else 0 end) +
            (case when ch.avg_customer_health_score >= 75 then 25 when ch.avg_customer_health_score >= 60 then 20 when ch.avg_customer_health_score >= 45 then 15 else 0 end) +
            (case when sm.avg_cancellation_rate <= 5 then 25 when sm.avg_cancellation_rate <= 10 then 20 when sm.avg_cancellation_rate <= 15 then 15 else 0 end)
        )) >= 60 then 'Good'
        when least(100, greatest(0,
            (case when safe_divide(
                mr.total_net_revenue - lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month)),
                lag(mr.total_net_revenue) over (order by coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month, rs.period_month))
            ) > 0.05 then 25 else 0 end) +
            (case when pp.avg_payment_success_rate >= 95 then 25 when pp.avg_payment_success_rate >= 90 then 20 when pp.avg_payment_success_rate >= 85 then 15 else 0 end) +
            (case when ch.avg_customer_health_score >= 75 then 25 when ch.avg_customer_health_score >= 60 then 20 when ch.avg_customer_health_score >= 45 then 15 else 0 end) +
            (case when sm.avg_cancellation_rate <= 5 then 25 when sm.avg_cancellation_rate <= 10 then 20 when sm.avg_cancellation_rate <= 15 then 15 else 0 end)
        )) >= 40 then 'Fair'
        else 'Poor'
    end as business_health_category

from monthly_revenue mr
full outer join subscription_metrics sm on mr.period_month = sm.period_month
full outer join customer_health ch on coalesce(mr.period_month, sm.period_month) = ch.period_month
full outer join payment_performance pp on coalesce(mr.period_month, sm.period_month, ch.period_month) = pp.period_month
full outer join refund_summary rs on coalesce(mr.period_month, sm.period_month, ch.period_month, pp.period_month) = rs.period_month
order by period_month desc 