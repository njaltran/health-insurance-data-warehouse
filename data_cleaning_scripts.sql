-- =====================================================================================================================
-- PRODUCTION-READY BIGQUERY DATA CLEANING SCRIPTS
-- =====================================================================================================================
-- Purpose: Clean raw health and insurance data following Data Engineering best practices
-- Author: Senior Data Engineer
-- Date: 2026-01-10
-- Tables Created:
--   1. raw_dataset.sleep_health_cleaned
--   2. raw_dataset.smartwatch_data_cleaned
--   3. raw_dataset.health_insurance_person_dim_cleaned
--   4. raw_dataset.health_insurance_facts_cleaned
-- =====================================================================================================================


-- =====================================================================================================================
-- TABLE 1: SLEEP HEALTH DATA CLEANING
-- =====================================================================================================================
-- Source: raw_dataset.raw_Sleep_Health_and_Lifestyle_Dataset
-- Target: raw_dataset.sleep_health_cleaned
-- Rows: 374 records
-- Issues Identified:
--   - Duplicate records (Person ID 81, 82, 4, 5, etc.)
--   - Column names with spaces (need snake_case)
--   - Blood Pressure stored as text (needs parsing to systolic/diastolic)
--   - Potential invalid values (heart rate < 30, negative sleep duration)
-- =====================================================================================================================

CREATE OR REPLACE TABLE `raw_dataset.sleep_health_cleaned` AS

WITH
-- Step 1: Standardize column names to snake_case and apply type casting
standardized_schema AS (
  SELECT
    -- Primary Key (will deduplicate later)
    SAFE_CAST(`Person ID` AS INT64) AS person_id,

    -- Demographics: Trim whitespace and normalize text to lowercase
    LOWER(TRIM(Gender)) AS gender,
    SAFE_CAST(Age AS INT64) AS age,
    LOWER(TRIM(Occupation)) AS occupation,

    -- Sleep Metrics: Ensure proper numeric types
    SAFE_CAST(`Sleep Duration` AS FLOAT64) AS sleep_duration_hours,
    SAFE_CAST(`Quality of Sleep` AS INT64) AS quality_of_sleep_score,

    -- Activity & Health Metrics
    SAFE_CAST(`Physical Activity Level` AS INT64) AS physical_activity_level,
    SAFE_CAST(`Stress Level` AS INT64) AS stress_level,
    LOWER(TRIM(`BMI Category`)) AS bmi_category,

    -- Blood Pressure: Keep original for parsing
    TRIM(`Blood Pressure`) AS blood_pressure_raw,

    -- Vital Signs
    SAFE_CAST(`Heart Rate` AS INT64) AS heart_rate_bpm,
    SAFE_CAST(`Daily Steps` AS INT64) AS daily_steps,

    -- Sleep Disorder: Handle NULL as "None"
    COALESCE(LOWER(TRIM(`Sleep Disorder`)), 'none') AS sleep_disorder,

    -- Metadata for audit trail
    CURRENT_TIMESTAMP() AS loaded_at
  FROM `raw_dataset.raw_Sleep_Health_and_Lifestyle_Dataset`
),

-- Step 2: Parse Blood Pressure into systolic and diastolic components
parsed_blood_pressure AS (
  SELECT
    *,
    -- Extract systolic (first number before '/')
    SAFE_CAST(SPLIT(blood_pressure_raw, '/')[SAFE_OFFSET(0)] AS INT64) AS blood_pressure_systolic,

    -- Extract diastolic (second number after '/')
    SAFE_CAST(SPLIT(blood_pressure_raw, '/')[SAFE_OFFSET(1)] AS INT64) AS blood_pressure_diastolic
  FROM standardized_schema
),

