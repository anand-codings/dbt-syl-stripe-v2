# Videos Models Data Dictionary

## Overview
The videos models contain all video-related content and assets used in Syllaby's AI-powered video creation platform. These models track different types of video content, assets, and their associated metadata.

## Models

### `videos`
**Type**: Dimension Table  
**Purpose**: Main videos table containing video metadata and lifecycle information  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Unique video identifier | Primary Key |
| `user_id` | STRING | Creator's user ID | Foreign Key to users |
| `idea_id` | STRING | Linked content idea ID | Foreign Key to ideas |
| `scheduler_id` | STRING | Reference to publication scheduler | Links to scheduling system |
| `title` | STRING | Video display title | User-facing title |
| `provider` | STRING | Hosting or generation platform | Platform identifier |
| `type` | STRING | Video category (e.g., 'faceless') | Video classification |
| `status` | STRING | Current video lifecycle status (e.g., 'completed') | Processing status |
| `metadata` | STRING | Unstructured additional video data (e.g., resolution, tags) | JSON format |
| `exports` | STRING | Info on exported video versions | JSON format |
| `synced_at` | TIMESTAMP | Last external synchronization time | Sync tracking |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `avatars`
**Type**: Dimension Table  
**Purpose**: AI avatars used in video generation  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Unique avatar identifier | Primary Key |
| `user_id` | STRING | Owner's user ID | Foreign Key to users |
| `provider_id` | STRING | External provider's reference ID | External system reference |
| `is_active` | BOOLEAN | Flag indicating if avatar is active | Status flag |
| `name` | STRING | Avatar's display name | User-facing name |
| `gender` | STRING | Gender attributed to the avatar | Avatar characteristic |
| `race` | STRING | Ethnicity/race of the avatar | Avatar characteristic |
| `preview_url` | STRING | URL for avatar preview | Media URL |
| `provider` | STRING | Source or creator of the avatar | Provider identifier |
| `type` | STRING | Avatar category (e.g., 'real-clone') | Avatar classification |
| `metadata` | STRING | Additional avatar attributes | JSON format |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `facelesses`
**Type**: Dimension Table  
**Purpose**: Faceless video content (AI-generated videos without human presenters)  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Unique faceless video identifier | Primary Key |
| `user_id` | STRING | Creator's user ID | Foreign Key to users |
| `video_id` | STRING | Associated video record | Foreign Key to videos |
| `title` | STRING | Faceless video title | Content title |
| `description` | STRING | Video description | Content description |
| `status` | STRING | Processing status | Generation status |
| `provider` | STRING | AI generation provider | Service provider |
| `metadata` | STRING | Generation parameters and settings | JSON format |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `real_clones`
**Type**: Dimension Table  
**Purpose**: Real clone videos (AI-generated videos using user's avatar/likeness)  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Unique real clone identifier | Primary Key |
| `user_id` | STRING | Creator's user ID | Foreign Key to users |
| `avatar_id` | STRING | Associated avatar | Foreign Key to avatars |
| `video_id` | STRING | Associated video record | Foreign Key to videos |
| `title` | STRING | Clone video title | Content title |
| `status` | STRING | Processing status | Generation status |
| `provider` | STRING | AI generation provider | Service provider |
| `metadata` | STRING | Clone generation parameters | JSON format |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `captions`
**Type**: Dimension Table  
**Purpose**: AI-generated video captions and subtitles  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Unique caption identifier | Primary Key |
| `user_id` | STRING | Creator's user ID | Foreign Key to users |
| `video_id` | STRING | Associated video | Foreign Key to videos |
| `language` | STRING | Caption language | Language code |
| `content` | STRING | Caption text content | Subtitle text |
| `format` | STRING | Caption file format | Format specification |
| `status` | STRING | Processing status | Generation status |
| `provider` | STRING | AI caption provider | Service provider |
| `metadata` | STRING | Caption generation settings | JSON format |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `footages`
**Type**: Dimension Table  
**Purpose**: Stock footage and background video assets  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Unique footage identifier | Primary Key |
| `title` | STRING | Footage title | Asset title |
| `description` | STRING | Footage description | Asset description |
| `category` | STRING | Footage category | Asset classification |
| `tags` | STRING | Search tags | Comma-separated tags |
| `duration` | FLOAT64 | Footage duration in seconds | Video length |
| `resolution` | STRING | Video resolution | Quality specification |
| `url` | STRING | Footage file URL | Media URL |
| `thumbnail_url` | STRING | Preview thumbnail URL | Preview image |
| `provider` | STRING | Footage source provider | Asset provider |
| `license_type` | STRING | Usage license type | Legal usage terms |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

---

### `video_assets`
**Type**: Association Table  
**Purpose**: Links videos to their associated assets (footage, music, etc.)  
**Materialization**: View  

| Column Name | Data Type | Description | Business Rules |
|-------------|-----------|-------------|----------------|
| `id` | STRING | Unique association identifier | Primary Key |
| `video_id` | STRING | Associated video | Foreign Key to videos |
| `asset_type` | STRING | Type of asset | Asset classification |
| `asset_id` | STRING | Asset identifier | Polymorphic reference |
| `usage_context` | STRING | How asset is used in video | Usage description |
| `sequence_order` | INT64 | Order in video timeline | Sequencing |
| `start_time` | FLOAT64 | Asset start time in video | Timeline position |
| `duration` | FLOAT64 | Asset duration in video | Usage duration |
| `metadata` | STRING | Asset usage parameters | JSON format |
| `created_at` | TIMESTAMP | Record creation timestamp | Audit trail |
| `updated_at` | TIMESTAMP | Last modification timestamp | Audit trail |

## Relationships
- `videos.user_id` → `users.user_id`
- `videos.idea_id` → `ideas.idea_id`
- `avatars.user_id` → `users.user_id`
- `facelesses.video_id` → `videos.id`
- `real_clones.avatar_id` → `avatars.id`
- `real_clones.video_id` → `videos.id`
- `captions.video_id` → `videos.id`
- `video_assets.video_id` → `videos.id`

## Business Context
These models support Syllaby's AI-powered video creation workflow:
- **Content Creation**: Users create videos using AI avatars, stock footage, and automated captions
- **Asset Management**: Track and organize video assets, footage, and generated content
- **Credit Consumption**: Video generation consumes user credits tracked in credit_histories
- **Quality Control**: Status tracking for AI generation processes

## Usage Patterns
- **Video Generation Flow**: User selects idea → Chooses avatar/style → AI generates video → Assets linked → Credits deducted
- **Asset Reuse**: Stock footage and avatars can be reused across multiple videos
- **Content Lifecycle**: Videos progress through statuses (pending → processing → completed → published) 