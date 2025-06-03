# Credits Models

The credits models in this directory form the core of Syllaby's credit-based billing and usage tracking system. These models track how users consume credits for various AI-powered video creation services and maintain a complete audit trail of all credit transactions.

## Overview

Syllaby operates on a credit-based system where users consume credits to generate AI content such as:
- **Faceless videos** - AI-generated videos without human presenters
- **Real clone videos** - AI-generated videos using user's avatar/likeness  
- **Captions** - AI-generated video captions and subtitles
- **Voice synthesis** - AI voice generation for videos
- **Background music and assets** - Premium media assets

Users receive monthly credit allocations based on their subscription plan (Basic, Pro, Enterprise) and can earn bonus credits through promotions or purchase additional credits.

## Models

### `credit_events`
**Type**: Dimension Table  
**Purpose**: Defines the catalog of credit event types that can occur in the system.

This model contains the master list of all possible credit events, including:
- **Bonus events** - Welcome bonuses, referral rewards, promotional credits
- **Usage events** - Credits consumed for video generation, captions, voice synthesis
- **Penalty events** - Credit deductions for policy violations or refunds

Key fields:
- `event_type`: Classification (bonus, usage, penalty)
- `calculation_type`: How credits are calculated (fixed amount, percentage-based)
- `value`: Base value for credit calculations
- `min_amount`: Minimum threshold for event triggering

### `credit_histories`
**Type**: Fact Table / Transaction Log  
**Purpose**: Complete audit trail of every credit transaction for every user.

This model serves as the system's financial ledger, recording:
- Every credit earned (bonuses, monthly allocations, purchases)
- Every credit spent (video generation, premium features)
- Running balance calculations
- Detailed transaction context

Key fields:
- `user_id`: Links to the user who performed the transaction
- `credit_event_id`: References the type of event from `credit_events`
- `creditable_type` & `creditable_id`: Polymorphic relationship to the resource that triggered the credit usage (e.g., 'video', 'caption')
- `amount`: Credits added (+) or deducted (-)
- `previous_amount`: User's balance before this transaction
- `description`: Human-readable transaction description
- `meta_data`: Additional context stored as JSON

## Business Logic

### Credit Consumption Flow
1. User initiates an AI service (e.g., creates a faceless video)
2. System calculates required credits based on service complexity
3. Credit availability is verified against user's current balance
4. Upon successful generation, credits are deducted and logged in `credit_histories`
5. The generated content is linked via `creditable_type` and `creditable_id`

### Credit Allocation Flow
1. Monthly subscription renewals trigger credit allocation events
2. Promotional campaigns can grant bonus credits
3. Manual admin adjustments for customer service
4. All allocations are logged with appropriate event types

### Balance Tracking
The `credit_histories` model maintains running balances through the `previous_amount` field, enabling:
- Real-time balance calculations
- Historical balance reconstruction
- Audit trail for financial reconciliation
- Fraud detection and usage pattern analysis

## Usage in Analytics

These models power several downstream analytics:

- **User credit trend dashboards** - Track usage patterns and predict churn
- **Service efficiency analysis** - Calculate cost per service type
- **Plan optimization** - Analyze credit allocation vs. actual usage by subscription tier
- **Revenue attribution** - Connect credit consumption to subscription revenue

## Data Quality

The models include comprehensive testing:
- Primary key uniqueness and non-null constraints
- Foreign key integrity between events and histories
- Balance reconciliation checks
- Audit trail completeness validation

## Related Models

- `users` - Contains user credit balances and monthly allocations
- `videos`, `captions`, `facelesses`, `real_clones` - Content models that consume credits
- `subscriptions` and `plans` - Billing models that determine credit allocations
- Mart models in `/marts/` - Aggregated analytics built on top of these credit models

## Technical Notes

- Both models are materialized as **views** for real-time data access
- Data is sourced from the `syllaby_v2` schema in the operational database
- All monetary amounts are stored as `FLOAT64` for precision
- Timestamps track both creation and modification times
- JSON metadata fields provide extensibility for future requirements