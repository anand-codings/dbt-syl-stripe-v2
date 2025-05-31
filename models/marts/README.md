# Subscription MRR Marts

This directory contains mart models for analyzing subscription Monthly Recurring Revenue (MRR) and related metrics.

## Models

### `mart_subscription_mrr_unified` ⭐ **RECOMMENDED**

**Purpose**: Unified subscription metrics combining both monthly and annual analysis in a single table.

**Key Metrics**:
- Active subscribers by billing cycle (monthly, annual, total)
- Revenue by billing cycle (monthly, annual, total)
- Average Revenue Per User (ARPU) by billing cycle
- Monthly MRR and Annual Recurring Revenue calculations
- Time series data for both monthly and annual views

**Grain**: 
- Monthly periods: Last 24 months (one row per month)
- Annual periods: Last 5 years (one row per year)
- Distinguished by `period_type` column ('monthly' or 'annual')

**Use Cases**:
- Comprehensive revenue dashboards
- Cross-period trend analysis
- Unified reporting across time granularities
- Single source of truth for subscription metrics

### `mart_customer_churn_analysis` ⭐ **NEW**

**Purpose**: Analyzes customer churn patterns over the last 6 months, segmenting by churn type and quantifying revenue impact.

**Key Metrics**:
- Monthly churn counts and trends
- Revenue impact of churned customers (lifetime value)
- Churn segmentation (payment failures vs voluntary cancellations)
- Average customer value of churned customers
- Churn percentage breakdowns by reason

**Grain**: One row per month for the last 6 months, plus a TOTAL summary row

**Use Cases**:
- Churn trend analysis and forecasting
- Revenue impact assessment of customer loss
- Retention strategy development
- Payment failure prevention tracking
- Customer success program optimization

### `mart_monthly_subscription_mrr`

**Purpose**: Provides monthly subscription metrics and revenue breakdown for the last 12 months.

**Key Metrics**:
- Active subscribers by billing cycle (monthly, annual, total)
- Revenue by billing cycle (monthly, annual, total)
- Time series data suitable for dashboards and trend analysis

**Grain**: One row per month for the last 12 full months

**Use Cases**:
- Monthly revenue reporting
- Subscriber growth tracking
- Billing cycle performance analysis
- Time series dashboards

### `mart_annual_subscription_mrr`

**Purpose**: Provides annual subscription metrics and revenue breakdown for the last 5 years, including ARPU calculations.

**Key Metrics**:
- Active subscribers by billing cycle (monthly, annual, total)
- Revenue by billing cycle (monthly, annual, total)
- Average Revenue Per User (ARPU) by billing cycle
- Long-term trend analysis

**Grain**: One row per year for the last 5 full years

**Use Cases**:
- Annual revenue reporting
- Long-term trend analysis
- ARPU tracking and optimization
- Strategic planning and forecasting

## Data Sources

All models are built on top of the following staging models:
- `stg_charges_view`: Stripe charge data
- `stg_subscriptions`: Stripe subscription data
- `stg_plans`: Stripe plan configuration data

## Key Features

### Revenue Recognition
- Revenue is recognized in the month/year the charge was created
- Only paid charges are included in revenue calculations
- Amounts are converted from cents to dollars

### Subscriber Counting
- Subscribers are counted based on the billing periods their charges cover
- Monthly subscribers: counted for each month their subscription is active
- Annual subscribers: counted for each year their subscription is active
- Distinct customer counting prevents double-counting

### Billing Cycle Support
- Supports monthly and annual billing cycles
- Handles custom interval counts (e.g., 3-month, 2-year plans)
- Gracefully handles other interval types with proper labeling

### Churn Analysis
- Identifies churned customers based on subscription cancellation status
- Categorizes churn reasons (payment failures vs voluntary cancellations)
- Calculates customer lifetime value for revenue impact assessment
- Provides both absolute numbers and percentage breakdowns

## Usage Examples

### Churn Analysis
```sql
-- Monthly churn trends with revenue impact
SELECT 
  churn_month,
  churned_customers_count,
  total_churned_value,
  avg_customer_value,
  payment_failure_churn_pct,
  voluntary_churn_pct
FROM {{ ref('mart_customer_churn_analysis') }}
WHERE churn_month != 'TOTAL'
ORDER BY churn_month DESC;
```

