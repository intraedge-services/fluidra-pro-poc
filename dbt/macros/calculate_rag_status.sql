{% macro calculate_rag_status(metric_value, target_value, higher_is_better=true) %}
    CASE
        WHEN {{ metric_value }} IS NULL THEN 'PENDING'
        {% if higher_is_better %}
        WHEN {{ metric_value }} >= {{ target_value }} THEN 'GREEN'
        {% else %}
        WHEN {{ metric_value }} <= {{ target_value }} THEN 'GREEN'
        {% endif %}
        ELSE 'RED'
    END
{% endmacro %}