-- Step 3: Apply Data Quality Validation Rules
validated_data AS (
  SELECT
    *,
    -- Validation flags for impossible values
    CASE
      WHEN sleep_duration_hours < 0 OR sleep_duration_hours > 24 THEN TRUE
      ELSE FALSE
    END AS is_invalid_sleep_duration,

    CASE
      WHEN heart_rate_bpm < 30 OR heart_rate_bpm > 220 THEN TRUE
      ELSE FALSE
    END AS is_invalid_heart_rate,

    CASE
      WHEN age < 0 OR age > 120 THEN TRUE
      ELSE FALSE
    END AS is_invalid_age,

    CASE
      WHEN daily_steps < 0 OR daily_steps > 100000 THEN TRUE
      ELSE FALSE
    END AS is_invalid_steps,

    CASE
      WHEN blood_pressure_systolic < 70 OR blood_pressure_systolic > 250 THEN TRUE
      WHEN blood_pressure_diastolic < 40 OR blood_pressure_diastolic > 150 THEN TRUE
      ELSE FALSE
    END AS is_invalid_blood_pressure

  FROM parsed_blood_pressure
),

-- Step 4: Deduplication - Keep most recent record per person_id based on row order
-- Using ROW_NUMBER() to identify duplicates, keeping first occurrence
deduplicated_data AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY loaded_at) AS row_rank
  FROM validated_data
  WHERE person_id IS NOT NULL  -- Remove records with NULL primary key
)

-- Step 5: Final Selection - Only valid, deduplicated records
SELECT
  -- Primary Key
  person_id,

  -- Demographics
  gender,
  age,
  occupation,

  -- Sleep Metrics
  sleep_duration_hours,
  quality_of_sleep_score,

  -- Activity & Health
  physical_activity_level,
  stress_level,
  bmi_category,

  -- Blood Pressure (parsed)
  blood_pressure_systolic,
  blood_pressure_diastolic,

  -- Vital Signs
  heart_rate_bpm,
  daily_steps,

  -- Sleep Disorder
  sleep_disorder,

  -- Data Quality Flags (for monitoring and alerting)
  is_invalid_sleep_duration,
  is_invalid_heart_rate,
  is_invalid_age,
  is_invalid_steps,
  is_invalid_blood_pressure,

  -- Metadata
  loaded_at

FROM deduplicated_data
WHERE row_rank = 1  -- Deduplication: Keep only first occurrence of each person_id
  AND NOT (is_invalid_sleep_duration OR is_invalid_heart_rate OR is_invalid_age)  -- Filter out impossible values
ORDER BY person_id;


-- =====================================================================================================================
-- TABLE 2: SMARTWATCH DATA CLEANING
-- =====================================================================================================================
-- Source: raw_dataset.raw_smartwatch_health_data
-- Target: raw_dataset.smartwatch_data_cleaned
-- Rows: 10,001 records
-- Issues Identified:
--   - All columns stored as STRING (need proper numeric types)
--   - Column names with spaces and special characters
--   - NULL values in Stress Level
--   - Blood Oxygen > 100% (impossible)
--   - Negative or zero values in step count
-- =====================================================================================================================

CREATE OR REPLACE TABLE `raw_dataset.smartwatch_data_cleaned` AS

WITH
-- Step 1: Type Casting and Schema Standardization
standardized_schema AS (
  SELECT
    -- Primary Key
    TRIM(`User ID`) AS user_id,

    -- Vital Signs: SAFE_CAST to handle non-numeric strings gracefully
    SAFE_CAST(`Heart Rate_BPM` AS FLOAT64) AS heart_rate_bpm,
    SAFE_CAST(`Blood Oxygen Level %` AS FLOAT64) AS blood_oxygen_percent,

    -- Activity Metrics
    SAFE_CAST(`Step Count` AS FLOAT64) AS step_count,
    SAFE_CAST(`Sleep Duration hours` AS FLOAT64) AS sleep_duration_hours,

    -- Activity & Stress: Normalize text to lowercase
    LOWER(TRIM(`Activity Level`)) AS activity_level,
    LOWER(TRIM(`Stress Level`)) AS stress_level_raw,

    -- Metadata
    CURRENT_TIMESTAMP() AS loaded_at
  FROM `raw_dataset.raw_smartwatch_health_data`
),

