{{
  config(
    materialized='table',
    tags=['cleaned', 'production', 'sleep_health']
  )
}}

/*
    Cleaned Sleep Health Data Model
    Source: {{ ref('stg_sleep_health') }}

    Transformations Applied:
    1. Parse blood pressure into systolic/diastolic
    2. Handle NULL values (sleep_disorder)
    3. Validate ranges (heart rate, sleep duration, age)
    4. Deduplicate based on person_id
    5. Filter invalid records

    Data Quality Standards:
    - Schema-on-Read with proper type casting
    - Deduplication by most recent record
    - Value validation with quality flags
    - Standardized categorical values
*/

WITH

-- Step 1: Parse Blood Pressure
parsed_blood_pressure AS (
    SELECT
        *,
        -- Extract systolic (first number before '/')
        SAFE_CAST(SPLIT(blood_pressure_raw, '/')[SAFE_OFFSET(0)] AS INT64) AS blood_pressure_systolic,

        -- Extract diastolic (second number after '/')
        SAFE_CAST(SPLIT(blood_pressure_raw, '/')[SAFE_OFFSET(1)] AS INT64) AS blood_pressure_diastolic
    FROM {{ ref('stg_sleep_health') }}
),

-- Step 2: Handle NULL values and standardize
null_handling AS (
    SELECT
        *,
        -- Sleep disorder: NULL means no disorder
        COALESCE(sleep_disorder, 'none') AS sleep_disorder_clean
    FROM parsed_blood_pressure
),

-- Step 3: Data Quality Validation
validated_data AS (
    SELECT
        *,
        -- Validation: Sleep Duration (0-24 hours)
        CASE
            WHEN sleep_duration_hours < 0 OR sleep_duration_hours > 24 THEN TRUE
            ELSE FALSE
        END AS is_invalid_sleep_duration,

        -- Validation: Heart Rate (30-220 bpm)
        CASE
            WHEN heart_rate_bpm < {{ var('min_heart_rate') }} OR heart_rate_bpm > {{ var('max_heart_rate') }} THEN TRUE
            ELSE FALSE
        END AS is_invalid_heart_rate,

        -- Validation: Age (0-120 years)
        CASE
            WHEN age < 0 OR age > {{ var('max_age') }} THEN TRUE
            ELSE FALSE
        END AS is_invalid_age,

        -- Validation: Daily Steps
        CASE
            WHEN daily_steps < 0 OR daily_steps > 100000 THEN TRUE
            ELSE FALSE
        END AS is_invalid_steps,

        -- Validation: Blood Pressure
        CASE
            WHEN blood_pressure_systolic < 70 OR blood_pressure_systolic > 250 THEN TRUE
            WHEN blood_pressure_diastolic < 40 OR blood_pressure_diastolic > 150 THEN TRUE
            ELSE FALSE
        END AS is_invalid_blood_pressure

    FROM null_handling
),

-- Step 4: Deduplication - Keep most recent record per person_id
deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY loaded_at DESC) AS row_rank
    FROM validated_data
    WHERE person_id IS NOT NULL
)

-- Step 5: Final Selection - Only clean, deduplicated records
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
    sleep_disorder_clean AS sleep_disorder,

    -- Data Quality Flags
    is_invalid_sleep_duration,
    is_invalid_heart_rate,
    is_invalid_age,
    is_invalid_steps,
    is_invalid_blood_pressure,

    -- Metadata
    loaded_at

FROM deduplicated
WHERE row_rank = 1  -- Deduplication
  AND NOT (is_invalid_sleep_duration OR is_invalid_heart_rate OR is_invalid_age)  -- Filter invalid records
