# Content Models Data Dictionary

## Overview
The content models manage all content-related data including surveys, tagging systems, templates, SEO keywords, ideas, and metadata. These models support content discovery, organization, and user-generated content management.

## Models

### Survey Models

#### `surveys`
**Type**: Dimension Table  
**Purpose**: Contains all surveys  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `survey_id` | STRING | Unique survey identifier | Primary Key, Not Null, Unique |
| `title` | STRING | Survey title | Survey name |
| `description` | STRING | Survey description | Survey purpose |
| `status` | STRING | Survey status | Active/inactive status |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

#### `questions`
**Type**: Dimension Table  
**Purpose**: Contains all questions related to surveys  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `question_id` | STRING | Unique question identifier | Primary Key, Not Null, Unique |
| `survey_id` | STRING | Associated survey | Foreign Key, Not Null |
| `question_text` | STRING | Question content | Question text |
| `question_type` | STRING | Type of question | Multiple choice, text, etc. |
| `required` | BOOLEAN | Whether question is required | Validation flag |
| `order_index` | INT64 | Question order in survey | Display sequence |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

#### `answers`
**Type**: Fact Table  
**Purpose**: Contains user-submitted answers to survey questions  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `answer_id` | STRING | Unique answer identifier | Primary Key, Not Null, Unique |
| `user_id` | STRING | User who submitted answer | Foreign Key, Not Null |
| `question_id` | STRING | Associated question | Foreign Key, Not Null |
| `answer_text` | STRING | User's answer content | Response text |
| `answer_value` | STRING | Structured answer value | Normalized response |
| `submitted_at` | TIMESTAMP | Answer submission time | Response timestamp |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### Tagging Models

#### `tags`
**Type**: Dimension Table  
**Purpose**: Dimension table of all user-created tags  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `tag_id` | STRING | Unique tag identifier | Primary Key, Not Null, Unique |
| `tag_name` | STRING | Tag display name | User-facing tag name |
| `tag_slug` | STRING | URL-friendly tag identifier | Normalized tag name |
| `user_id` | STRING | Tag creator | Foreign Key to users |
| `usage_count` | INT64 | Number of times tag is used | Usage tracking |
| `is_public` | BOOLEAN | Whether tag is publicly visible | Visibility flag |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

#### `taggables`
**Type**: Association Table  
**Purpose**: Association table linking tags to various content types (polymorphic)  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `taggable_record_id` | STRING | Unique association identifier | Primary Key, Not Null, Unique |
| `tag_id` | STRING | Associated tag | Foreign Key, Not Null |
| `taggable_id` | STRING | ID of tagged content | Polymorphic reference, Not Null |
| `taggable_type` | STRING | Type of tagged content | Content model name |
| `tagged_by_user_id` | STRING | User who applied the tag | Foreign Key to users |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |

#### `bookmarks`
**Type**: Association Table  
**Purpose**: Contains user bookmarks of various content types (polymorphic)  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `bookmark_id` | STRING | Unique bookmark identifier | Primary Key, Not Null, Unique |
| `user_id` | STRING | User who created bookmark | Foreign Key, Not Null |
| `bookmarked_model_id` | STRING | ID of bookmarked content | Polymorphic reference, Not Null |
| `bookmarked_model_type` | STRING | Type of bookmarked content | Content model name |
| `bookmark_name` | STRING | User-defined bookmark name | Optional custom name |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### Template Models

#### `templates`
**Type**: Dimension Table  
**Purpose**: Contains all user-created and system templates  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `template_id` | STRING | Unique template identifier | Primary Key, Not Null, Unique |
| `template_name` | STRING | Template display name | User-facing name |
| `template_description` | STRING | Template description | Purpose description |
| `template_content` | STRING | Template content/structure | Template body |
| `template_type` | STRING | Type of template | Video, post, etc. |
| `user_id` | STRING | Template creator | Foreign Key to users |
| `is_system_template` | BOOLEAN | Whether template is system-provided | System vs user template |
| `is_public` | BOOLEAN | Whether template is publicly available | Sharing flag |
| `usage_count` | INT64 | Number of times template is used | Usage tracking |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### SEO Models

#### `keywords`
**Type**: Dimension Table  
**Purpose**: Dimension table of all keywords  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `keyword_id` | STRING | Unique keyword identifier | Primary Key, Not Null, Unique |
| `keyword_text` | STRING | Keyword phrase | Search term |
| `keyword_slug` | STRING | URL-friendly keyword identifier | Normalized keyword |
| `search_volume` | INT64 | Monthly search volume | SEO metric |
| `competition_score` | FLOAT64 | Keyword competition level | SEO difficulty |
| `cost_per_click` | FLOAT64 | Average CPC for keyword | Advertising metric |
| `trend_status` | STRING | Keyword trend direction | Rising/falling/stable |
| `language` | STRING | Keyword language | Language code |
| `country` | STRING | Target country | Geographic targeting |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

