# User Management Models Data Dictionary

## Overview
The user management models handle all user-related data including user profiles, industry associations, social media accounts, feedback, and tracking information. These models support user authentication, profile management, and user behavior analytics.

## Models

### `users`
**Type**: Dimension Table  
**Purpose**: Core user profiles and account information  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `user_id` | STRING | User ID. Unique identifier for the user | Primary Key |
| `plan_id` | STRING | Reference to the subscribed plan | Foreign Key to plans |
| `account_provider` | STRING | Account provider (e.g., 'google', 'email') | Authentication method |
| `registration_code` | STRING | The registration code used during signup, if any | Referral/promo tracking |
| `promo_code` | STRING | The promotional code used by the user, if any | Marketing attribution |
| `user_type` | STRING | Type of user (e.g., 'admin', 'member') | Role classification |
| `remaining_credit_amount` | INT64 | User's current balance of remaining credits | Credit balance |
| `monthly_credit_amount` | INT64 | The number of credits allocated to the user each month | Plan allocation |
| `extra_credits` | INT64 | One-time additional credits granted to the user | Bonus credits |
| `created_at_ts` | TIMESTAMP | Timestamp of when the user record was created | Account creation |
| `updated_at_ts` | TIMESTAMP | Timestamp of the last update to the user record | Last modification |

---

### `industries`
**Type**: Dimension Table  
**Purpose**: Industry categories for user classification  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `industry_id` | STRING | Unique industry identifier | Primary Key |
| `industry_name` | STRING | Industry display name | Human-readable name |
| `industry_code` | STRING | Industry classification code | Standardized code |
| `industry_description` | STRING | Detailed industry description | Industry details |
| `parent_industry_id` | STRING | Parent industry for hierarchical classification | Self-referencing FK |
| `is_active` | BOOLEAN | Whether industry is currently active | Status flag |
| `sort_order` | INT64 | Display order for industry lists | UI ordering |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `industry_user`
**Type**: Association Table  
**Purpose**: Links users to their industry classifications  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `industry_user_id` | STRING | Unique association identifier | Primary Key |
| `user_id` | STRING | Associated user | Foreign Key to users |
| `industry_id` | STRING | Associated industry | Foreign Key to industries |
| `is_primary` | BOOLEAN | Whether this is the user's primary industry | Primary industry flag |
| `experience_level` | STRING | User's experience level in this industry | Beginner/intermediate/expert |
| `years_experience` | INT64 | Number of years of experience | Experience metric |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `social_channels`
**Type**: Dimension Table  
**Purpose**: Social media platform definitions  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `social_channel_id` | STRING | Unique social channel identifier | Primary Key |
| `channel_name` | STRING | Social platform name | Platform identifier |
| `channel_display_name` | STRING | User-friendly platform name | Display name |
| `channel_url` | STRING | Platform base URL | Platform website |
| `api_endpoint` | STRING | API endpoint for platform integration | Integration URL |
| `icon_url` | STRING | Platform icon/logo URL | Visual identifier |
| `is_active` | BOOLEAN | Whether platform is currently supported | Support status |
| `requires_oauth` | BOOLEAN | Whether platform requires OAuth authentication | Auth requirement |
| `max_video_length` | INT64 | Maximum video length in seconds | Platform constraint |
| `supported_formats` | STRING | Supported video formats | Format specifications |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `social_accounts`
**Type**: Dimension Table  
**Purpose**: User's connected social media accounts  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `social_account_id` | STRING | Unique social account identifier | Primary Key |
| `user_id` | STRING | Account owner | Foreign Key to users |
| `social_channel_id` | STRING | Associated social platform | Foreign Key to social_channels |
| `account_username` | STRING | Username on the social platform | Platform username |
| `account_display_name` | STRING | Display name on the platform | Platform display name |
| `account_url` | STRING | Profile URL on the platform | Profile link |
| `follower_count` | INT64 | Number of followers | Audience size |
| `following_count` | INT64 | Number of accounts following | Following metric |
| `is_verified` | BOOLEAN | Whether account is verified on platform | Verification status |
| `is_active` | BOOLEAN | Whether account is actively used | Usage status |
| `access_token` | STRING | OAuth access token (encrypted) | Authentication token |
| `refresh_token` | STRING | OAuth refresh token (encrypted) | Token refresh |
| `token_expires_at` | TIMESTAMP | Token expiration time | Token validity |
| `last_sync_at` | TIMESTAMP | Last synchronization with platform | Sync tracking |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `user_feedback`
**Type**: Fact Table  
**Purpose**: User feedback and support interactions  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `feedback_id` | STRING | Unique feedback identifier | Primary Key |
| `user_id` | STRING | User who provided feedback | Foreign Key to users |
| `feedback_type` | STRING | Type of feedback | Bug/feature/complaint/praise |
| `feedback_category` | STRING | Feedback category | UI/performance/billing/content |
| `feedback_title` | STRING | Feedback title/subject | Brief description |
| `feedback_content` | STRING | Detailed feedback content | Full feedback text |
| `priority_level` | STRING | Feedback priority | Low/medium/high/critical |
| `status` | STRING | Feedback processing status | New/in-progress/resolved/closed |
| `assigned_to` | STRING | Staff member assigned to feedback | Support assignment |
| `resolution_notes` | STRING | Notes on how feedback was resolved | Resolution details |
| `satisfaction_rating` | INT64 | User satisfaction rating (1-5) | Satisfaction metric |
| `resolved_at` | TIMESTAMP | Timestamp when feedback was resolved | Resolution time |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `trackers`
**Type**: Fact Table  
**Purpose**: User behavior and analytics tracking  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `tracker_id` | STRING | Unique tracker identifier | Primary Key |
| `user_id` | STRING | Associated user | Foreign Key to users |
| `session_id` | STRING | User session identifier | Session tracking |
| `event_type` | STRING | Type of tracked event | Page view/click/action |
| `event_category` | STRING | Event category | Navigation/content/billing |
| `event_action` | STRING | Specific action taken | Button click/form submit |
| `event_label` | STRING | Additional event context | Specific element |
| `page_url` | STRING | URL where event occurred | Page tracking |
| `referrer_url` | STRING | Previous page URL | Navigation flow |
| `user_agent` | STRING | Browser user agent | Device/browser info |
| `ip_address` | STRING | User's IP address | Location tracking |
| `device_type` | STRING | Device type | Desktop/mobile/tablet |
| `browser_name` | STRING | Browser name | Browser tracking |
| `operating_system` | STRING | Operating system | OS tracking |
| `screen_resolution` | STRING | Screen resolution | Display info |
| `event_value` | FLOAT64 | Numeric value associated with event | Quantitative metric |
| `custom_properties` | STRING | Additional event properties | JSON format |
| `created_at` | TIMESTAMP | Event timestamp | Event time |

