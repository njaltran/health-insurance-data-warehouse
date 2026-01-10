{% macro test_no_future_dates(model, column_name) %}

/*
    Custom test macro to ensure no future dates in a column
    Usage: {{ test_no_future_dates('my_model', 'birthdate') }}
*/

SELECT
    {{ column_name }},
    COUNT(*) AS invalid_count
FROM {{ model }}
WHERE {{ column_name }} > CURRENT_DATE()
GROUP BY {{ column_name }}
HAVING COUNT(*) > 0

{% endmacro %}


{% macro test_percentage_range(model, column_name, min_val=0, max_val=100) %}

/*
    Custom test macro to ensure percentage values are in valid range
    Usage: {{ test_percentage_range('my_model', 'blood_oxygen_percent') }}
*/

SELECT
    {{ column_name }},
    COUNT(*) AS invalid_count
FROM {{ model }}
WHERE {{ column_name }} < {{ min_val }}
   OR {{ column_name }} > {{ max_val }}
GROUP BY {{ column_name }}
HAVING COUNT(*) > 0

{% endmacro %}


{% macro audit_log(message) %}

/*
    Macro to log audit messages during dbt runs
    Usage: {{ audit_log('Starting data cleaning process') }}
*/

{% do log(message, info=True) %}

{% endmacro %}


{% macro generate_quality_report(model_name) %}

/*
    Generate a data quality summary report for a model
    Returns count of records with quality flags
*/

SELECT
    '{{ model_name }}' AS model_name,
    COUNT(*) AS total_records,
    COUNTIF(is_invalid_sleep_duration) AS invalid_sleep_duration,
    COUNTIF(is_invalid_heart_rate) AS invalid_heart_rate,
    COUNTIF(is_invalid_age) AS invalid_age
FROM {{ ref(model_name) }}

{% endmacro %}
