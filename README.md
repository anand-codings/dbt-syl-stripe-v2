# Stripe to BigQuery dbt Project

This dbt project extracts Stripe data from PostgreSQL views/tables and transforms it for analytics in BigQuery. The project follows a staging-to-marts pattern with staging models for data cleaning and mart models for business aggregations.

## Project Structure

```
├── dbt_project.yml          # Main dbt configuration
├── profiles.yml             # Connection profiles (copy to ~/.dbt/)
├── requirements.txt         # Python dependencies
├── models/
│   ├── src/
│   │   └── stripe_sources.yml    # Source definitions
│   ├── staging/               # Staging models (clean and cast)
│   │   ├── stg_charges_view.sql
│   │   ├── stg_coupons.sql
│   │   ├── stg_customers_view.sql
│   │   ├── stg_invoices_view.sql
│   │   ├── stg_payment_intents_view.sql
│   │   ├── stg_plans.sql
│   │   ├── stg_prices.sql
│   │   ├── stg_products.sql
│   │   ├── stg_refunds.sql
│   │   ├── stg_subscriptions.sql
│   │   └── schema.yml         # Tests and documentation
│   └── marts/                 # Business aggregation models
│       ├── mart_charges_summary.sql
│       ├── mart_revenue_by_month.sql
│       ├── mart_mrr.sql
│       ├── mart_arr.sql
│       ├── mart_churn_rate.sql
│       ├── mart_customer_lifetime_value.sql
│       ├── mart_coupon_usage.sql
│       ├── mart_refund_rate.sql
│       ├── mart_failed_payments.sql
│       ├── mart_cohort_analysis.sql
│       ├── mart_subscription_status.sql
│       ├── mart_monthly_revenue.sql
│       ├── mart_daily_revenue_dashboard.sql
│       ├── mart_customer_ltv_analysis.sql
│       ├── mart_customer_segmentation.sql
│       ├── mart_subscription_metrics_enhanced.sql
│       ├── mart_product_revenue_analysis.sql
│       ├── mart_payment_success_analysis.sql
│       ├── mart_refund_analysis_enhanced.sql
│       ├── mart_business_kpi_dashboard.sql
│       └── schema.yml         # Tests and documentation
└── analysis/                  # Ad-hoc analysis queries
```

## Setup Instructions

### 1. Prerequisites

- Python 3.8+
- Access to your PostgreSQL Stripe database
- Google Cloud Platform project with BigQuery enabled
- Service account with BigQuery permissions

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure Profiles

Copy `profiles.yml` to `~/.dbt/profiles.yml` and update the following:

```yaml
stripe_bigquery:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: service-account
      project: your-gcp-project-id        # ← Update this
      dataset: stripe_models
      threads: 4
      keyfile: /path/to/service-account.json  # ← Update this
      timeout_seconds: 300
      location: US
```

### 4. Update Source Configuration

Edit `models/src/stripe_sources.yml` and update:
- `database: your_postgres_database` ← Your PostgreSQL database name
- Add/remove tables as needed for your Stripe setup

### 5. Test Connection

```bash
dbt debug
```

### 6. Run the Project

