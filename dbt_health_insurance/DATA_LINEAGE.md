# Data Lineage & Architecture Diagram

## 🔄 Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           RAW SOURCES (BigQuery)                                 │
│                          Dataset: raw_dataset                                    │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ EXTRACT & LOAD
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           STAGING LAYER (Views)                                  │
│                        Dataset: raw_dataset.staging                              │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌────────────────────────┐│
│  │  stg_sleep_health    │  │  stg_smartwatch_data │  │  stg_health_insurance  ││
│  │                      │  │                      │  │  _person               ││
│  │ • Type casting       │  │ • STRING → numeric   │  │  • Trim whitespace     ││
│  │ • Column rename      │  │ • Column rename      │  │  • Column rename       ││
│  │ • TRIM/LOWER         │  │ • TRIM/LOWER         │  │  • Preserve dates      ││
│  └──────────────────────┘  └──────────────────────┘  └────────────────────────┘│
│                                                        ┌────────────────────────┐│
│                                                        │  stg_health_insurance  ││
│                                                        │  _facts                ││
│                                                        │  • Type casting        ││
│                                                        │  • Trim person_id      ││
│                                                        └────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ TRANSFORM
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           CLEANED LAYER (Tables)                                 │
│                        Dataset: raw_dataset.cleaned                              │
│  ┌──────────────────────┐  ┌──────────────────────┐  ┌────────────────────────┐│
│  │ sleep_health_cleaned │  │ smartwatch_data      │  │ health_insurance       ││
│  │                      │  │ _cleaned             │  │ _person_cleaned        ││
│  │ TRANSFORMATIONS:     │  │                      │  │                        ││
│  │ ✓ Deduplicate        │  │ TRANSFORMATIONS:     │  │ TRANSFORMATIONS:       ││
│  │ ✓ Parse BP           │  │ ✓ Deduplicate        │  │ ✓ Parse dates (5 fmt)  ││
│  │ ✓ Handle NULLs       │  │ ✓ Handle NULLs       │  │ ✓ Standardize gender   ││
│  │ ✓ Validate ranges    │  │ ✓ Validate ranges    │  │ ✓ Calculate age        ││
│  │ ✓ Quality flags      │  │ ✓ Quality flags      │  │ ✓ Normalize text       ││
│  │                      │  │                      │  │ ✓ Validate dates       ││
│  │ TESTS: 11            │  │ TESTS: 7             │  │ ✓ Quality flags        ││
│  └──────────────────────┘  └──────────────────────┘  │                        ││
│                                                        │ TESTS: 12              ││
│                                                        └────────────────────────┘│
│                                                        ┌────────────────────────┐│
│                                                        │ health_insurance       ││
│                                                        │ _facts_cleaned         ││
│                                                        │                        ││
│                                                        │ TRANSFORMATIONS:       ││
│                                                        │ ✓ Deduplicate (PK+yr)  ││
│                                                        │ ✓ Handle NULLs (→ 0)   ││
│                                                        │ ✓ Validate costs       ││
│                                                        │ ✓ Validate year        ││
│                                                        │ ✓ Quality flags        ││
│                                                        │ ✓ FK integrity         ││
│                                                        │                        ││
│                                                        │ TESTS: 9               ││
│                                                        └────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ SERVE
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           CONSUMPTION LAYER                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐  │
│  │  BI Tools    │  │  ML Models   │  │  Analytics   │  │  Reverse ETL       │  │
│  │  (Looker,    │  │  (Vertex AI, │  │  (Jupyter,   │  │  (Hightouch,       │  │
│  │  Tableau)    │  │  TensorFlow) │  │  Colab)      │  │  Census)           │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Detailed Table Lineage

### **Sleep Health Pipeline**

```
raw_Sleep_Health_and_Lifestyle_Dataset (374 rows)
    │
    │ [Staging: Type casting, column rename]
    ▼
stg_sleep_health (374 rows - VIEW)
    │
    │ [Cleaning: Parse BP, dedupe, validate, handle NULLs]
    ▼
sleep_health_cleaned (~320 rows - TABLE)
    │
    │ Quality Checks: 11 tests
    │ • unique(person_id)
    │ • accepted_values(gender)
    │ • range(heart_rate: 30-220)
    │ • range(blood_pressure)
    │ • accepted_values(sleep_disorder)
    ▼
    BI/Analytics
```

### **Smartwatch Data Pipeline**

```
raw_smartwatch_health_data (10,001 rows)
    │
    │ [Staging: STRING → numeric, column rename]
    ▼
stg_smartwatch_data (10,001 rows - VIEW)
    │
    │ [Cleaning: Handle NULLs, validate, dedupe]
    ▼
smartwatch_data_cleaned (~9,800 rows - TABLE)
    │
    │ Quality Checks: 7 tests
    │ • range(heart_rate: 30-220)
    │ • range(blood_oxygen: 70-100%)
    │ • non_negative(step_count)
    │ • missing_value_flags
    ▼
    ML Models / Analytics
```

### **Insurance Person Dimension Pipeline**