```sql
-- Churn reason analysis
SELECT 
  churn_month,
  payment_failure_churns,
  voluntary_churns,
  churned_customers_count,
  ROUND(payment_failure_churns * 100.0 / churned_customers_count, 1) as payment_failure_rate,
  ROUND(voluntary_churns * 100.0 / churned_customers_count, 1) as voluntary_churn_rate
FROM {{ ref('mart_customer_churn_analysis') }}
WHERE churn_month != 'TOTAL'
  AND churned_customers_count > 0
ORDER BY churn_month DESC;
```

### Unified Analysis (Recommended)
```sql
-- Get both monthly and annual trends in one query
SELECT 
  period_start,
  period_type,
  total_active_subscribers,
  total_revenue,
  total_arpu,
  CASE 
    WHEN period_type = 'monthly' THEN monthly_mrr
    WHEN period_type = 'annual' THEN annual_recurring_revenue
  END as recurring_revenue
FROM {{ ref('mart_subscription_mrr_unified') }}
ORDER BY period_type, period_start;
```

### Monthly Trend Analysis
```sql
-- Focus on monthly trends only
SELECT 
  period_start as month,
  total_active_subscribers,
  monthly_mrr,
  LAG(monthly_mrr) OVER (ORDER BY period_start) as prev_month_mrr,
  (monthly_mrr - LAG(monthly_mrr) OVER (ORDER BY period_start)) / 
    LAG(monthly_mrr) OVER (ORDER BY period_start) * 100 as mrr_growth_pct
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE period_type = 'monthly'
ORDER BY period_start;
```

### Annual Comparison
```sql
-- Compare annual performance
SELECT 
  period_year,
  total_active_subscribers,
  annual_recurring_revenue,
  total_arpu,
  LAG(annual_recurring_revenue) OVER (ORDER BY period_year) as prev_year_arr,
  (annual_recurring_revenue - LAG(annual_recurring_revenue) OVER (ORDER BY period_year)) / 
    LAG(annual_recurring_revenue) OVER (ORDER BY period_year) * 100 as arr_growth_pct
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE period_type = 'annual'
ORDER BY period_year;
```

### Cross-Period Analysis
```sql
-- Compare monthly vs annual billing preferences
SELECT 
  period_year,
  period_type,
  monthly_active_subscribers,
  annual_active_subscribers,
  ROUND(annual_active_subscribers * 100.0 / 
    NULLIF(monthly_active_subscribers + annual_active_subscribers, 0), 2) as annual_subscriber_pct
FROM {{ ref('mart_subscription_mrr_unified') }}
WHERE period_start >= '2023-01-01'
ORDER BY period_year, period_type;
```

### Legacy Model Usage

#### Monthly MRR Analysis
```sql
SELECT 
  month,
  total_active_subscribers,
  total_revenue,
  monthly_revenue / NULLIF(monthly_active_subscribers, 0) as monthly_arpu
FROM {{ ref('mart_monthly_subscription_mrr') }}
WHERE month >= '2024-01-01'
ORDER BY month;
```

#### Annual Trend Analysis
```sql
SELECT 
  year,
  total_active_subscribers,
  total_revenue,
  total_arpu,
  LAG(total_revenue) OVER (ORDER BY year) as prev_year_revenue,
  (total_revenue - LAG(total_revenue) OVER (ORDER BY year)) / 
    LAG(total_revenue) OVER (ORDER BY year) * 100 as revenue_growth_pct
FROM {{ ref('mart_annual_subscription_mrr') }}
ORDER BY year;
```

## Model Recommendations

- **Use `mart_subscription_mrr_unified`** for most use cases as it provides the most comprehensive view
- **Use `mart_customer_churn_analysis`** for churn analysis, retention strategies, and revenue impact assessment
- **Use `mart_monthly_subscription_mrr`** only if you specifically need just monthly data with shorter history (12 months vs 24)
- **Use `mart_annual_subscription_mrr`** only if you specifically need just annual data

## Notes

- Data is filtered to exclude the current incomplete month/year
- All revenue figures are in USD (converted from cents)
- Models use BigQuery-specific functions (GENERATE_DATE_ARRAY, JSON_EXTRACT_SCALAR)
- Models are materialized as tables for performance
- The unified model provides 24 months of monthly data vs 12 months in the standalone monthly model
- Churn analysis focuses on the last 6 months to provide actionable insights while maintaining data quality 