-- Step 2: Handle Missing Values with Context-Aware Imputation
missing_value_handling AS (
  SELECT
    *,
    -- Replace NULL stress level with 'unknown' placeholder instead of dropping records
    COALESCE(stress_level_raw, 'unknown') AS stress_level,

    -- Flag missing values for data quality monitoring
    CASE WHEN stress_level_raw IS NULL THEN TRUE ELSE FALSE END AS is_missing_stress_level,
    CASE WHEN blood_oxygen_percent IS NULL THEN TRUE ELSE FALSE END AS is_missing_blood_oxygen

  FROM standardized_schema
),

-- Step 3: Data Validation - Flag Invalid Values
validated_data AS (
  SELECT
    *,
    -- Heart Rate Validation: Normal range 30-220 bpm
    CASE
      WHEN heart_rate_bpm < 30 OR heart_rate_bpm > 220 THEN TRUE
      ELSE FALSE
    END AS is_invalid_heart_rate,

    -- Blood Oxygen: Must be between 70% and 100%
    CASE
      WHEN blood_oxygen_percent < 70 OR blood_oxygen_percent > 100 THEN TRUE
      ELSE FALSE
    END AS is_invalid_blood_oxygen,

    -- Step Count: Cannot be negative
    CASE
      WHEN step_count < 0 OR step_count > 100000 THEN TRUE
      ELSE FALSE
    END AS is_invalid_step_count,

    -- Sleep Duration: Must be between 0 and 24 hours
    CASE
      WHEN sleep_duration_hours < 0 OR sleep_duration_hours > 24 THEN TRUE
      ELSE FALSE
    END AS is_invalid_sleep_duration

  FROM missing_value_handling
),

-- Step 4: Deduplication - Remove full-row duplicates using hash for float comparison
deduplicated_data AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY
        user_id,
        -- Convert FLOAT64 to STRING to avoid partitioning error
        CAST(ROUND(heart_rate_bpm, 2) AS STRING),
        CAST(ROUND(step_count, 2) AS STRING),
        CAST(ROUND(sleep_duration_hours, 2) AS STRING)
      ORDER BY loaded_at
    ) AS row_rank
  FROM validated_data
  WHERE user_id IS NOT NULL AND TRIM(user_id) != ''  -- Remove empty/null user IDs
)

-- Step 5: Final Selection - Clean data only
SELECT
  -- Primary Key
  user_id,

  -- Vital Signs
  heart_rate_bpm,
  blood_oxygen_percent,

  -- Activity Metrics
  step_count,
  sleep_duration_hours,

  -- Activity & Stress
  activity_level,
  stress_level,

  -- Data Quality Flags
  is_missing_stress_level,
  is_missing_blood_oxygen,
  is_invalid_heart_rate,
  is_invalid_blood_oxygen,
  is_invalid_step_count,
  is_invalid_sleep_duration,

  -- Metadata
  loaded_at

FROM deduplicated_data
WHERE row_rank = 1  -- Deduplication
  AND NOT (is_invalid_heart_rate OR is_invalid_blood_oxygen OR is_invalid_step_count OR is_invalid_sleep_duration)  -- Filter impossible values
ORDER BY user_id;


-- =====================================================================================================================
-- TABLE 3: HEALTH INSURANCE PERSON DIMENSION CLEANING
-- =====================================================================================================================
-- Source: raw_dataset.raw_health_insurance_person_dim
-- Target: raw_dataset.health_insurance_person_dim_cleaned
-- Rows: 124 records
-- Issues Identified:
--   - Inconsistent date formats (YYYY-MM-DD, DD-MM-YYYY, MM/DD/YYYY, DD.MM.YYYY)
--   - Gender values not standardized (m, f, male, female, MALE, other)
--   - Insurance status has mixed case (ACTIVE, active, pending, inactive, cancelled)
--   - Whitespace in Person_id and addresses
--   - Wealth bracket has mixed case (LOW, high, MEDIUM)
--   - Future dates in birthdate and sign-up dates
-- =====================================================================================================================

