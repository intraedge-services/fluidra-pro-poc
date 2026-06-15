{% macro calculate_variance(metric_value, target_value) %}
    CASE
        WHEN {{ metric_value }} IS NULL OR {{ target_value }} IS NULL THEN NULL
        ELSE ROUND({{ metric_value }} - {{ target_value }}, 4)
    END
{% endmacro %}
