{{ config(
    materialized='table',
    schema='marts'
) }}

with customer_rfm_base as (
    select 
        customer_id,
        days_since_last_purchase as recency,
        total_transactions as frequency,
        total_spent as monetary,
        customer_type,
        first_purchase_date,
        customer_health_score
    from {{ ref('mart_customer_ltv_analysis') }}
),

rfm_quartiles as (
    select 
        *,
        -- Recency quartiles (lower is better for recency)
        ntile(4) over (order by recency desc) as recency_score,
        -- Frequency quartiles (higher is better)
        ntile(4) over (order by frequency asc) as frequency_score,
        -- Monetary quartiles (higher is better)
        ntile(4) over (order by monetary asc) as monetary_score
    from customer_rfm_base
),

rfm_segments as (
    select 
        *,
        concat(
            cast(recency_score as string),
            cast(frequency_score as string), 
            cast(monetary_score as string)
        ) as rfm_score,
        
        -- RFM segment classification
        case 
            when recency_score >= 3 and frequency_score >= 3 and monetary_score >= 3 then 'Champions'
            when recency_score >= 2 and frequency_score >= 3 and monetary_score >= 3 then 'Loyal Customers'
            when recency_score >= 3 and frequency_score <= 2 and monetary_score >= 3 then 'Potential Loyalists'
            when recency_score >= 3 and frequency_score >= 2 and monetary_score <= 2 then 'New Customers'
            when recency_score >= 2 and frequency_score <= 2 and monetary_score <= 2 then 'Promising'
            when recency_score <= 2 and frequency_score >= 3 and monetary_score >= 3 then 'Need Attention'
            when recency_score <= 2 and frequency_score >= 2 and monetary_score >= 2 then 'About to Sleep'
            when recency_score <= 2 and frequency_score <= 2 and monetary_score >= 3 then 'At Risk'
            when recency_score <= 1 and frequency_score >= 2 and monetary_score <= 2 then 'Cannot Lose Them'
            when recency_score >= 2 and frequency_score <= 1 and monetary_score <= 2 then 'Hibernating'
            else 'Lost'
        end as rfm_segment
    from rfm_quartiles
)

select
    customer_id,
    first_purchase_date,
    date_trunc('month', first_purchase_date) as acquisition_cohort,
    
    -- RFM Metrics
    recency,
    frequency,
    monetary,
    recency_score,
    frequency_score,
    monetary_score,
    rfm_score,
    rfm_segment,
    
    -- Customer classification
    customer_type,
    customer_health_score,
    
    -- Segment characteristics
    case 
        when rfm_segment in ('Champions', 'Loyal Customers') then 'High Value'
        when rfm_segment in ('Potential Loyalists', 'New Customers', 'Promising') then 'Growth Opportunity'
        when rfm_segment in ('Need Attention', 'About to Sleep', 'At Risk') then 'At Risk'
        when rfm_segment in ('Cannot Lose Them') then 'Critical'
        else 'Low Engagement'
    end as segment_priority,
    
    -- Recommended actions
    case 
        when rfm_segment = 'Champions' then 'Reward and upsell'
        when rfm_segment = 'Loyal Customers' then 'Offer premium products'
        when rfm_segment = 'Potential Loyalists' then 'Increase purchase frequency'
        when rfm_segment = 'New Customers' then 'Provide onboarding support'
        when rfm_segment = 'Promising' then 'Offer membership or loyalty program'
        when rfm_segment = 'Need Attention' then 'Make limited time offers'
        when rfm_segment = 'About to Sleep' then 'Share valuable resources'
        when rfm_segment = 'At Risk' then 'Send personalized reactivation campaigns'
        when rfm_segment = 'Cannot Lose Them' then 'Win them back via renewals or newer products'
        when rfm_segment = 'Hibernating' then 'Offer other product categories'
        else 'Recreate brand value'
    end as recommended_action,
    
    -- Cohort analysis
    date_diff(current_date(), date(first_purchase_date), month) as months_since_acquisition,
    
    case 
        when date_diff(current_date(), date(first_purchase_date), month) <= 3 then 'New (0-3 months)'
        when date_diff(current_date(), date(first_purchase_date), month) <= 12 then 'Established (4-12 months)'
        when date_diff(current_date(), date(first_purchase_date), month) <= 24 then 'Mature (1-2 years)'
        else 'Veteran (2+ years)'
    end as customer_tenure_segment

from rfm_segments
order by monetary desc, frequency desc, recency asc 