```bash
# Run staging models
dbt run --select staging

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## Model Descriptions

### Staging Models (`models/staging/`)

These models clean and standardize data from PostgreSQL Stripe sources:

- **stg_charges_view**: Cleaned charge/payment data with proper typing
- **stg_customers_view**: Customer information and metadata
- **stg_invoices_view**: Invoice details and status tracking
- **stg_payment_intents_view**: Payment intent lifecycle data
- **stg_subscriptions**: Subscription management data
- **stg_products**: Product catalog information
- **stg_prices**: Pricing configuration data
- **stg_plans**: Legacy subscription plans
- **stg_coupons**: Discount and promotion data
- **stg_refunds**: Refund transaction details

### Mart Models (`models/marts/`)

Business-ready aggregation models organized by functional area:

#### Revenue & Financial Analytics
- **mart_charges_summary**: Monthly aggregated charge metrics
- **mart_revenue_by_month**: Monthly revenue and unique paying customers
- **mart_monthly_revenue**: Comprehensive monthly revenue analysis with growth metrics, refund tracking, and currency breakdown
- **mart_daily_revenue_dashboard**: Daily revenue trends with payment method analysis, success rates, and 7-day rolling averages
- **mart_mrr**: Monthly Recurring Revenue with new/churned MRR breakdown
- **mart_arr**: Annual Recurring Revenue with growth metrics and composition analysis

#### Customer Analytics & Segmentation
- **mart_customer_lifetime_value**: CLV predictions and customer segmentation
- **mart_customer_ltv_analysis**: Comprehensive customer lifetime value analysis with RFM components, health scoring, and behavioral patterns
- **mart_customer_segmentation**: Advanced RFM-based customer segmentation with actionable recommendations and cohort insights
- **mart_churn_rate**: Customer and revenue churn rates with retention analysis
- **mart_cohort_analysis**: Customer retention and revenue by acquisition cohorts

#### Subscription Business Intelligence
- **mart_subscription_status**: Current subscription health with risk indicators
- **mart_subscription_metrics_enhanced**: Enhanced subscription analytics with trial conversion, churn analysis, billing cycle insights, and health scoring

#### Product Performance
- **mart_product_revenue_analysis**: Product performance analysis with subscription metrics, trial conversions, and lifecycle stage classification

#### Payment Operations & Risk
- **mart_payment_success_analysis**: Payment method performance analysis with failure categorization, risk assessment, and success rate benchmarking
- **mart_failed_payments**: Payment failure analysis with categorized failure types
- **mart_refund_rate**: Refund analysis with rates, reasons, and trends
- **mart_refund_analysis_enhanced**: Comprehensive refund analysis with timing patterns, customer behavior insights, and risk categorization

#### Promotions & Discounts
- **mart_coupon_usage**: Coupon performance, ROI, and adoption metrics

#### Executive Dashboard
- **mart_business_kpi_dashboard**: Executive dashboard with comprehensive business KPIs, health scoring, and cross-functional metrics

## Key Features

### Advanced Analytics Capabilities
- **Customer Health Scoring**: 0-100 health scores for customers and products
- **RFM Segmentation**: Recency, Frequency, Monetary analysis with actionable recommendations
- **Predictive Insights**: Customer lifetime value predictions and churn risk indicators
- **Growth Metrics**: Month-over-month growth tracking across all key metrics
- **Risk Assessment**: Payment failure categorization and refund risk analysis

### Data Quality
- Primary key tests on all staging models
- Type casting for BigQuery compatibility
- Standardized naming conventions

### Performance
- Staging models materialized as views for flexibility
- Mart models materialized as tables for performance
- Optimized aggregations

### Documentation
- Model descriptions and column tests
- Clear business logic in SQL

## Common Commands

```bash
# Run specific model
dbt run --select stg_customers_view

# Run staging models only
dbt run --select staging

# Run marts models only  
dbt run --select marts

# Test specific model
dbt test --select stg_charges_view

# Compile without running
dbt compile

# Fresh rebuild
dbt run --full-refresh
```

## Customization

### Adding New Stripe Tables

1. Add table to `models/src/stripe_sources.yml`
2. Create staging model in `models/staging/stg_[table_name].sql`
3. Add tests and documentation to `models/staging/schema.yml`
4. Run `dbt run --select stg_[table_name]`

### Modifying Column Mappings

Update the staging models to match your PostgreSQL schema. Common changes:
- Column names (adjust `as` aliases)
- Data types (modify `cast()` functions)
- Additional transformations

### Creating New Marts

Build analytics models in `models/marts/` that reference staging models:

```sql
{{ config(materialized='table') }}

select *
from {{ ref('stg_customers_view') }}
-- Add your business logic here
```

## Next Steps

1. Add any additional marts needed under `models/marts/` (e.g., customer lifetime value, churn analysis).
2. Document and test each mart in `models/marts/schema.yml`.
3. Run `dbt run --models marts` to materialize your marts.
4. Use these tables for your BI dashboards or further analytical models.

## Troubleshooting

### Connection Issues
- Verify service account permissions
- Check BigQuery dataset exists
- Confirm PostgreSQL connectivity

### Model Failures
- Check column names match your PostgreSQL schema
- Verify data types are compatible
- Review dbt logs: `logs/dbt.log`

### Performance Issues
- Consider partitioning large tables
- Add appropriate indexes in PostgreSQL
- Optimize model materialization strategies

## Support

For issues with this dbt project:
1. Check dbt logs for detailed error messages
2. Verify source data quality in PostgreSQL
3. Review BigQuery permissions and quotas
4. Consult dbt documentation: https://docs.getdbt.com/ 