{{
  config(
    materialized='view',
    tags=['staging', 'insurance', 'facts']
  )
}}

/*
    Staging model for Health Insurance Facts
    Source: raw_dataset.health_insurance_insurance_facts_raw
    Purpose: Type casting and basic cleansing
*/

SELECT
    -- Foreign Key
    TRIM(Person_id) AS person_id,

    -- Financial Metrics
    insurance_cost_year,
    SAFE_CAST(annual_cost_to_insurance AS FLOAT64) AS annual_cost_to_insurance,

    -- Activity Metrics
    SAFE_CAST(annual_doctor_visits AS INT64) AS annual_doctor_visits,

    -- Time Dimension
    SAFE_CAST(year AS INT64) AS year,

    -- Metadata
    CURRENT_TIMESTAMP() AS loaded_at

FROM {{ source('raw_dataset', 'health_insurance_insurance_facts_raw') }}
