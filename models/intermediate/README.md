# Intermediate Models - DRY Refactoring

This directory contains intermediate models that consolidate repeated business logic from the marts layer, implementing DRY (Don't Repeat Yourself) principles.

## Overview

The intermediate models were created to eliminate code duplication across multiple mart models. Previously, complex business logic was repeated in multiple places, making maintenance difficult and increasing the risk of inconsistencies.

## Models

### `int_customer_active_periods`
**Purpose**: Unified charge expansion logic  
**Replaces**: Duplicated charge expansion CTEs in multiple MRR and lifecycle models  
**Used by**:
- `mart_monthly_subscription_mrr`
- `mart_annual_subscription_mrr`
- `mart_subscription_mrr_unified`
- `mart_customer_lifecycle_status`

This model expands each paid charge to determine all the months and years a subscription is considered "active" for a customer. It includes both monthly and yearly activity periods, billing cycle types, and charge details for revenue calculations.

### `int_plans_with_tiers`
**Purpose**: Centralized plan tier categorization  
**Replaces**: Duplicated plan tier logic across credit-related models  
**Used by**:
- `mart_credit_allocation_vs_usage_by_plan`
- `mart_credit_churn_risk`
- `mart_monthly_credit_allocation`

This model consolidates the business logic for categorizing subscription plans into tiers:
- **Pro**: Monthly plans >= $50.00
- **Basic**: Monthly plans < $50.00
- **Enterprise**: Annual plans
- **Other**: All other plans

It handles both the legacy `plans` table and the modern `prices` table.

### `int_customer_latest_subscription`
**Purpose**: Customer's current/primary subscription  
**Replaces**: Subscription ranking logic from customer segmentation  
**Used by**:
- `mart_customer_segmentation`
- Any other marts needing current subscription info

This model provides each customer's latest subscription with intelligent ranking that prioritizes:
1. Active subscriptions first
2. Most recent start date
3. Most recent creation date

### `int_customer_tenure`
**Purpose**: Customer tenure calculations  
**Replaces**: Duplicated tenure logic across multiple models  
**Used by**:
- `mart_customer_segmentation`
- `mart_monthly_credit_balance`

This model provides standardized customer tenure calculations based on:
- First paid charge date
- First subscription date
- Tenure segments (0-5 months, 6-11 months, etc.)
- Months subscribed calculations

## Benefits of This Refactoring

### 1. **Reduced Maintenance Overhead**
- Business logic exists in one place
- Changes to business rules only need to be made once
- Easier to maintain and update

### 2. **Improved Consistency**
- All marts use the exact same definitions for key concepts
- Eliminates discrepancies between models
- Ensures consistent reporting across the organization

### 3. **Increased Readability**
- Final mart models are much cleaner
- Focus on joins and final aggregations rather than complex transformations
- Easier for new team members to understand

### 4. **Better Performance**
- Intermediate models can be materialized as tables
- Reduces computation time for downstream models
- Enables better query optimization

### 5. **Enhanced Testing**
- Business logic can be tested at the intermediate level
- Easier to validate core calculations
- More granular testing capabilities

## Migration Notes

The refactoring maintains backward compatibility - all existing mart models produce the same results but now use the centralized intermediate models. The changes are purely structural and do not affect the business logic or output.

## Future Enhancements

Consider creating additional intermediate models for:
- Customer LTM (Last Twelve Months) revenue calculations
- Geographic segmentation logic
- Trial period expansions
- Churn prediction features

This foundation makes it easy to continue applying DRY principles as the data model evolves. 