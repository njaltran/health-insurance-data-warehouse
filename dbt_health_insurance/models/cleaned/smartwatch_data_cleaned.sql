{{
  config(
    materialized='table',
    tags=['cleaned', 'production', 'smartwatch']
  )
}}

/*
    Cleaned Smartwatch Data Model
    Source: {{ ref('stg_smartwatch_data') }}

    Transformations Applied:
    1. Handle NULL stress levels (use 'unknown' placeholder)
    2. Validate vital signs ranges (heart rate, blood oxygen)
    3. Validate activity metrics (step count, sleep duration)
    4. Deduplicate full-row duplicates
    5. Filter impossible values

    Data Quality Standards:
    - All STRING columns cast to proper numeric types
    - Missing values flagged with is_missing_* columns
    - Range validation for health metrics
    - Deduplication based on composite key
*/

WITH

-- Step 1: Handle Missing Values
missing_value_handling AS (
    SELECT
        *,
        -- Replace NULL stress level with 'unknown' placeholder
        COALESCE(stress_level, 'unknown') AS stress_level_clean,

        -- Flag missing values for monitoring
        CASE WHEN stress_level IS NULL THEN TRUE ELSE FALSE END AS is_missing_stress_level,
        CASE WHEN blood_oxygen_percent IS NULL THEN TRUE ELSE FALSE END AS is_missing_blood_oxygen

    FROM {{ ref('stg_smartwatch_data') }}
),

-- Step 2: Data Validation
validated_data AS (
    SELECT
        *,
        -- Heart Rate Validation (30-220 bpm)
        CASE
            WHEN heart_rate_bpm < {{ var('min_heart_rate') }} OR heart_rate_bpm > {{ var('max_heart_rate') }} THEN TRUE
            ELSE FALSE
        END AS is_invalid_heart_rate,

        -- Blood Oxygen Validation (70-100%)
        CASE
            WHEN blood_oxygen_percent < {{ var('min_blood_oxygen') }} OR blood_oxygen_percent > {{ var('max_blood_oxygen') }} THEN TRUE
            ELSE FALSE
        END AS is_invalid_blood_oxygen,

        -- Step Count Validation
        CASE
            WHEN step_count < 0 OR step_count > 100000 THEN TRUE
            ELSE FALSE
        END AS is_invalid_step_count,

        -- Sleep Duration Validation (0-24 hours)
        CASE
            WHEN sleep_duration_hours < 0 OR sleep_duration_hours > 24 THEN TRUE
            ELSE FALSE
        END AS is_invalid_sleep_duration

    FROM missing_value_handling
),

-- Step 3: Deduplication - Remove full-row duplicates using hash for float comparison
deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY
                user_id,
                -- Use CAST to INT64 or hash to avoid FLOAT64 partitioning error
                CAST(ROUND(heart_rate_bpm, 2) AS STRING),
                CAST(ROUND(step_count, 2) AS STRING),
                CAST(ROUND(sleep_duration_hours, 2) AS STRING)
            ORDER BY loaded_at DESC
        ) AS row_rank
    FROM validated_data
    WHERE user_id IS NOT NULL
      AND TRIM(user_id) != ''
)

-- Step 4: Final Selection - Clean data only
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
    stress_level_clean AS stress_level,

    -- Data Quality Flags
    is_missing_stress_level,
    is_missing_blood_oxygen,
    is_invalid_heart_rate,
    is_invalid_blood_oxygen,
    is_invalid_step_count,
    is_invalid_sleep_duration,

    -- Metadata
    loaded_at

FROM deduplicated
WHERE row_rank = 1  -- Deduplication
  AND NOT (is_invalid_heart_rate OR is_invalid_blood_oxygen OR is_invalid_step_count OR is_invalid_sleep_duration)
