{{
  config(
    materialized='view',
    tags=['staging', 'sleep_health']
  )
}}

/*
    Staging model for Sleep Health and Lifestyle Dataset
    Source: raw_dataset.raw_Sleep_Health_and_Lifestyle_Dataset
    Purpose: Light transformation - standardize column names and types only
*/

SELECT
    -- Primary Key
    SAFE_CAST(`Person ID` AS INT64) AS person_id,

    -- Demographics
    LOWER(TRIM(Gender)) AS gender,
    SAFE_CAST(Age AS INT64) AS age,
    LOWER(TRIM(Occupation)) AS occupation,

    -- Sleep Metrics
    SAFE_CAST(`Sleep Duration` AS FLOAT64) AS sleep_duration_hours,
    SAFE_CAST(`Quality of Sleep` AS INT64) AS quality_of_sleep_score,

    -- Activity & Health Metrics
    SAFE_CAST(`Physical Activity Level` AS INT64) AS physical_activity_level,
    SAFE_CAST(`Stress Level` AS INT64) AS stress_level,
    LOWER(TRIM(`BMI Category`)) AS bmi_category,

    -- Blood Pressure (raw, will parse in cleaned layer)
    TRIM(`Blood Pressure`) AS blood_pressure_raw,

    -- Vital Signs
    SAFE_CAST(`Heart Rate` AS INT64) AS heart_rate_bpm,
    SAFE_CAST(`Daily Steps` AS INT64) AS daily_steps,

    -- Sleep Disorder
    LOWER(TRIM(`Sleep Disorder`)) AS sleep_disorder,

    -- Metadata
    CURRENT_TIMESTAMP() AS loaded_at

FROM {{ source('raw_dataset', 'raw_Sleep_Health_and_Lifestyle_Dataset') }}
