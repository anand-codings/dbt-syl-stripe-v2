# Stripe Models Data Dictionary

## Overview
The Stripe models contain cleaned and cast data from Stripe's payment processing platform. These models handle subscription billing, payment processing, customer management, and financial transactions for Syllaby's SaaS platform.

## Models

### `customers_view`
**Type**: Dimension Table  
**Purpose**: Cast and clean customer data for BigQuery  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Primary identifier for the customer | Primary Key, Not Null, Unique |
| `stripe_id` | STRING | Stripe's unique customer identifier | Not Null, External reference |
| `email` | STRING | Customer email address | Contact information |
| `name` | STRING | Customer full name | Customer identification |
| `description` | STRING | Customer description | Additional context |
| `phone` | STRING | Customer phone number | Contact information |
| `address` | STRING | Customer billing address | JSON format |
| `shipping` | STRING | Customer shipping address | JSON format |
| `currency` | STRING | Customer's preferred currency | ISO currency code |
| `balance` | INT64 | Customer account balance in cents | Account balance |
| `delinquent` | BOOLEAN | Whether customer has overdue payments | Payment status |
| `default_source` | STRING | Default payment method | Payment source ID |
| `invoice_prefix` | STRING | Prefix for customer invoices | Invoice formatting |
| `metadata_` | STRING | Additional customer metadata | JSON format |
| `created` | TIMESTAMP | Customer creation timestamp | Account creation |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `subscriptions`
**Type**: Dimension Table  
**Purpose**: Cast and clean subscription data for BigQuery  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Primary subscription identifier | Primary Key, Not Null, Unique |
| `stripe_id` | STRING | Stripe's unique subscription identifier | Not Null, External reference |
| `customer` | STRING | Associated customer ID | Foreign Key to customers |
| `product` | STRING | Associated product ID | Foreign Key to products |
| `quantity` | INT64 | Subscription quantity | Number of units |
| `currency` | STRING | Subscription currency | ISO currency code |
| `description` | STRING | Subscription description | Subscription details |
| `status` | STRING | Current subscription status | active/canceled/past_due/etc. |
| `collection_method` | STRING | Payment collection method | charge_automatically/send_invoice |
| `interval` | STRING | Billing interval | month/year |
| `items_data` | STRING | Subscription items details | JSON format |
| `plan_data` | STRING | Plan configuration data | JSON format |
| `cancellation_details` | STRING | Cancellation reason and details | JSON format |
| `livemode` | BOOLEAN | Whether subscription is in live mode | Production vs test |
| `metadata_` | STRING | Additional subscription metadata | JSON format |
| `raw_data` | STRING | Complete raw Stripe data | Full API response |
| `created` | TIMESTAMP | Subscription creation timestamp | Subscription start |
| `start_date` | TIMESTAMP | Subscription start date | Billing start |
| `current_period_start` | TIMESTAMP | Current billing period start | Period tracking |
| `current_period_end` | TIMESTAMP | Current billing period end | Period tracking |
| `trial_start` | TIMESTAMP | Trial period start | Trial tracking |
| `trial_end` | TIMESTAMP | Trial period end | Trial tracking |
| `cancel_at` | TIMESTAMP | Scheduled cancellation date | Future cancellation |
| `canceled_at` | TIMESTAMP | Actual cancellation timestamp | Cancellation tracking |
| `received_at` | TIMESTAMP | Data received timestamp | Data ingestion |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `charges_view`
**Type**: Fact Table  
**Purpose**: Cast and clean charge data for BigQuery  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Primary identifier for the charge | Primary Key, Not Null, Unique |
| `stripe_id` | STRING | Stripe's unique charge identifier | External reference |
| `amount` | INT64 | Amount intended to be collected (in cents) | Not Null, Payment amount |
| `amount_captured` | INT64 | Amount actually captured (in cents) | Captured amount |
| `amount_refunded` | INT64 | Amount refunded (in cents) | Refund tracking |
| `currency` | STRING | Charge currency | ISO currency code |
| `customer` | STRING | Associated customer ID | Foreign Key to customers |
| `description` | STRING | Charge description | Payment description |
| `invoice` | STRING | Associated invoice ID | Foreign Key to invoices |
| `payment_intent` | STRING | Associated payment intent ID | Payment flow tracking |
| `payment_method` | STRING | Payment method used | Payment method ID |
| `status` | STRING | Charge status | succeeded/pending/failed |
| `outcome` | STRING | Charge outcome details | JSON format |
| `receipt_email` | STRING | Email for receipt | Receipt delivery |
| `receipt_url` | STRING | URL for receipt | Receipt access |
| `refunded` | BOOLEAN | Whether charge was refunded | Refund status |
| `captured` | BOOLEAN | Whether charge was captured | Capture status |
| `paid` | BOOLEAN | Whether charge was paid | Payment status |
| `failure_code` | STRING | Failure reason code | Error tracking |
| `failure_message` | STRING | Failure reason message | Error details |
| `metadata_` | STRING | Additional charge metadata | JSON format |
| `created` | TIMESTAMP | Charge creation timestamp | Payment time |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `invoices_view`
**Type**: Fact Table  
**Purpose**: Cast and clean invoice data for BigQuery  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Primary invoice identifier | Primary Key, Not Null, Unique |
| `stripe_id` | STRING | Stripe's unique invoice identifier | Not Null, External reference |
| `customer` | STRING | Associated customer ID | Foreign Key to customers |
| `subscription` | STRING | Associated subscription ID | Foreign Key to subscriptions |
| `amount_due` | INT64 | Amount due on invoice (in cents) | Invoice total |
| `amount_paid` | INT64 | Amount paid on invoice (in cents) | Payment tracking |
| `amount_remaining` | INT64 | Amount remaining on invoice (in cents) | Outstanding balance |
| `currency` | STRING | Invoice currency | ISO currency code |
| `status` | STRING | Invoice status | draft/open/paid/void/uncollectible |
| `collection_method` | STRING | Collection method | charge_automatically/send_invoice |
| `description` | STRING | Invoice description | Invoice details |
| `invoice_pdf` | STRING | URL to invoice PDF | Document access |
| `hosted_invoice_url` | STRING | URL to hosted invoice page | Customer portal |
| `number` | STRING | Invoice number | Invoice identifier |
| `receipt_number` | STRING | Receipt number | Receipt identifier |
| `billing_reason` | STRING | Reason for billing | subscription_cycle/manual/etc. |
| `charge` | STRING | Associated charge ID | Payment reference |
| `payment_intent` | STRING | Associated payment intent ID | Payment flow |
| `lines` | STRING | Invoice line items | JSON format |
| `tax` | INT64 | Tax amount (in cents) | Tax calculation |
| `total` | INT64 | Total invoice amount (in cents) | Final amount |
| `subtotal` | INT64 | Subtotal before tax (in cents) | Pre-tax amount |
| `metadata_` | STRING | Additional invoice metadata | JSON format |
| `created` | TIMESTAMP | Invoice creation timestamp | Invoice date |
| `due_date` | TIMESTAMP | Invoice due date | Payment deadline |
| `period_start` | TIMESTAMP | Billing period start | Period tracking |
| `period_end` | TIMESTAMP | Billing period end | Period tracking |
| `finalized_at` | TIMESTAMP | Invoice finalization timestamp | Finalization time |
| `paid_at` | TIMESTAMP | Payment timestamp | Payment completion |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `products`
**Type**: Dimension Table  
**Purpose**: Cast and clean product data for BigQuery  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Primary product identifier | Primary Key, Not Null, Unique |
| `stripe_id` | STRING | Stripe's unique product identifier | Not Null, External reference |
| `name` | STRING | Product name | Product title |
| `description` | STRING | Product description | Product details |
| `type` | STRING | Product type | service/good |
| `active` | BOOLEAN | Whether product is active | Product status |
| `attributes` | STRING | Product attributes | JSON format |
| `caption` | STRING | Product caption | Short description |
| `images` | STRING | Product images | JSON array of URLs |
| `package_dimensions` | STRING | Package dimensions | JSON format |
| `shippable` | BOOLEAN | Whether product is shippable | Shipping flag |
| `statement_descriptor` | STRING | Statement descriptor | Billing statement text |
| `unit_label` | STRING | Unit label | Unit description |
| `url` | STRING | Product URL | Product page |
| `metadata_` | STRING | Additional product metadata | JSON format |
| `created` | TIMESTAMP | Product creation timestamp | Product creation |
| `updated` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `prices`
**Type**: Dimension Table  
**Purpose**: Cast and clean pricing data for BigQuery  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Primary price identifier | Primary Key, Not Null, Unique |
| `stripe_id` | STRING | Stripe's unique price identifier | Not Null, External reference |
| `product` | STRING | Associated product ID | Foreign Key to products |
| `currency` | STRING | Price currency | ISO currency code |
| `unit_amount` | INT64 | Price per unit (in cents) | Price amount |
| `billing_scheme` | STRING | Billing scheme | per_unit/tiered |
| `type` | STRING | Price type | one_time/recurring |
| `recurring` | STRING | Recurring billing details | JSON format |
| `tiers` | STRING | Tiered pricing details | JSON format |
| `tiers_mode` | STRING | Tiered pricing mode | graduated/volume |
| `transform_quantity` | STRING | Quantity transformation | JSON format |
| `active` | BOOLEAN | Whether price is active | Price status |
| `nickname` | STRING | Price nickname | Internal name |
| `lookup_key` | STRING | Price lookup key | External reference |
| `metadata_` | STRING | Additional price metadata | JSON format |
| `created` | TIMESTAMP | Price creation timestamp | Price creation |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `plans`
**Type**: Dimension Table  
**Purpose**: Cast and clean subscription plan data for BigQuery  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Primary plan identifier | Primary Key, Not Null, Unique |
| `stripe_id` | STRING | Stripe's unique plan identifier | Not Null, External reference |
| `product` | STRING | Associated product ID | Foreign Key to products |
| `amount` | INT64 | Plan amount (in cents) | Plan price |
| `currency` | STRING | Plan currency | ISO currency code |
| `interval` | STRING | Billing interval | month/year/week/day |
| `interval_count` | INT64 | Number of intervals | Interval multiplier |
| `nickname` | STRING | Plan nickname | Internal name |
| `usage_type` | STRING | Usage type | licensed/metered |
| `billing_scheme` | STRING | Billing scheme | per_unit/tiered |
| `tiers` | STRING | Tiered pricing details | JSON format |
| `tiers_mode` | STRING | Tiered pricing mode | graduated/volume |
| `transform_usage` | STRING | Usage transformation | JSON format |
| `trial_period_days` | INT64 | Trial period length in days | Trial duration |
| `active` | BOOLEAN | Whether plan is active | Plan status |
| `aggregate_usage` | STRING | Usage aggregation method | sum/last_during_period/max |
| `metadata_` | STRING | Additional plan metadata | JSON format |
| `created` | TIMESTAMP | Plan creation timestamp | Plan creation |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### Additional Models

