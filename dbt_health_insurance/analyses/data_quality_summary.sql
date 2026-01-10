/*
    Data Quality Summary Report

    This analysis provides a comprehensive overview of data quality metrics
    across all cleaned tables. Run with: dbt compile --select analyses

    Execute the compiled SQL in BigQuery to generate the report.
*/

-- =====================================================================================================================
-- SLEEP HEALTH DATA QUALITY SUMMARY
-- =====================================================================================================================

WITH sleep_health_quality AS (
    SELECT
        'sleep_health_cleaned' AS table_name,
        COUNT(*) AS total_records,
        COUNTIF(is_invalid_sleep_duration = FALSE) AS valid_sleep_duration,
        COUNTIF(is_invalid_heart_rate = FALSE) AS valid_heart_rate,
        COUNTIF(is_invalid_age = FALSE) AS valid_age,
        COUNTIF(is_invalid_steps = FALSE) AS valid_steps,
        COUNTIF(is_invalid_blood_pressure = FALSE) AS valid_blood_pressure,

        -- Calculate percentages
        ROUND(COUNTIF(is_invalid_sleep_duration = FALSE) / COUNT(*) * 100, 2) AS pct_valid_sleep_duration,
        ROUND(COUNTIF(is_invalid_heart_rate = FALSE) / COUNT(*) * 100, 2) AS pct_valid_heart_rate,
        ROUND(COUNTIF(is_invalid_age = FALSE) / COUNT(*) * 100, 2) AS pct_valid_age
    FROM {{ ref('sleep_health_cleaned') }}
),

-- =====================================================================================================================
-- SMARTWATCH DATA QUALITY SUMMARY
-- =====================================================================================================================

smartwatch_quality AS (
    SELECT
        'smartwatch_data_cleaned' AS table_name,
        COUNT(*) AS total_records,
        COUNTIF(is_missing_stress_level) AS missing_stress_level_count,
        COUNTIF(is_missing_blood_oxygen) AS missing_blood_oxygen_count,
        COUNTIF(is_invalid_heart_rate = FALSE) AS valid_heart_rate,
        COUNTIF(is_invalid_blood_oxygen = FALSE) AS valid_blood_oxygen,

        -- Calculate percentages
        ROUND(COUNTIF(is_missing_stress_level) / COUNT(*) * 100, 2) AS pct_missing_stress,
        ROUND(COUNTIF(is_missing_blood_oxygen) / COUNT(*) * 100, 2) AS pct_missing_oxygen,
        ROUND(COUNTIF(is_invalid_heart_rate = FALSE) / COUNT(*) * 100, 2) AS pct_valid_heart_rate
    FROM {{ ref('smartwatch_data_cleaned') }}
),

-- =====================================================================================================================
-- INSURANCE PERSON DATA QUALITY SUMMARY
-- =====================================================================================================================

insurance_person_quality AS (
    SELECT
        'health_insurance_person_cleaned' AS table_name,
        COUNT(*) AS total_records,
        COUNT(DISTINCT person_id) AS unique_persons,
        COUNTIF(is_invalid_birthdate = FALSE) AS valid_birthdate,
        COUNTIF(is_invalid_age = FALSE) AS valid_age,
        COUNTIF(is_invalid_signup_date = FALSE) AS valid_signup_date,

        -- Age distribution
        MIN(age) AS min_age,
        MAX(age) AS max_age,
        ROUND(AVG(age), 1) AS avg_age,

        -- Calculate percentages
        ROUND(COUNTIF(is_invalid_birthdate = FALSE) / COUNT(*) * 100, 2) AS pct_valid_birthdate
    FROM {{ ref('health_insurance_person_cleaned') }}
),

-- =====================================================================================================================
-- INSURANCE FACTS DATA QUALITY SUMMARY
-- =====================================================================================================================

insurance_facts_quality AS (
    SELECT
        'health_insurance_facts_cleaned' AS table_name,
        COUNT(*) AS total_records,
        COUNTIF(is_missing_doctor_visits) AS missing_doctor_visits_count,
        COUNTIF(is_missing_insurance_cost) AS missing_insurance_cost_count,
        COUNTIF(is_invalid_cost_year = FALSE) AS valid_cost_year,
        COUNTIF(is_invalid_doctor_visits = FALSE) AS valid_doctor_visits,

        -- Financial summaries
        ROUND(AVG(insurance_cost_year), 2) AS avg_annual_cost,
        ROUND(AVG(cost_to_insurance_amount), 2) AS avg_cost_to_insurance,
        ROUND(AVG(doctor_visits_count), 1) AS avg_doctor_visits,

        -- Calculate percentages
        ROUND(COUNTIF(is_missing_doctor_visits) / COUNT(*) * 100, 2) AS pct_missing_visits
    FROM {{ ref('health_insurance_facts_cleaned') }}
)

-- =====================================================================================================================
-- COMBINED SUMMARY REPORT
-- =====================================================================================================================

SELECT
    table_name,
    total_records,
    CONCAT(
        'Sleep Duration: ', pct_valid_sleep_duration, '% valid, ',
        'Heart Rate: ', pct_valid_heart_rate, '% valid, ',
        'Age: ', pct_valid_age, '% valid'
    ) AS quality_summary
FROM sleep_health_quality

UNION ALL

SELECT
    table_name,
    total_records,
    CONCAT(
        'Missing Stress: ', pct_missing_stress, '%, ',
        'Missing Oxygen: ', pct_missing_oxygen, '%, ',
        'Valid Heart Rate: ', pct_valid_heart_rate, '%'
    ) AS quality_summary
FROM smartwatch_quality

UNION ALL

SELECT
    table_name,
    total_records,
    CONCAT(
        'Unique Persons: ', unique_persons, ', ',
        'Valid Birthdate: ', pct_valid_birthdate, '%, ',
        'Age Range: ', min_age, '-', max_age, ' (avg: ', avg_age, ')'
    ) AS quality_summary
FROM insurance_person_quality

UNION ALL

SELECT
    table_name,
    total_records,
    CONCAT(
        'Missing Visits: ', pct_missing_visits, '%, ',
        'Avg Annual Cost: $', avg_annual_cost, ', ',
        'Avg Doctor Visits: ', avg_doctor_visits
    ) AS quality_summary
FROM insurance_facts_quality

ORDER BY table_name;