CREATE OR REPLACE TABLE `raw_dataset.health_insurance_person_dim_cleaned` AS

WITH
-- Step 1: Standardize Column Names and Trim Whitespace
standardized_schema AS (
  SELECT
    -- Primary Key: Trim whitespace
    TRIM(Person_id) AS person_id,

    -- Demographics
    TRIM(birthdate) AS birthdate_raw,
    TRIM(address) AS address_raw,
    TRIM(gender) AS gender_raw,
    TRIM(family_status) AS family_status_raw,

    -- Insurance Details
    TRIM(insurance_status) AS insurance_status_raw,
    TRIM(insurance_sign_up_date) AS insurance_sign_up_date_raw,

    -- Socioeconomic
    TRIM(occupational_category) AS occupational_category_raw,
    TRIM(wealth_bracket) AS wealth_bracket_raw,

    -- Metadata
    CURRENT_TIMESTAMP() AS loaded_at
  FROM `raw_dataset.raw_health_insurance_person_dim`
),

-- Step 2: Parse Dates - Handle Multiple Formats
parsed_dates AS (
  SELECT
    *,
    -- Birthdate: Try multiple date formats, return NULL if all fail
    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', birthdate_raw),       -- Format: 1991-03-27
      SAFE.PARSE_DATE('%d-%m-%Y', birthdate_raw),       -- Format: 23-01-1994
      SAFE.PARSE_DATE('%m/%d/%Y', birthdate_raw),       -- Format: 06/30/1948
      SAFE.PARSE_DATE('%d/%m/%Y', birthdate_raw),       -- Format: 19/01/1936
      SAFE.PARSE_DATE('%d.%m.%Y', birthdate_raw)        -- Format: 11.11.2006
    ) AS birthdate,

    -- Insurance Sign-Up Date: Try multiple formats
    COALESCE(
      SAFE.PARSE_DATE('%Y-%m-%d', insurance_sign_up_date_raw),   -- Format: 2000-12-15
      SAFE.PARSE_DATE('%d.%m.%Y', insurance_sign_up_date_raw),   -- Format: 11.11.2006
      SAFE.PARSE_DATE('%d/%m/%y', insurance_sign_up_date_raw),   -- Format: 17/02/11
      SAFE.PARSE_DATE('%m/%d/%y', insurance_sign_up_date_raw)    -- Format: 01/11/05
    ) AS insurance_sign_up_date

  FROM standardized_schema
),

-- Step 3: Standardize Categorical Values
standardized_categories AS (
  SELECT
    *,
    -- Gender: Map all variations to standard values (male, female, other)
    CASE
      WHEN LOWER(gender_raw) IN ('m', 'male') THEN 'male'
      WHEN LOWER(gender_raw) IN ('f', 'female') THEN 'female'
      WHEN LOWER(gender_raw) = 'other' THEN 'other'
      ELSE 'unknown'
    END AS gender,

    -- Family Status: Normalize to uppercase
    UPPER(family_status_raw) AS family_status,

    -- Insurance Status: Normalize to uppercase
    UPPER(insurance_status_raw) AS insurance_status,

    -- Occupational Category: Lowercase and trim
    LOWER(occupational_category_raw) AS occupational_category,

    -- Wealth Bracket: Normalize to uppercase
    UPPER(wealth_bracket_raw) AS wealth_bracket,

    -- Address: Normalize case for consistency
    LOWER(address_raw) AS address

  FROM parsed_dates
),