#### `payment_intents_view`
**Purpose**: Cast and clean payment intent data for BigQuery  
**Key Columns**: `id`, `stripe_id`, payment flow tracking, status management

#### `refunds`
**Purpose**: Cast and clean refund data for BigQuery  
**Key Columns**: `id`, `stripe_id`, refund amounts, refund reasons

#### `coupons`
**Purpose**: Cast and clean coupon data for BigQuery  
**Key Columns**: `id`, `stripe_id`, discount details, usage tracking

## Relationships
- `subscriptions.customer` → `customers_view.stripe_id`
- `subscriptions.product` → `products.stripe_id`
- `charges_view.customer` → `customers_view.stripe_id`
- `charges_view.invoice` → `invoices_view.stripe_id`
- `invoices_view.customer` → `customers_view.stripe_id`
- `invoices_view.subscription` → `subscriptions.stripe_id`
- `prices.product` → `products.stripe_id`
- `plans.product` → `products.stripe_id`

## Data Sources
All models source from the `stripe` schema containing raw Stripe webhook data.

## Business Context
These models support Syllaby's subscription billing and payment processing:
- **Customer Management**: Track customer accounts and billing information
- **Subscription Billing**: Manage recurring subscription charges and lifecycle
- **Payment Processing**: Handle one-time and recurring payments
- **Revenue Recognition**: Track revenue from charges and invoices
- **Financial Reporting**: Provide clean data for financial analysis

## Usage Patterns
- **Subscription Analytics**: Track MRR, churn, and customer lifecycle
- **Payment Monitoring**: Monitor payment success rates and failures
- **Revenue Reporting**: Calculate revenue from charges and subscriptions
- **Customer Support**: Access customer billing history and status
- **Financial Reconciliation**: Match payments to invoices and subscriptions

## Data Quality
- All monetary amounts stored in cents for precision
- Timestamps in UTC for consistency
- JSON fields for complex Stripe objects
- Primary key uniqueness and foreign key integrity
- Status field validation for business logic 