# Marts Models Data Dictionary

## Overview
The marts models provide business-ready analytics tables for subscription revenue analysis, customer lifecycle tracking, and business intelligence. These models aggregate and transform raw data into actionable insights for stakeholders.

## Models

### `mart_subscription_mrr_unified` ⭐ **RECOMMENDED**
**Type**: Mart Table  
**Purpose**: Unified subscription metrics combining both monthly and annual analysis  
**Materialization**: Table  
**Grain**: Monthly periods (24 months) + Annual periods (5 years)  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `period_start` | DATE | Start date of the period (first day of month/year) | Primary Key component, Not Null |
| `period_type` | STRING | Type of period: 'monthly' or 'annual' | Primary Key component, Not Null, Values: ['monthly', 'annual'] |
| `period_year` | INT64 | Year component of the period | Not Null |
| `period_month` | INT64 | Month component (1-12) for monthly periods, NULL for annual | NULL for annual periods |
| `monthly_active_subscribers` | INT64 | Number of distinct customers with active monthly subscriptions | Not Null |
| `annual_active_subscribers` | INT64 | Number of distinct customers with active annual subscriptions | Not Null |
| `total_active_subscribers` | INT64 | Total number of distinct active subscribers (monthly + annual) | Not Null |
| `monthly_revenue` | FLOAT64 | Revenue from monthly subscription charges (in dollars) | Not Null |
| `annual_revenue` | FLOAT64 | Revenue from annual subscription charges (in dollars) | Not Null |
| `total_revenue` | FLOAT64 | Total subscription revenue (monthly + annual, in dollars) | Not Null |
| `monthly_arpu` | FLOAT64 | Average revenue per user for monthly subscribers (in dollars) | Not Null |
| `annual_arpu` | FLOAT64 | Average revenue per user for annual subscribers (in dollars) | Not Null |
| `total_arpu` | FLOAT64 | Average revenue per user across all subscribers (in dollars) | Not Null |
| `monthly_mrr` | FLOAT64 | Monthly Recurring Revenue - only populated for monthly periods | NULL for annual periods |
| `annual_recurring_revenue` | FLOAT64 | Annual Recurring Revenue - only populated for annual periods | NULL for monthly periods |

---

### `mart_customer_churn_analysis`
**Type**: Mart Table  
**Purpose**: Monthly customer churn and revenue impact analysis  
**Materialization**: Table  
**Grain**: One row per month (6 months) + TOTAL summary row  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `churn_month` | STRING | Month when customers churned (YYYY-MM format) or 'TOTAL' | Primary Key, Not Null |
| `churned_customers_count` | INT64 | Total number of customers who canceled in this month | Not Null |
| `total_churned_value` | STRING | Total lifetime value of churned customers (formatted as currency) | Not Null |
| `avg_customer_value` | STRING | Average lifetime spend per churned customer (formatted as currency) | Not Null |
| `payment_failure_churns` | INT64 | Number of customers who churned due to payment issues | Not Null |
| `voluntary_churns` | INT64 | Number of customers who actively requested cancellation | Not Null |
| `payment_failure_churn_pct` | FLOAT64 | Percentage of churns due to payment failures | Not Null |
| `voluntary_churn_pct` | FLOAT64 | Percentage of churns due to voluntary cancellations | Not Null |

---

### `mart_customer_lifecycle_status`
**Type**: Mart Table  
**Purpose**: Monthly customer lifecycle analysis tracking transitions through key stages  
**Materialization**: Table  
**Grain**: One row per month per lifecycle stage (36 months)  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `month_start` | DATE | Month start date (first day of the month) | Primary Key component, Not Null |
| `lifecycle_stage` | STRING | Customer lifecycle stage for this month | Primary Key component, Not Null, Values: ['New', 'Active', 'Reactivated', 'Churned'] |
| `customer_count` | INT64 | Number of distinct customers in this lifecycle stage | Not Null |

