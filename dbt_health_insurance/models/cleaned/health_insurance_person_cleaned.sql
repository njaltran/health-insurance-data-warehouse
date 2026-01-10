{{
  config(
    materialized='table',
    tags=['cleaned', 'production', 'insurance', 'dimension']
  )
}}

/*
    Cleaned Health Insurance Person Dimension
    Source: {{ ref('stg_health_insurance_person') }}

    Transformations Applied:
    1. Parse dates from multiple formats (5 different formats)
    2. Standardize gender values (m, f, male, female → male, female, other)
    3. Normalize categorical fields (uppercase for statuses)
    4. Calculate age from birthdate
    5. Validate dates (no future dates, reasonable ranges)
    6. Deduplicate by person_id

    Data Quality Standards:
    - Multi-format date parsing with COALESCE
    - Text standardization (UPPER for codes, LOWER for text)
    - Age calculation and validation
    - Future date filtering
*/

WITH

-- Step 1: Parse Dates from Multiple Formats
parsed_dates AS (
    SELECT
        *,
        -- Birthdate: Try 5 different date formats
        COALESCE(
            SAFE.PARSE_DATE('%Y-%m-%d', birthdate_raw),       -- 1991-03-27
            SAFE.PARSE_DATE('%d-%m-%Y', birthdate_raw),       -- 23-01-1994
            SAFE.PARSE_DATE('%m/%d/%Y', birthdate_raw),       -- 06/30/1948
            SAFE.PARSE_DATE('%d/%m/%Y', birthdate_raw),       -- 19/01/1936
            SAFE.PARSE_DATE('%d.%m.%Y', birthdate_raw)        -- 11.11.2006
        ) AS birthdate,

        -- Insurance Sign-Up Date: Try multiple formats
        COALESCE(
            SAFE.PARSE_DATE('%Y-%m-%d', insurance_sign_up_date_raw),   -- 2000-12-15
            SAFE.PARSE_DATE('%d.%m.%Y', insurance_sign_up_date_raw),   -- 11.11.2006
            SAFE.PARSE_DATE('%d/%m/%y', insurance_sign_up_date_raw),   -- 17/02/11
            SAFE.PARSE_DATE('%m/%d/%y', insurance_sign_up_date_raw)    -- 01/11/05
        ) AS insurance_sign_up_date

    FROM {{ ref('stg_health_insurance_person') }}
),

-- Step 2: Standardize Categorical Values
standardized_categories AS (
    SELECT
        *,
        -- Gender: Map all variations to standard values
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

        -- Occupational Category: Lowercase
        LOWER(occupational_category_raw) AS occupational_category,

        -- Wealth Bracket: Normalize to uppercase
        UPPER(wealth_bracket_raw) AS wealth_bracket,

        -- Address: Normalize to lowercase
        LOWER(address) AS address_clean

    FROM parsed_dates
),

-- Step 3: Calculate Age and Validate
validated_data AS (
    SELECT
        *,
        -- Calculate age from birthdate
        DATE_DIFF(CURRENT_DATE(), birthdate, YEAR) AS age,

        -- Validation: Birthdate
        CASE
            WHEN birthdate > CURRENT_DATE() THEN TRUE
            WHEN birthdate < DATE('1900-01-01') THEN TRUE
            ELSE FALSE
        END AS is_invalid_birthdate,

        -- Validation: Sign-up Date
        CASE
            WHEN insurance_sign_up_date > CURRENT_DATE() THEN TRUE
            WHEN insurance_sign_up_date < DATE('1950-01-01') THEN TRUE
            ELSE FALSE
        END AS is_invalid_signup_date,

        -- Validation: Age
        CASE
            WHEN DATE_DIFF(CURRENT_DATE(), birthdate, YEAR) < 0 OR DATE_DIFF(CURRENT_DATE(), birthdate, YEAR) > {{ var('max_age') }} THEN TRUE
            ELSE FALSE
        END AS is_invalid_age

    FROM standardized_categories
),

-- Step 4: Deduplication
deduplicated AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY loaded_at DESC) AS row_rank
    FROM validated_data
    WHERE person_id IS NOT NULL
      AND person_id != ''
      -- Filter out header rows that were imported as data
      AND insurance_status NOT IN ('INSURANCE_STATUS')
      AND family_status NOT IN ('FAMILY_STATUS')
      AND wealth_bracket NOT IN ('WEALTH_BRACKET')
)

-- Step 5: Final Selection
SELECT
    -- Primary Key
    person_id,

    -- Demographics
    birthdate,
    age,
    gender,
    family_status,
    address_clean AS address,

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

FROM deduplicated
WHERE row_rank = 1  -- Deduplication
  AND NOT (is_invalid_birthdate OR is_invalid_age)  -- Filter invalid records