-- Step 4: Data Validation - Filter Future Dates and Invalid Values
validated_data AS (
  SELECT
    *,
    -- Calculate age from birthdate
    DATE_DIFF(CURRENT_DATE(), birthdate, YEAR) AS age,

    -- Validation flags
    CASE
      WHEN birthdate > CURRENT_DATE() THEN TRUE
      WHEN birthdate < DATE('1900-01-01') THEN TRUE
      ELSE FALSE
    END AS is_invalid_birthdate,

    CASE
      WHEN insurance_sign_up_date > CURRENT_DATE() THEN TRUE
      WHEN insurance_sign_up_date < DATE('1950-01-01') THEN TRUE
      ELSE FALSE
    END AS is_invalid_signup_date,

    CASE
      WHEN DATE_DIFF(CURRENT_DATE(), birthdate, YEAR) < 0 OR DATE_DIFF(CURRENT_DATE(), birthdate, YEAR) > 120 THEN TRUE
      ELSE FALSE
    END AS is_invalid_age

  FROM standardized_categories
),

-- Step 5: Deduplication - Keep only unique person_id records
deduplicated_data AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY loaded_at) AS row_rank
  FROM validated_data
  WHERE person_id IS NOT NULL AND person_id != ''  -- Remove empty person IDs
)

-- Step 6: Final Selection
SELECT
  -- Primary Key
  person_id,

  -- Demographics
  birthdate,
  age,
  gender,
  family_status,
  address,

  -- Insurance Details
  insurance_status,
  insurance_sign_up_date,

  -- Socioeconomic
  occupational_category,
  wealth_bracket,

  -- Data Quality Flags
  is_invalid_birthdate,
  is_invalid_signup_date,
  is_invalid_age,

  -- Metadata
  loaded_at

FROM deduplicated_data
WHERE row_rank = 1  -- Deduplication
  AND NOT (is_invalid_birthdate OR is_invalid_age)  -- Filter invalid records
ORDER BY person_id;


-- =====================================================================================================================
-- TABLE 4: HEALTH INSURANCE FACTS CLEANING
-- =====================================================================================================================
-- Source: raw_dataset.health_insurance_insurance_facts_raw
-- Target: raw_dataset.health_insurance_facts_cleaned
-- Rows: 365 records
-- Issues Identified:
--   - Whitespace in Person_id field
--   - annual_doctor_visits and annual_cost_to_insurance stored as STRING with NULL values
--   - Negative costs (impossible)
--   - Year validation (future years, too old years)
-- =====================================================================================================================

CREATE OR REPLACE TABLE `raw_dataset.health_insurance_facts_cleaned` AS

WITH
-- Step 1: Schema Standardization and Type Casting
standardized_schema AS (
  SELECT
    -- Foreign Key to Person Dimension: Trim whitespace
    TRIM(Person_id) AS person_id,

    -- Financial Metrics: Already FLOAT, but validate
    insurance_cost_year,

    -- Activity Metrics: Cast from STRING to numeric
    SAFE_CAST(annual_doctor_visits AS INT64) AS annual_doctor_visits,
    SAFE_CAST(annual_cost_to_insurance AS FLOAT64) AS annual_cost_to_insurance,

    -- Time Dimension
    SAFE_CAST(year AS INT64) AS year,

    -- Metadata
    CURRENT_TIMESTAMP() AS loaded_at
  FROM `raw_dataset.health_insurance_insurance_facts_raw`
),

-- Step 2: Handle Missing Values - Replace NULL with 0 for metrics
missing_value_handling AS (
  SELECT
    *,
    -- For fact table metrics, NULL often means "no activity" = 0
    COALESCE(annual_doctor_visits, 0) AS doctor_visits_count,
    COALESCE(annual_cost_to_insurance, 0.0) AS cost_to_insurance_amount,

    -- Track which values were missing for data quality monitoring
    CASE WHEN annual_doctor_visits IS NULL THEN TRUE ELSE FALSE END AS is_missing_doctor_visits,
    CASE WHEN annual_cost_to_insurance IS NULL THEN TRUE ELSE FALSE END AS is_missing_insurance_cost

  FROM standardized_schema
),

