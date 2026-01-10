# Troubleshooting Guide

## Common Issues and Solutions

### ✅ FIXED: BigQuery FLOAT64 Partitioning Error

**Error Message:**
```
Database Error in model smartwatch_data_cleaned
Partitioning by expressions of type FLOAT64 is not allowed at [86:35]
```

**Problem:**
BigQuery does not allow `PARTITION BY` clauses in window functions to use FLOAT64 columns directly.

**Original Code (BROKEN):**
```sql
ROW_NUMBER() OVER (
    PARTITION BY user_id, heart_rate_bpm, step_count, sleep_duration_hours
    ORDER BY loaded_at DESC
)
```

**Fixed Code:**
```sql
ROW_NUMBER() OVER (
    PARTITION BY
        user_id,
        -- Convert FLOAT64 to STRING to avoid partitioning error
        CAST(ROUND(heart_rate_bpm, 2) AS STRING),
        CAST(ROUND(step_count, 2) AS STRING),
        CAST(ROUND(sleep_duration_hours, 2) AS STRING)
    ORDER BY loaded_at DESC
)
```

**Solution Applied:**
- Round float values to 2 decimal places
- Cast to STRING for partitioning
- This allows duplicate detection while avoiding BigQuery's FLOAT64 restriction

**Status:** ✅ Fixed in both `smartwatch_data_cleaned.sql` and `data_cleaning_scripts.sql`

---

## Other Common Issues

### Issue: Connection Failed

**Error:**
```
Could not connect to BigQuery
```

**Solutions:**
1. Check `~/.dbt/profiles.yml` exists and has correct project ID
2. Verify authentication:
   ```bash
   gcloud auth application-default login
   ```
3. Test connection:
   ```bash
   dbt debug
   ```

---

### Issue: Tables Already Exist

**Error:**
```
Table already exists: raw_dataset.cleaned.sleep_health_cleaned
```

**Solutions:**

**Option 1 - Full Refresh (Rebuild tables):**
```bash
dbt run --full-refresh
```

**Option 2 - Drop tables manually:**
```sql
DROP TABLE IF EXISTS `raw_dataset.cleaned.sleep_health_cleaned`;
DROP TABLE IF EXISTS `raw_dataset.cleaned.smartwatch_data_cleaned`;
DROP TABLE IF EXISTS `raw_dataset.cleaned.health_insurance_person_cleaned`;
DROP TABLE IF EXISTS `raw_dataset.cleaned.health_insurance_facts_cleaned`;
```

Then run:
```bash
dbt run
```

---

### Issue: Tests Failing

**Error:**
```
Failure in test unique_person_id
Got 2 results, expected 0
```

**Solutions:**

1. **View test failures:**
   ```bash
   dbt test --store-failures
   ```

2. **Query failed test results:**
   ```sql
   SELECT * FROM `raw_dataset.test_failures.unique_person_id`;
   ```

3. **Debug specific model:**
   ```bash
   dbt test --select sleep_health_cleaned
   ```

4. **Check compiled SQL:**
   ```bash
   cat target/compiled/health_insurance_dw/models/cleaned/sleep_health_cleaned.sql
   ```

---

### Issue: Model Not Found

**Error:**
```
Could not find model 'sleep_health_cleaned'
```

**Solutions:**

1. **List all models:**
   ```bash
   dbt list
   ```

2. **Check model path:**
   ```bash
   ls -la models/cleaned/sleep_health_cleaned.sql
   ```

3. **Verify dbt_project.yml config:**
   ```yaml
   models:
     health_insurance_dw:
       cleaned:
         +materialized: table
   ```

---

### Issue: Source Not Found

**Error:**
```
Source 'raw_dataset.raw_Sleep_Health_and_Lifestyle_Dataset' not found
```

**Solutions:**

1. **Check source exists in BigQuery:**
   ```sql
   SELECT COUNT(*) FROM `raw_dataset.raw_Sleep_Health_and_Lifestyle_Dataset`;
   ```

2. **Verify sources.yml:**
   ```bash
   cat models/staging/sources.yml
   ```

3. **List available sources:**
   ```bash
   dbt list --resource-type source
   ```

---

### Issue: Package Installation Failed

**Error:**
```
Could not install package dbt-labs/dbt_utils
```

**Solutions:**

