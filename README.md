# Health Insurance Data Warehouse Project

Production-ready data cleaning and transformation pipelines for health and insurance data, built with dbt and BigQuery.

[![dbt](https://img.shields.io/badge/dbt-1.7+-orange.svg)](https://www.getdbt.com/)
[![BigQuery](https://img.shields.io/badge/BigQuery-enabled-blue.svg)](https://cloud.google.com/bigquery)
[![Data Engineering](https://img.shields.io/badge/Data%20Engineering-Best%20Practices-green.svg)](https://github.com)

## 📋 Project Overview

This project implements a complete ELT (Extract-Load-Transform) data pipeline that cleans and validates health and insurance data following modern data engineering best practices from HWR Berlin's Data Warehouse course.

### **Key Features**

✅ **39+ Automated Data Quality Tests**
✅ **Production-Ready dbt Models** (Staging + Cleaned layers)
✅ **Comprehensive Data Cleaning** (Deduplication, validation, standardization)
✅ **BigQuery Optimized** (ELT pattern, schema-on-read)
✅ **Full Documentation** (Data lineage, quality reports, troubleshooting)

---

## 🏗️ Architecture

```
Raw Data (BigQuery)
    ↓
Staging Layer (Views) - Light transformation
    ↓
Cleaned Layer (Tables) - Full data quality
    ↓
BI Tools / ML Models / Analytics
```

### **Data Pipeline**

- **4 Source Tables** → **4 Staging Views** → **4 Cleaned Tables**
- **~10,000+ rows** transformed with quality validation
- **Data Quality Flags** for monitoring and observability

---

## 📊 Tables Created

| Table | Description | Rows | Tests |
|-------|-------------|------|-------|
| `sleep_health_cleaned` | Sleep & lifestyle metrics | ~320 | 11 |
| `smartwatch_data_cleaned` | Smartwatch health data | ~9,800 | 7 |
| `health_insurance_person_cleaned` | Person dimension | ~120 | 12 |
| `health_insurance_facts_cleaned` | Insurance facts | ~350 | 9 |

---

## 🚀 Quick Start

### **Prerequisites**

```bash
# Install dbt with BigQuery adapter
pip install dbt-bigquery

# Verify installation
dbt --version
```

### **Setup**

1. **Clone the repository:**
```bash
git clone <your-repo-url>
cd final_project
```

2. **Configure BigQuery connection:**

Create `~/.dbt/profiles.yml`:

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

3. **Install dbt packages:**
```bash
cd dbt_health_insurance
dbt deps
```

4. **Test connection:**
```bash
dbt debug
```

### **Run the Pipeline**

```bash
# Run all models (creates staging views + cleaned tables)
dbt run

# Run tests (executes 39+ quality checks)
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

---

## 📁 Project Structure

```
final_project/
├── dbt_health_insurance/          # dbt project
│   ├── models/
│   │   ├── staging/               # Staging layer (views)
│   │   │   ├── stg_sleep_health.sql
│   │   │   ├── stg_smartwatch_data.sql
│   │   │   ├── stg_health_insurance_person.sql
│   │   │   ├── stg_health_insurance_facts.sql
│   │   │   └── sources.yml
│   │   └── cleaned/               # Cleaned layer (tables)
│   │       ├── sleep_health_cleaned.sql
│   │       ├── smartwatch_data_cleaned.sql
│   │       ├── health_insurance_person_cleaned.sql
│   │       ├── health_insurance_facts_cleaned.sql
│   │       └── schema.yml         # Tests & documentation
│   ├── macros/                    # Custom SQL macros
│   ├── analyses/                  # Data quality reports
│   ├── dbt_project.yml            # Project config
│   ├── packages.yml               # Dependencies
│   ├── README.md                  # dbt documentation
│   ├── QUICKSTART.md              # Quick start guide
│   ├── DATA_LINEAGE.md            # Lineage diagrams
│   └── TROUBLESHOOTING.md         # Common issues
├── context/                       # Expert dossiers (reference)
├── data_cleaning_scripts.sql      # Original SQL scripts
├── PROJECT_SUMMARY.md             # Project overview
└── README.md                      # This file
```

---

## 🔧 Data Engineering Standards

This project implements the following best practices:

### **1. Schema & Types**
- ✅ SAFE_CAST to appropriate types (INT64, FLOAT64, DATE)
- ✅ Column names standardized to `snake_case`
- ✅ Complex field parsing (blood pressure: "131/86" → systolic/diastolic)

### **2. Deduplication**
- ✅ Full-row duplicate removal using `ROW_NUMBER()`
- ✅ Primary key deduplication (person_id, user_id)
- ✅ Composite key deduplication (person_id + year)

### **3. Missing Values**
- ✅ Context-aware handling (dimensions: 'unknown', metrics: 0)
- ✅ `is_missing_*` flags for monitoring

### **4. Value Validation**
- ✅ Range checks (heart rate: 30-220, age: 0-120, etc.)
- ✅ Future date filtering
- ✅ Negative value removal
- ✅ `is_invalid_*` flags for tracking

### **5. Standardization**
- ✅ Text normalization (TRIM, LOWER, UPPER)
- ✅ Multi-format date parsing (5 different formats)
- ✅ Categorical value mapping (gender, status codes)

---

## 🧪 Testing

The project includes **39+ automated data quality tests**:

```bash
# Run all tests
dbt test

# Test specific model
dbt test --select sleep_health_cleaned

# Run only uniqueness tests
dbt test --select test_type:unique
```

**Test Coverage:**
- Primary key uniqueness
- Referential integrity (foreign keys)
- Accepted values (categorical fields)
- Range validations (numeric fields)
- NOT NULL constraints
- Composite key uniqueness

---

## 📈 Data Quality Improvements

| Metric | Before (Raw) | After (Cleaned) |
|--------|--------------|-----------------|
| Duplicates | Yes | ❌ Removed |
| Date Formats | 5 different | ✅ Standardized |
| Gender Values | m, f, male, MALE, etc. | ✅ Standardized |
| NULL Handling | No strategy | ✅ Context-aware |
| Invalid Values | Heart rate=0, Age>150 | ✅ Filtered |
| Type Safety | All STRING | ✅ Proper types |
| Blood Pressure | Text "131/86" | ✅ Parsed (systolic/diastolic) |

---

## 📚 Documentation

- **[dbt README](dbt_health_insurance/README.md)** - Comprehensive dbt documentation
- **[Quick Start Guide](dbt_health_insurance/QUICKSTART.md)** - Get started in 5 minutes
- **[Data Lineage](dbt_health_insurance/DATA_LINEAGE.md)** - Visual data flow diagrams
- **[Troubleshooting](dbt_health_insurance/TROUBLESHOOTING.md)** - Common issues & solutions
- **[Project Summary](PROJECT_SUMMARY.md)** - Complete project overview

---

## 🔍 Data Lineage

View the complete data flow:

```bash
dbt docs generate
dbt docs serve
# Navigate to "Lineage" tab
```

Or see [DATA_LINEAGE.md](dbt_health_insurance/DATA_LINEAGE.md) for visual diagrams.

---

## 🎯 Output

After running `dbt run`, cleaned data is available at:

```
Project: dw-health-insurance-bipm
└── Dataset: raw_dataset
    └── Schema: cleaned
        ├── sleep_health_cleaned
        ├── smartwatch_data_cleaned
        ├── health_insurance_person_cleaned
        └── health_insurance_facts_cleaned
```

Query in BigQuery:
```sql
SELECT * FROM `dw-health-insurance-bipm.raw_dataset.cleaned.sleep_health_cleaned`;
```

---

## 🤝 Contributing

This is an academic project for HWR Berlin's Data Warehouse course. For improvements:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -m 'Add improvement'`)
4. Push to branch (`git push origin feature/improvement`)
5. Open a Pull Request

---

## 📖 References

This project implements concepts from:

- **Expert Dossier 1:** Modern Data Architecture & Data Serving
- **Expert Dossier 2:** Extraction Strategies & CDC
- **Expert Dossier 3:** Transformation Logic & Data Quality Engineering
- **Expert Dossier 4:** Loading Strategies & History Management

### **Resources**
- [dbt Documentation](https://docs.getdbt.com/)
- [BigQuery Best Practices](https://cloud.google.com/bigquery/docs/best-practices)
- [Data Quality Dimensions](https://www.montecarlodata.com/blog-6-data-quality-dimensions-examples/)

---

## 📄 License

This project is for educational purposes as part of HWR Berlin's Data Warehouse course.

---

## 👤 Author

**Student:** Nikolas Jackaltran
**Institution:** HWR Berlin
**Course:** Data Warehouse
**Date:** January 2026

---

## 🎓 Acknowledgments

- Prof. Dr. Sebastian Fischer (HWR Berlin)
- Expert Dossiers 1-4 (Course Materials)
- dbt Labs (dbt framework)
- Google Cloud (BigQuery)

---

**Built with ❤️ following Modern Data Engineering Best Practices**
