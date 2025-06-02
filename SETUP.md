# dbt BigQuery Setup Guide

This guide will help you set up the dbt project to work with Google BigQuery.

## Prerequisites

1. **Google Cloud Platform Account**: You need access to a GCP project with BigQuery enabled
2. **Python 3.8+**: Already installed
3. **dbt**: Already installed in the virtual environment

## Setup Steps

### 1. Activate Virtual Environment

```bash
source venv/bin/activate
```

### 2. Configure BigQuery Authentication

You have several options for authentication:

#### Option A: Service Account Key (Recommended for Production)

1. **Create a Service Account**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Navigate to IAM & Admin > Service Accounts
   - Create a new service account
   - Grant the following roles:
     - BigQuery Data Editor
     - BigQuery Job User
     - BigQuery User

2. **Download Service Account Key**:
   - Click on the service account
   - Go to Keys tab
   - Add Key > Create new key > JSON
   - Save the JSON file securely (e.g., `~/.gcp/stripe-dbt-service-account.json`)

3. **Update profiles.yml**:
   ```bash
   cp profiles.yml.example ~/.dbt/profiles.yml
   ```
   
   Then edit `~/.dbt/profiles.yml` and update:
   - `project: your-gcp-project-id` → Your actual GCP project ID
   - `keyfile: /path/to/service-account.json` → Path to your service account key file

#### Option B: OAuth (Recommended for Development)

1. **Install gcloud CLI** (if not already installed):
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # Or download from: https://cloud.google.com/sdk/docs/install
   ```

2. **Authenticate with gcloud**:
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   gcloud auth application-default login
   ```

3. **Update profiles.yml**:
   ```yaml
   stripe_bigquery:
     target: dev
     outputs:
       dev:
         type: bigquery
         method: oauth
         project: your-gcp-project-id  # ← Your actual GCP project ID
         dataset: syl
         threads: 4
         timeout_seconds: 300
         location: US
   ```

### 3. Update Source Configuration

Edit `models/src/stripe_sources.yml` and update the database name:
- Change `database: stripe_warehouse` to your actual source database name
- If your Stripe data is in BigQuery, this should be your GCP project ID
- If your Stripe data is in PostgreSQL, keep the current configuration

### 4. Test Connection

```bash
dbt debug
```

You should see:
- ✅ profiles.yml file [OK found and valid]
- ✅ dbt_project.yml file [OK found and valid]
- ✅ Connection test: [OK connection ok]

### 5. Run the Project

```bash
# Parse and compile models
dbt parse

# Run staging models first
dbt run --select staging

# Run all models
dbt run

# Run tests
dbt test

# Generate and serve documentation
dbt docs generate
dbt docs serve
```

## Troubleshooting

### Common Issues

1. **"'NoneType' object has no attribute 'close'"**
   - This usually means the service account key file path is incorrect
   - Verify the path in your profiles.yml file
   - Ensure the service account key file exists and is readable

2. **"Access Denied" errors**
   - Check that your service account has the required BigQuery permissions
   - Ensure BigQuery API is enabled in your GCP project

3. **"Dataset not found" errors**
   - The dataset will be created automatically when you run dbt
   - Ensure your service account has permissions to create datasets

4. **Source table errors**
   - Update the source configuration in `models/src/stripe_sources.yml`
   - Ensure your Stripe data is accessible from BigQuery

### Useful Commands

```bash
# Check dbt version
dbt --version

# Validate project configuration
dbt debug

# Compile models without running
dbt compile

# Run specific models
dbt run --select stg_customers_view

# Run models with dependencies
dbt run --select stg_customers_view+

# Run tests for specific models
dbt test --select staging

# Generate documentation
dbt docs generate
dbt docs serve --port 8080
```

## Next Steps

1. **Update Source Configuration**: Modify `models/src/stripe_sources.yml` to match your actual data sources
2. **Customize Models**: Review and customize the staging and mart models as needed
3. **Set up CI/CD**: Consider setting up automated testing and deployment
4. **Monitor Performance**: Use BigQuery's query performance tools to optimize your models

For more information, see the main [README.md](README.md) file. 