1. **Clean packages:**
   ```bash
   rm -rf dbt_packages/
   ```

2. **Reinstall:**
   ```bash
   dbt deps
   ```

3. **Check packages.yml syntax:**
   ```yaml
   packages:
     - package: dbt-labs/dbt_utils
       version: 1.1.1
   ```

---

### Issue: Permission Denied

**Error:**
```
Permission denied on dataset raw_dataset
```

**Solutions:**

1. **Check BigQuery permissions:**
   - Need `BigQuery Data Editor` role
   - Need `BigQuery Job User` role

2. **Verify service account (if using one):**
   ```bash
   gcloud auth list
   ```

3. **Grant permissions:**
   ```bash
   gcloud projects add-iam-policy-binding PROJECT_ID \
     --member="user:YOUR_EMAIL" \
     --role="roles/bigquery.dataEditor"
   ```

---

### Issue: Variable Not Found

**Error:**
```
Variable 'max_heart_rate' is undefined
```

**Solutions:**

1. **Check dbt_project.yml has vars defined:**
   ```yaml
   vars:
     max_heart_rate: 220
     min_heart_rate: 30
   ```

2. **Override at runtime:**
   ```bash
   dbt run --vars '{"max_heart_rate": 250}'
   ```

---

### Issue: Compilation Error

**Error:**
```
Compilation Error in model sleep_health_cleaned
Unexpected end of template
```

**Solutions:**

1. **Check Jinja syntax:**
   - Missing `{% endfor %}`
   - Missing `}}`
   - Unmatched `{{ }}`

2. **Compile without running:**
   ```bash
   dbt compile --select sleep_health_cleaned
   ```

3. **View compiled SQL:**
   ```bash
   cat target/compiled/health_insurance_dw/models/cleaned/sleep_health_cleaned.sql
   ```

---

## Performance Issues

### Issue: Query Timeout

**Error:**
```
Query execution timeout
```

**Solutions:**

1. **Increase timeout in profiles.yml:**
   ```yaml
   outputs:
     dev:
       timeout_seconds: 600  # Increase from 300
   ```

2. **Add partitioning/clustering:**
   ```sql
   {{
     config(
       materialized='table',
       partition_by={
         'field': 'loaded_at',
         'data_type': 'timestamp'
       }
     )
   }}
   ```

3. **Optimize window functions:**
   - Use smaller partition keys
   - Add WHERE clause before window function

---

### Issue: Out of Memory

**Error:**
```
Resources exceeded during query execution
```

**Solutions:**

1. **Break into smaller CTEs**
2. **Use incremental materialization:**
   ```sql
   {{
     config(
       materialized='incremental',
       unique_key='person_id'
     )
   }}
   ```

3. **Filter early in pipeline**

---

## Debug Commands

```bash
# Check dbt configuration
dbt debug

# List all models
dbt list

# List only cleaned models
dbt list --select cleaned

# Compile without running
dbt compile

# Run specific model
dbt run --select sleep_health_cleaned

# Run model and dependencies
dbt run --select +sleep_health_cleaned

# Test specific model
dbt test --select sleep_health_cleaned

# Show model SQL
dbt show --select sleep_health_cleaned --limit 10

# Parse project without running
dbt parse

# Clean compiled files
dbt clean
```

---

## Log Locations

- **dbt logs:** `logs/dbt.log`
- **Run results:** `target/run_results.json`
- **Manifest:** `target/manifest.json`
- **Compiled SQL:** `target/compiled/health_insurance_dw/`
- **Test failures:** In `test_failures` schema (if `+store_failures: true`)

---

## Getting Help

1. **Check dbt logs:**
   ```bash
   cat logs/dbt.log
   ```

2. **View compiled SQL:**
   ```bash
   cat target/run/health_insurance_dw/models/cleaned/MODEL_NAME.sql
   ```

3. **dbt Documentation:**
   - https://docs.getdbt.com/
   - https://docs.getdbt.com/reference/dbt-jinja-functions

4. **BigQuery Documentation:**
   - https://cloud.google.com/bigquery/docs

5. **dbt Community:**
   - Slack: https://getdbt.slack.com
   - Discourse: https://discourse.getdbt.com

---

**Last Updated:** 2026-01-10 after fixing FLOAT64 partitioning issue
