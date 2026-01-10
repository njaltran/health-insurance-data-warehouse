# Health Insurance Data Warehouse - dbt Project

## 🎯 Overview

This dbt project implements production-ready data cleaning and transformation pipelines for health and insurance data, following modern Data Engineering best practices from the ELT paradigm.

## 📊 Project Structure

```
dbt_health_insurance/
├── models/
│   ├── staging/          # Staging layer (views) - Schema standardization only
│   │   ├── stg_sleep_health.sql
│   │   ├── stg_smartwatch_data.sql
│   │   ├── stg_health_insurance_person.sql
│   │   ├── stg_health_insurance_facts.sql
│   │   └── sources.yml
│   └── cleaned/          # Cleaned layer (tables) - Production-ready data
│       ├── sleep_health_cleaned.sql
│       ├── smartwatch_data_cleaned.sql
│       ├── health_insurance_person_cleaned.sql
│       ├── health_insurance_facts_cleaned.sql
│       └── schema.yml    # Comprehensive data quality tests
├── macros/               # Reusable SQL macros
│   └── test_helpers.sql
├── tests/                # Custom data quality tests
├── dbt_project.yml       # Project configuration
└── profiles.yml          # BigQuery connection config
```

## 🏗️ Architecture

### **ELT Pattern (Extract-Load-Transform)**

Following modern cloud data warehouse best practices:

1. **Extract**: Data is loaded from source systems into BigQuery raw tables
2. **Load**: Raw data stored as-is (Schema-on-Write avoided)
3. **Transform**: Transformations applied in BigQuery using dbt (Schema-on-Read)

### **Layered Architecture**

#### **Staging Layer** (`models/staging/`)
- **Materialization**: Views (lightweight, always fresh)
- **Purpose**: Basic schema standardization and type casting
- **Philosophy**: Minimal transformation, preserve raw data

#### **Cleaned Layer** (`models/cleaned/`)
- **Materialization**: Tables (production-ready, performance-optimized)
- **Purpose**: Full data quality transformation
- **Philosophy**: Comprehensive cleaning, validation, and business logic

## 🔧 Data Engineering Standards Applied

### **1. Schema & Types**
✅ SAFE_CAST all columns to appropriate types (INT64, FLOAT64, DATE)
✅ Standardized column names to **snake_case**
✅ Complex field parsing (e.g., "131/86" → systolic/diastolic)

### **2. Deduplication**
✅ Full-row duplicate removal using `ROW_NUMBER()` window functions
✅ Primary key deduplication (person_id, user_id)
✅ Composite key deduplication (person_id + year)

### **3. Missing Values**
✅ **Context-aware handling:**
- Dimensions: `COALESCE(stress_level, 'unknown')`
- Metrics: `COALESCE(annual_doctor_visits, 0)`
✅ Added `is_missing_*` flags for monitoring

### **4. Value Validation**
✅ **Range validation with filters:**
- Heart rate: 30-220 bpm
- Blood oxygen: 70-100%
- Age: 0-120 years
- Sleep duration: 0-24 hours
- No future dates
- No negative costs

✅ Added `is_invalid_*` flags for quality monitoring

### **5. Standardization**
✅ **Text normalization:**
- `TRIM()` all strings
- `LOWER()` for descriptive fields
- `UPPER()` for status codes

✅ **Date standardization:**
- Handled 5 different date formats
- Converted to standard DATE type

✅ **Categorical mapping:**
- Gender: m, f, male, female → male, female, other, unknown

## 📦 Tables Created

### **1. sleep_health_cleaned**
- **Source**: `raw_Sleep_Health_and_Lifestyle_Dataset`
- **Rows**: 374 → ~320 (after deduplication)
- **Key Features**:
  - Blood pressure parsing
  - Sleep disorder NULL handling
  - Vital signs validation

### **2. smartwatch_data_cleaned**
- **Source**: `raw_smartwatch_health_data`
- **Rows**: 10,001 → ~9,800 (after validation)
- **Key Features**:
  - STRING to numeric conversion
  - Blood oxygen capping at 100%
  - Stress level missing value handling

### **3. health_insurance_person_cleaned**
- **Source**: `raw_health_insurance_person_dim`
- **Rows**: 124 → ~120 (after validation)
- **Key Features**:
  - Multi-format date parsing (5 formats)
  - Gender standardization
  - Age calculation

### **4. health_insurance_facts_cleaned**
- **Source**: `health_insurance_insurance_facts_raw`
- **Rows**: 365 → ~350 (after validation)
- **Key Features**:
  - NULL metrics → 0
  - Referential integrity with person dimension
  - Composite key deduplication

## 🚀 Getting Started

