# 🚀 Quick Start Guide

## Prerequisites

```bash
# Install dbt with BigQuery adapter
pip install dbt-bigquery

# Verify installation
dbt --version
```

## Setup Steps

### 1. Configure BigQuery Connection

Edit `~/.dbt/profiles.yml` (or copy the provided `profiles.yml`):

```yaml
health_insurance:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: dw-health-insurance-bipm  # Update with your project ID
      dataset: raw_dataset
      threads: 4
      location: EU
```

### 2. Test Connection

```bash
cd dbt_health_insurance
dbt debug
```

Expected output:
```
✓ Connection test: [OK connection ok]
```

### 3. Install dbt Packages

```bash
dbt deps
```

This installs:
- `dbt_utils` - Useful macros and tests
- `dbt_expectations` - Great Expectations-style tests

### 4. Run the Project

```bash
# Run all models (staging + cleaned)
dbt run

# Expected output:
# - 4 staging views created
# - 4 cleaned tables created
```

### 5. Run Tests

```bash
# Run all data quality tests
dbt test

# Expected tests:
# - Primary key uniqueness
# - Range validations
# - Accepted values
# - Referential integrity
# - Custom business logic tests
```

### 6. Generate Documentation

```bash
# Generate docs
dbt docs generate

# Serve locally at http://localhost:8080
dbt docs serve
```

## Common Commands

### Development

```bash
# Run specific model
dbt run --select sleep_health_cleaned

# Run model and all downstream dependencies
dbt run --select sleep_health_cleaned+

# Run model and all upstream dependencies
dbt run --select +sleep_health_cleaned

# Run only staging layer
dbt run --select staging

# Run only cleaned layer
dbt run --select cleaned
```

### Testing

```bash
# Test specific model
dbt test --select sleep_health_cleaned

# Run only uniqueness tests
dbt test --select test_type:unique

# Run only relationship tests
dbt test --select test_type:relationships
```

### Full Refresh

```bash
# Rebuild all tables from scratch
dbt run --full-refresh

# Rebuild specific model
dbt run --select sleep_health_cleaned --full-refresh
```

## Project Outputs

After running `dbt run`, you will have:

### Staging Views (in `raw_dataset.staging` schema)
- `stg_sleep_health`
- `stg_smartwatch_data`
- `stg_health_insurance_person`
- `stg_health_insurance_facts`

### Cleaned Tables (in `raw_dataset.cleaned` schema)
- `sleep_health_cleaned`
- `smartwatch_data_cleaned`
- `health_insurance_person_cleaned`
- `health_insurance_facts_cleaned`

## Verification

### Check Row Counts

```sql
-- Sleep Health
SELECT 'sleep_health' AS table, COUNT(*) AS row_count
FROM `raw_dataset.cleaned.sleep_health_cleaned`

UNION ALL

-- Smartwatch
SELECT 'smartwatch_data', COUNT(*)
FROM `raw_dataset.cleaned.smartwatch_data_cleaned`

UNION ALL

-- Insurance Person
SELECT 'insurance_person', COUNT(*)
FROM `raw_dataset.cleaned.health_insurance_person_cleaned`

UNION ALL

-- Insurance Facts
SELECT 'insurance_facts', COUNT(*)
FROM `raw_dataset.cleaned.health_insurance_facts_cleaned`;
```

### Check Data Quality

```sql
-- Run the analysis query
SELECT * FROM {{ ref('data_quality_summary') }}
```

Or execute:
```bash
dbt compile --select analyses
# Then run the compiled SQL from target/compiled/
```

## Troubleshooting

### Issue: Connection Failed

**Solution**: Check your `profiles.yml`:
```bash
dbt debug
```

### Issue: Tables Already Exist

**Solution**: Use `--full-refresh`:
```bash
dbt run --full-refresh
```

### Issue: Tests Failing

**Solution**: Check which tests failed:
```bash
dbt test --store-failures
# Failed test results stored in test_failures schema
```

### Issue: Model Not Found

**Solution**: Check model exists:
```bash
dbt list --select sleep_health_cleaned
```

## Next Steps

1. ✅ Review generated documentation: `dbt docs serve`
2. ✅ Explore data lineage graph in docs
3. ✅ Check test results: `target/run_results.json`
4. ✅ Query cleaned tables in BigQuery
5. ✅ Connect BI tools (Looker, Tableau, etc.)

## Production Deployment

For production, update `profiles.yml`:

```yaml
health_insurance:
  target: prod
  outputs:
    prod:
      type: bigquery
      method: service-account
      project: your-prod-project
      dataset: raw_dataset
      threads: 8
      keyfile: /path/to/service-account.json
```

Then run:
```bash
dbt run --target prod
dbt test --target prod
```

## Support

- dbt Logs: `logs/dbt.log`
- Run Results: `target/run_results.json`
- Compiled SQL: `target/compiled/`
- dbt Slack: https://getdbt.slack.com

---

**Happy dbt-ing! 🎉**