#### `ideas`
**Type**: Dimension Table  
**Purpose**: Contains generated ideas, typically linked to a keyword  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `idea_id` | STRING | Unique identifier for the idea | Primary Key, Not Null, Unique |
| `keyword_id` | STRING | Reference to a related keyword | Foreign Key |
| `idea_title` | STRING | The title of the idea | Content title |
| `idea_slug` | STRING | URL-friendly identifier for the idea | Normalized title |
| `idea_type` | STRING | The type or category of the idea | Content classification |
| `trend_status` | STRING | The trend status of the idea | Trending indicator |
| `country_code` | STRING | The country where the idea is relevant | Geographic relevance |
| `currency_code` | STRING | The currency related to the idea's metrics | Monetary context |
| `locale` | STRING | Locale information (e.g., 'en-US') | Localization |
| `search_volume` | INT64 | The search volume for the keyword | SEO metric |
| `cost_per_click` | FLOAT64 | The cost-per-click value | Advertising metric |
| `competition_score` | FLOAT64 | Numeric value of the keyword competition | Competition level |
| `competition_label` | STRING | Descriptive label for the competition level | Human-readable competition |
| `total_results` | INT64 | The total number of search results for the keyword | Search result count |
| `is_public` | BOOLEAN | Boolean flag indicating if the idea is publicly visible | Visibility flag |
| `trends_json` | STRING | JSON containing time-based trend data | Trend analytics |
| `valid_until_ts` | TIMESTAMP | The expiry date for the idea data | Data freshness |
| `deleted_at_ts` | TIMESTAMP | Timestamp of deletion (if soft deleted) | Soft delete tracking |
| `created_at_ts` | TIMESTAMP | Timestamp of when the idea was created | Audit trail |
| `updated_at_ts` | TIMESTAMP | Timestamp of the last update to the idea | Audit trail |

#### `related_topics`
**Type**: Dimension Table  
**Purpose**: Contains topics related to keywords or ideas  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `related_topic_id` | STRING | Unique related topic identifier | Primary Key, Not Null, Unique |
| `keyword_id` | STRING | Associated keyword | Foreign Key |
| `idea_id` | STRING | Associated idea | Foreign Key |
| `topic_text` | STRING | Related topic content | Topic description |
| `relevance_score` | FLOAT64 | How relevant the topic is | Relevance metric |
| `search_volume` | INT64 | Search volume for the topic | SEO metric |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

#### `keyword_user`
**Type**: Association Table  
**Purpose**: Association table linking users to keywords  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `keyword_user_id` | STRING | Unique association identifier | Primary Key, Not Null, Unique |
| `user_id` | STRING | Associated user | Foreign Key, Not Null |
| `keyword_id` | STRING | Associated keyword | Foreign Key, Not Null |
| `tracking_status` | STRING | User's tracking status for keyword | Active/paused/stopped |
| `priority_level` | STRING | User's priority for this keyword | High/medium/low |
| `notes` | STRING | User's notes about the keyword | Personal notes |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### System Models

#### `metadata`
**Type**: Dimension Table  
**Purpose**: A generic table for storing various types of key-value metadata from different providers  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `metadata_id` | STRING | Unique metadata identifier | Primary Key, Not Null, Unique |
| `entity_type` | STRING | Type of entity the metadata belongs to | Entity classification |
| `entity_id` | STRING | ID of the entity | Polymorphic reference |
| `provider` | STRING | Source of the metadata | Provider identifier |
| `metadata_key` | STRING | Metadata key/name | Key identifier |
| `metadata_value` | STRING | Metadata value | Value content |
| `data_type` | STRING | Type of the metadata value | String/number/boolean/json |
| `is_sensitive` | BOOLEAN | Whether metadata contains sensitive information | Security flag |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

## Relationships
- `questions.survey_id` → `surveys.survey_id`
- `answers.question_id` → `questions.question_id`
- `answers.user_id` → `users.user_id`
- `taggables.tag_id` → `tags.tag_id`
- `bookmarks.user_id` → `users.user_id`
- `templates.user_id` → `users.user_id`
- `ideas.keyword_id` → `keywords.keyword_id`
- `related_topics.keyword_id` → `keywords.keyword_id`
- `related_topics.idea_id` → `ideas.idea_id`
- `keyword_user.user_id` → `users.user_id`
- `keyword_user.keyword_id` → `keywords.keyword_id`

## Business Context
These models support Syllaby's content management and SEO capabilities:
- **Content Organization**: Tags and bookmarks help users organize their content
- **Template System**: Reusable templates for consistent content creation
- **SEO Research**: Keywords and ideas drive content strategy
- **User Feedback**: Surveys collect user insights and preferences
- **Metadata Management**: Flexible key-value storage for various data needs

## Usage Patterns
- **Content Discovery**: Users search and filter content using tags and keywords
- **Template Usage**: Users create content from templates, tracking usage patterns
- **SEO Workflow**: Keywords generate ideas → Ideas become videos → Performance tracked
- **User Research**: Surveys collect feedback to improve platform features 