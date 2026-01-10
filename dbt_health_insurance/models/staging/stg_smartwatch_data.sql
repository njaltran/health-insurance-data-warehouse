{{
  config(
    materialized='view',
    tags=['staging', 'smartwatch']
  )
}}

/*
    Staging model for Smartwatch Health Data
    Source: raw_dataset.raw_smartwatch_health_data
    Purpose: Type casting from STRING to proper numeric types
*/

SELECT
    -- Primary Key
    TRIM(`User ID`) AS user_id,

    -- Vital Signs
    SAFE_CAST(`Heart Rate_BPM` AS FLOAT64) AS heart_rate_bpm,
    SAFE_CAST(`Blood Oxygen Level %` AS FLOAT64) AS blood_oxygen_percent,

    -- Activity Metrics
    SAFE_CAST(`Step Count` AS FLOAT64) AS step_count,
    SAFE_CAST(`Sleep Duration hours` AS FLOAT64) AS sleep_duration_hours,

    -- Activity & Stress
    LOWER(TRIM(`Activity Level`)) AS activity_level,
    LOWER(TRIM(`Stress Level`)) AS stress_level,

    -- Metadata
    CURRENT_TIMESTAMP() AS loaded_at

FROM {{ source('raw_dataset', 'raw_smartwatch_health_data') }}