## Relationships
- `users.plan_id` → `plans.plan_id`
- `industry_user.user_id` → `users.user_id`
- `industry_user.industry_id` → `industries.industry_id`
- `industries.parent_industry_id` → `industries.industry_id`
- `social_accounts.user_id` → `users.user_id`
- `social_accounts.social_channel_id` → `social_channels.social_channel_id`
- `user_feedback.user_id` → `users.user_id`
- `trackers.user_id` → `users.user_id`

## Business Context
These models support Syllaby's user management and analytics capabilities:
- **User Profiles**: Complete user account management with credit tracking
- **Industry Segmentation**: Classify users by industry for targeted features
- **Social Integration**: Connect and manage social media accounts for content distribution
- **User Support**: Track and manage user feedback and support requests
- **Analytics**: Comprehensive user behavior tracking for product optimization

## Usage Patterns
- **User Onboarding**: New users select industries and connect social accounts
- **Credit Management**: Track credit allocation, usage, and balances
- **Content Distribution**: Use connected social accounts for video publishing
- **Support Workflow**: Feedback collection and resolution tracking
- **Product Analytics**: User behavior analysis for feature development

## Data Quality
- User credit balances must be non-negative
- Social account tokens require encryption
- Feedback requires proper categorization and status tracking
- Analytics events must include session and user context 