-- Step 3: Data Validation
validated_data AS (
  SELECT
    *,
    -- Validate costs are non-negative
    CASE
      WHEN insurance_cost_year < 0 THEN TRUE
      ELSE FALSE
    END AS is_invalid_cost_year,

    CASE
      WHEN cost_to_insurance_amount < 0 THEN TRUE
      ELSE FALSE
    END AS is_invalid_cost_to_insurance,

    -- Validate doctor visits are reasonable
    CASE
      WHEN doctor_visits_count < 0 OR doctor_visits_count > 365 THEN TRUE
      ELSE FALSE
    END AS is_invalid_doctor_visits,

    -- Validate year is reasonable (between 2000 and current year)
    CASE
      WHEN year < 2000 OR year > EXTRACT(YEAR FROM CURRENT_DATE()) THEN TRUE
      ELSE FALSE
    END AS is_invalid_year

  FROM missing_value_handling
),

-- Step 4: Deduplication - Remove duplicates based on person_id + year combination
deduplicated_data AS (
  SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY person_id, year ORDER BY loaded_at) AS row_rank
  FROM validated_data
  WHERE person_id IS NOT NULL AND person_id != ''  -- Remove empty person IDs
    AND year IS NOT NULL  -- Year is required for time-based facts
)

-- Step 5: Final Selection
SELECT
  -- Foreign Key
  person_id,

  -- Time Dimension
  year,

  -- Financial Metrics
  insurance_cost_year,
  cost_to_insurance_amount,

  -- Activity Metrics
  doctor_visits_count,

  -- Data Quality Flags
  is_missing_doctor_visits,
  is_missing_insurance_cost,
  is_invalid_cost_year,
  is_invalid_cost_to_insurance,
  is_invalid_doctor_visits,
  is_invalid_year,

  -- Metadata
  loaded_at

FROM deduplicated_data
WHERE row_rank = 1  -- Deduplication
  AND NOT (is_invalid_cost_year OR is_invalid_cost_to_insurance OR is_invalid_doctor_visits OR is_invalid_year)  -- Filter invalid records
ORDER BY person_id, year;


-- =====================================================================================================================
-- DATA QUALITY SUMMARY QUERIES
-- =====================================================================================================================
-- Run these queries after executing the cleaning scripts to validate results

-- Check row counts before/after cleaning
SELECT
  'sleep_health' AS table_name,
  (SELECT COUNT(*) FROM `raw_dataset.raw_Sleep_Health_and_Lifestyle_Dataset`) AS raw_count,
  (SELECT COUNT(*) FROM `raw_dataset.sleep_health_cleaned`) AS cleaned_count
UNION ALL
SELECT
  'smartwatch_data',
  (SELECT COUNT(*) FROM `raw_dataset.raw_smartwatch_health_data`),
  (SELECT COUNT(*) FROM `raw_dataset.smartwatch_data_cleaned`)
UNION ALL
SELECT
  'health_insurance_person_dim',
  (SELECT COUNT(*) FROM `raw_dataset.raw_health_insurance_person_dim`),
  (SELECT COUNT(*) FROM `raw_dataset.health_insurance_person_dim_cleaned`)
UNION ALL
SELECT
  'health_insurance_facts',
  (SELECT COUNT(*) FROM `raw_dataset.health_insurance_insurance_facts_raw`),
  (SELECT COUNT(*) FROM `raw_dataset.health_insurance_facts_cleaned`);

-- Check data quality flags in cleaned tables
SELECT
  'sleep_health' AS table_name,
  COUNTIF(is_invalid_sleep_duration) AS invalid_sleep_duration_count,
  COUNTIF(is_invalid_heart_rate) AS invalid_heart_rate_count,
  COUNTIF(is_invalid_age) AS invalid_age_count
FROM `raw_dataset.sleep_health_cleaned`;

SELECT
  'smartwatch_data' AS table_name,
  COUNTIF(is_missing_stress_level) AS missing_stress_level_count,
  COUNTIF(is_missing_blood_oxygen) AS missing_blood_oxygen_count
FROM `raw_dataset.smartwatch_data_cleaned`;

-- =====================================================================================================================
-- END OF SCRIPT
-- =====================================================================================================================
