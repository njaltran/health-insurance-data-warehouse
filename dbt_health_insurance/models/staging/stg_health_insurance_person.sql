{{
  config(
    materialized='view',
    tags=['staging', 'insurance', 'dimension']
  )
}}

/*
    Staging model for Health Insurance Person Dimension
    Source: raw_dataset.raw_health_insurance_person_dim
    Purpose: Basic cleansing - trim whitespace, dates remain as strings for parsing in cleaned layer
*/

SELECT
    -- Primary Key
    TRIM(Person_id) AS person_id,

    -- Demographics (dates kept as strings for multi-format parsing later)
    TRIM(birthdate) AS birthdate_raw,
    TRIM(address) AS address,
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

FROM {{ source('raw_dataset', 'raw_health_insurance_person_dim') }}