---

### `mart_customer_segmentation`
**Type**: Mart Table  
**Purpose**: Customer segmentation analysis grouping customers by multiple dimensions  
**Materialization**: Table  
**Grain**: One row per customer  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `customer_id` | STRING | Unique customer identifier | Primary Key, Not Null, Unique |
| `segment_plan_name` | STRING | Customer's latest subscription plan name or 'Unknown' | Not Null |
| `segment_billing_interval` | STRING | Customer's latest subscription billing interval or 'Unknown' | Not Null |
| `segment_current_subscription_status` | STRING | Current status of customer's latest subscription | Not Null |
| `first_paid_charge_date` | DATE | Date of customer's first paid charge (for tenure calculation) | Used for tenure segmentation |
| `segment_customer_tenure` | STRING | Customer tenure segment based on time since first paid charge | Not Null, Values: ['No Paid Charges', '0-5 Months Tenure', '6-11 Months Tenure', '12-23 Months Tenure', '24+ Months Tenure'] |
| `ltm_revenue` | FLOAT64 | Customer's Last Twelve Months revenue in dollars | Not Null |
| `segment_ltm_revenue_tier` | STRING | Customer's LTM revenue tier segment | Not Null, Values: ['No LTM Revenue', 'LTM Revenue < $100', 'LTM Revenue $100-$499', 'LTM Revenue $500-$999', 'LTM Revenue $1000+'] |
| `segment_geo_country` | STRING | Customer's country from latest invoice or 'Unknown' | Not Null |
| `segment_metadata_tier` | STRING | Customer tier from metadata (if available) | Optional |
| `segment_metadata_industry` | STRING | Industry segment from metadata (if available) | Optional |
| `customer_created_at` | TIMESTAMP | Timestamp when customer was created | Not Null |

---

### Additional Mart Models

#### `mart_monthly_subscription_mrr`
**Purpose**: Monthly subscription metrics for the last 12 months  
**Key Columns**: `month`, `monthly_active_subscribers`, `annual_active_subscribers`, `total_active_subscribers`, `monthly_revenue`, `annual_revenue`, `total_revenue`

#### `mart_annual_subscription_mrr`
**Purpose**: Annual subscription metrics for the last 5 years with ARPU  
**Key Columns**: `year`, subscriber counts, revenue amounts, ARPU calculations

#### Credit-Related Marts
- `mart_monthly_credit_allocation`: Monthly credit allocation analysis
- `mart_monthly_credit_usage`: Monthly credit usage patterns
- `mart_monthly_credit_balance`: Monthly credit balance tracking
- `mart_user_credit_trend_dashboard`: User credit trend analysis
- `mart_credit_churn_risk`: Credit-based churn risk analysis
- `mart_credit_allocation_vs_usage_by_plan`: Plan-based credit analysis
- `mart_credit_usage_by_tenure`: Tenure-based credit usage
- `mart_service_credit_efficiency`: Service efficiency analysis

## Data Sources
All models are built on top of staging models:
- `stg_charges_view`: Stripe charge data
- `stg_subscriptions`: Stripe subscription data
- `stg_plans`: Stripe plan configuration data
- Credit models: `credit_histories`, `credit_events`

## Key Features
- **Revenue Recognition**: Revenue recognized in the month/year the charge was created
- **Subscriber Counting**: Distinct customer counting prevents double-counting
- **Billing Cycle Support**: Supports monthly and annual billing cycles
- **Churn Analysis**: Categorizes churn reasons and calculates revenue impact
- **Customer Segmentation**: Multi-dimensional customer analysis

## Usage Recommendations
- **Use `mart_subscription_mrr_unified`** for most subscription analysis use cases
- **Use `mart_customer_churn_analysis`** for retention strategies and revenue impact
- **Use `mart_customer_segmentation`** for targeted marketing and customer success
- **Use `mart_customer_lifecycle_status`** for lifecycle stage analysis 