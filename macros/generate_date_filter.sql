{% macro generate_date_filter(months_back=6) %}
  SELECT
    DATE_SUB(CURRENT_DATE(), INTERVAL {{ months_back }} MONTH) AS lookback_start_date,
    CURRENT_DATE() AS analysis_end_date
{% endmacro %} 