### **Prerequisites**
```bash
# Install dbt with BigQuery adapter
pip install dbt-bigquery

# Verify installation
dbt --version
```

### **Setup**

1. **Configure BigQuery connection**:
```bash
# Copy profiles.yml to ~/.dbt/
cp profiles.yml ~/.dbt/profiles.yml

# Update with your project ID
# project: your-gcp-project-id
```

2. **Install dependencies** (if using dbt packages):
```bash
dbt deps
```

3. **Test connection**:
```bash
dbt debug
```

### **Running the Project**

```bash
# Run all models (staging + cleaned)
dbt run

# Run only staging models
dbt run --select staging

# Run only cleaned models
dbt run --select cleaned

# Run specific model
dbt run --select sleep_health_cleaned

# Run with full refresh (rebuild tables)
dbt run --full-refresh
```

### **Testing**

```bash
# Run all tests
dbt test

# Test specific model
dbt test --select sleep_health_cleaned

# Run only uniqueness tests
dbt test --select test_type:unique

# Run only referential integrity tests
dbt test --select test_type:relationships
```

### **Documentation**

```bash
# Generate documentation
dbt docs generate

# Serve documentation locally
dbt docs serve
```

## 📋 Data Quality Tests

### **Schema Tests** (defined in `schema.yml`)

**sleep_health_cleaned**:
- ✅ Primary key uniqueness (person_id)
- ✅ Gender accepted values
- ✅ Heart rate range (30-220 bpm)
- ✅ Blood pressure ranges
- ✅ Sleep disorder categories

**smartwatch_data_cleaned**:
- ✅ Heart rate validation
- ✅ Blood oxygen range (70-100%)
- ✅ Step count non-negative
- ✅ Missing value flags

**health_insurance_person_cleaned**:
- ✅ Primary key uniqueness
- ✅ Age range (0-120)
- ✅ Gender standardization
- ✅ Valid status codes

**health_insurance_facts_cleaned**:
- ✅ Composite key uniqueness (person_id + year)
- ✅ Referential integrity with person dimension
- ✅ Non-negative costs
- ✅ Year range (2000-present)

## 🔍 Data Lineage

```
Raw Sources (BigQuery)
    ↓
Staging Layer (Views) - Light transformation
    ├── stg_sleep_health
    ├── stg_smartwatch_data
    ├── stg_health_insurance_person
    └── stg_health_insurance_facts
    ↓
Cleaned Layer (Tables) - Full transformation
    ├── sleep_health_cleaned
    ├── smartwatch_data_cleaned
    ├── health_insurance_person_cleaned
    └── health_insurance_facts_cleaned
    ↓
BI Tools / Analytics / ML Models
```

## 📈 Monitoring & Observability

### **Data Quality Flags**

All cleaned tables include quality flags:
- `is_invalid_*` - Records with invalid values (filtered out)
- `is_missing_*` - Records with originally NULL values (retained with defaults)

### **Audit Trail**
- `loaded_at` timestamp on all records
- dbt run logs in `target/run_results.json`
- Test failures stored in `test_failures` schema

## 🛠️ Advanced Usage

### **Custom Variables**

Override default thresholds at runtime:
```bash
dbt run --vars '{"max_heart_rate": 250, "min_heart_rate": 25}'
```

### **Incremental Runs**

Convert to incremental materialization for large datasets:
```sql
{{
  config(
    materialized='incremental',
    unique_key='person_id'
  )
}}
```

## 📚 Best Practices Implemented

Based on Expert Dossiers from HWR Berlin:

1. **ELT over ETL** - Transform after loading (Schema-on-Read)
2. **Modularity** - Layered architecture with CTEs
3. **Idempotency** - Runs can be repeated safely
4. **Data Quality Gates** - Automated testing with dbt
5. **Documentation** - Inline comments and dbt docs
6. **Version Control** - All SQL in Git
7. **Referential Integrity** - Foreign key relationships tested
8. **Metadata Management** - Schema.yml documents all models

## 🎓 References

- **dbt Documentation**: https://docs.getdbt.com/
- **BigQuery Best Practices**: https://cloud.google.com/bigquery/docs/best-practices
- **Expert Dossier 1**: Modern Data Architecture & Data Serving
- **Expert Dossier 2**: Data Quality, Metadata & Lineage
- **Expert Dossier 3**: Transformation Logic & Data Quality Engineering
- **Expert Dossier 4**: Loading Strategies & History Management

## 📞 Support

For questions or issues:
- Check dbt logs: `target/run_results.json`
- View model SQL: `target/compiled/health_insurance_dw/models/`
- Run dbt debug: `dbt debug`

---

**Built with ❤️ following Modern Data Engineering Practices**