```
raw_health_insurance_person_dim (124 rows)
    │
    │ [Staging: Trim whitespace, preserve dates]
    ▼
stg_health_insurance_person (124 rows - VIEW)
    │
    │ [Cleaning: Parse dates (5 formats), standardize, calculate age]
    ▼
health_insurance_person_cleaned (~120 rows - TABLE)
    │
    │ Quality Checks: 12 tests
    │ • unique(person_id)
    │ • accepted_values(gender, status, wealth)
    │ • range(age: 0-120)
    │ • valid_dates
    ▼
    BI Dashboards
```

### **Insurance Facts Pipeline**

```
health_insurance_insurance_facts_raw (365 rows)
    │
    │ [Staging: Type casting, trim person_id]
    ▼
stg_health_insurance_facts (365 rows - VIEW)
    │
    │ [Cleaning: Handle NULLs (→0), validate, dedupe on PK+year]
    ▼
health_insurance_facts_cleaned (~350 rows - TABLE)
    │
    │ Quality Checks: 9 tests
    │ • unique_combination(person_id, year)
    │ • relationships(person_id → person_cleaned)
    │ • non_negative(costs)
    │ • range(year: 2000-present)
    │ • range(doctor_visits: 0-365)
    ▼
    Revenue Analytics / Forecasting
```

---

## 🔗 Referential Integrity

```
┌──────────────────────────────────┐
│ health_insurance_person_cleaned  │
│ ┌──────────────┐                 │
│ │  person_id   │ (PRIMARY KEY)   │
│ └──────────────┘                 │
└──────────────────────────────────┘
                 ▲
                 │
                 │ FOREIGN KEY
                 │
┌──────────────────────────────────┐
│ health_insurance_facts_cleaned   │
│ ┌──────────────┐                 │
│ │  person_id   │ (FOREIGN KEY)   │
│ │  year        │                 │
│ └──────────────┘                 │
│ (Composite Primary Key)          │
└──────────────────────────────────┘
```

**Enforced by dbt test:**
```yaml
- name: person_id
  tests:
    - relationships:
        to: ref('health_insurance_person_cleaned')
        field: person_id
```

---

## 🎯 Data Quality Gates

### **Circuit Breaker Pattern**

Each cleaned model has quality gates that **FILTER OUT** invalid records:

```sql
WHERE row_rank = 1  -- Deduplication gate
  AND NOT (is_invalid_sleep_duration OR is_invalid_heart_rate OR is_invalid_age)
```

### **Quality Flag Pattern**

Invalid records are **FLAGGED** but not dropped in intermediate steps:

```sql
-- Validation flags for monitoring
CASE
  WHEN heart_rate_bpm < 30 OR heart_rate_bpm > 220 THEN TRUE
  ELSE FALSE
END AS is_invalid_heart_rate
```

This allows:
- ✅ Monitoring of data quality trends
- ✅ Investigation of why data is invalid
- ✅ Quarantine approach (can be exported for review)

---

## 📈 Data Volume Flow

```
SLEEP HEALTH:
374 raw → 374 staging → ~320 cleaned (14% reduction from deduplication)

SMARTWATCH:
10,001 raw → 10,001 staging → ~9,800 cleaned (2% reduction from validation)

INSURANCE PERSON:
124 raw → 124 staging → ~120 cleaned (3% reduction from validation)

INSURANCE FACTS:
365 raw → 365 staging → ~350 cleaned (4% reduction from validation)
```

---

## 🧪 Testing Hierarchy

```
┌─────────────────────────────────────────┐
│         RAW SOURCE TABLES               │
│         (No tests)                      │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         STAGING MODELS                  │
│         (Light tests: not_null)         │
└─────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│         CLEANED MODELS                  │
│         (Comprehensive tests: 39+)      │
│  • unique                               │
│  • not_null                             │
│  • accepted_values                      │
│  • relationships                        │
│  • range validations                    │
│  • custom business logic                │
└─────────────────────────────────────────┘
```

---

## 🚀 dbt DAG (Directed Acyclic Graph)

```
sources.yml
    │
    ├─── stg_sleep_health ───────────────► sleep_health_cleaned
    │
    ├─── stg_smartwatch_data ────────────► smartwatch_data_cleaned
    │
    ├─── stg_health_insurance_person ────► health_insurance_person_cleaned
    │                                               │
    │                                               │ (FK relationship)
    │                                               ▼
    └─── stg_health_insurance_facts ─────► health_insurance_facts_cleaned
```

View in dbt docs:
```bash
dbt docs generate
dbt docs serve
# Navigate to "Lineage" tab
```

---

## 📊 Transformation Summary by Layer

| Layer     | Transformations                                      | Quality                    |
|-----------|------------------------------------------------------|----------------------------|
| **Raw**   | • None (as-is from source)                           | • Unknown                  |
| **Staging**| • Type casting<br>• Column rename<br>• TRIM/LOWER   | • Basic schema validation  |
| **Cleaned**| • Deduplication<br>• NULL handling<br>• Validation<br>• Parsing<br>• Standardization | • 39+ automated tests<br>• Quality flags<br>• Circuit breakers |

---

**This lineage ensures full traceability from raw source to production tables! 🎯**
