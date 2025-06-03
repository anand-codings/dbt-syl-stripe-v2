# Credits Models Data Dictionary

## Overview
The credits models form the core of Syllaby's credit-based billing and usage tracking system. These models track how users consume credits for various AI-powered video creation services and maintain a complete audit trail of all credit transactions.

## Models

### `credit_events`
**Type**: Dimension Table  
**Purpose**: Defines the catalog of credit event types that can occur in the system  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `credit_event_id` | STRING | The unique identifier for a credit event | Primary Key, Not Null, Unique |
| `credit_event_name` | STRING | The display name of the credit event | Human-readable event name |
| `event_type` | STRING | The classification of the event | Values: 'bonus', 'penalty', 'usage' |
| `calculation_type` | STRING | The method used to calculate the credit amount | Values: 'fixed', 'percentage' |
| `value` | FLOAT64 | The numerical value associated with the event for calculation purposes | Used in credit amount calculations |
| `min_amount` | FLOAT64 | The minimum qualifying amount for the event to be triggered | Threshold for event activation |

**Business Context**: Contains the master list of all possible credit events including bonus events (welcome bonuses, referral rewards, promotional credits), usage events (credits consumed for video generation, captions, voice synthesis), and penalty events (credit deductions for policy violations or refunds).

---

### `credit_histories`
**Type**: Fact Table / Transaction Log  
**Purpose**: Complete audit trail of every credit transaction for every user  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `credit_history_id` | STRING | The unique identifier for a credit history record | Primary Key, Not Null, Unique |
| `user_id` | STRING | The user associated with this credit transaction | Foreign Key, Not Null |
| `credit_event_id` | STRING | A reference to the specific event that triggered this history record | Foreign Key to credit_events, Not Null |
| `creditable_type` | STRING | For usage-based events, the type of resource that was used | Polymorphic reference (e.g., 'video', 'caption') |
| `creditable_id` | STRING | The unique ID of the resource that was used | Links to specific content that consumed credits |
| `description` | STRING | A human-readable description of the transaction | User-facing transaction description |
| `label` | STRING | A short label for display in user interfaces | UI display label |
| `calculative_index` | INT64 | An index used for internal calculation logic | System calculation reference |
| `event_value` | STRING | The display value of the event | Formatted display (e.g., '+10', '-5') |
| `amount` | FLOAT64 | The actual number of credits added or subtracted | Positive for credits added, negative for deducted |
| `previous_amount` | FLOAT64 | The user's credit balance before this transaction occurred | Running balance tracking |
| `credit_history_event_type` | STRING | The type of transaction | Values: 'debit', 'credit' |
| `meta_data` | STRING | A JSON string containing any additional metadata | Extensible additional context |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

**Business Context**: Serves as the system's financial ledger, recording every credit earned (bonuses, monthly allocations, purchases), every credit spent (video generation, premium features), running balance calculations, and detailed transaction context. Enables real-time balance calculations, historical balance reconstruction, audit trail for financial reconciliation, and fraud detection.

## Relationships
- `credit_histories.credit_event_id` → `credit_events.credit_event_id`
- `credit_histories.user_id` → `users.user_id`
- `credit_histories.creditable_type` + `credit_histories.creditable_id` → Various content models (polymorphic)

## Usage Patterns
- **Credit Consumption Flow**: User initiates AI service → System calculates required credits → Availability verified → Credits deducted and logged
- **Credit Allocation Flow**: Monthly renewals, promotions, manual adjustments → All logged with appropriate event types
- **Balance Tracking**: Running balances maintained through `previous_amount` field

## Data Quality
- Primary key uniqueness and non-null constraints
- Foreign key integrity between events and histories
- Balance reconciliation checks
- Audit trail completeness validation 