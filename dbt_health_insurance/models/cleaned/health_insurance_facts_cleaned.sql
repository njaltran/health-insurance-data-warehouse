{{
  config(
    materialized='table',
    tags=['cleaned', 'production', 'insurance', 'facts']
  )
}}

/*
    Cleaned Health Insurance Facts
    Source: {{ ref('stg_health_insurance_facts') }}

    Transformations Applied:
    1. Replace NULL metrics with 0 (business logic: no visits = 0)
    2. Validate costs are non-negative
    3. Validate year ranges (2000 to current year)
    4. Deduplicate by person_id + year composite key
    5. Filter invalid records

    Data Quality Standards:
    - NULL handling with business context (0 for no activity)
    - Negative value filtering
    - Time dimension validation
    - Composite key deduplication
*/

WITH

-- Step 1: Handle Missing Values
missing_value_handling AS (
    SELECT
        *,
        -- For metrics: NULL means "no activity" = 0
        COALESCE(annual_doctor_visits, 0) AS doctor_visits_count,
        COALESCE(annual_cost_to_insurance, 0.0) AS cost_to_insurance_amount,

        -- Track missing values for quality monitoring
        CASE WHEN annual_doctor_visits IS NULL THEN TRUE ELSE FALSE END AS is_missing_doctor_visits,
        CASE WHEN annual_cost_to_insurance IS NULL THEN TRUE ELSE FALSE END AS is_missing_insurance_cost

    FROM {{ ref('stg_health_insurance_facts') }}
),

-- Step 2: Data Validation
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

        -- Validate year (2000 to current year)
        CASE
            WHEN year < {{ var('min_year') }} OR year > EXTRACT(YEAR FROM CURRENT_DATE()) THEN TRUE
            ELSE FALSE
        END AS is_invalid_year

    FROM missing_value_handling
),

-- Step 3: Deduplication - Composite key (person_id + year)
deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY person_id, year ORDER BY loaded_at DESC) AS row_rank
    FROM validated_data
    WHERE person_id IS NOT NULL
      AND person_id != ''
      AND year IS NOT NULL
)

-- Step 4: Final Selection
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

FROM deduplicated
WHERE row_rank = 1  -- Deduplication
  AND NOT (is_invalid_cost_year OR is_invalid_cost_to_insurance OR is_invalid_doctor_visits OR is_invalid_year)
