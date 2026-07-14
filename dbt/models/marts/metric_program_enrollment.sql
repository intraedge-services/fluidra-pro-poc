{{
  config(
    materialized='view',
    schema='MARTS'
  )
}}

SELECT
    program_name,
    COUNT(DISTINCT CASE WHEN program_status = 'ACTIVE' THEN pro_business_id END) AS active_count,
    COUNT(DISTINCT CASE WHEN program_status = 'PENDING' THEN pro_business_id END) AS pending_count,
    COUNT(DISTINCT CASE WHEN program_status = 'DECLINED' THEN pro_business_id END) AS declined_count,
    COUNT(DISTINCT CASE WHEN program_status = 'INACTIVE' THEN pro_business_id END) AS inactive_count,
    COUNT(DISTINCT pro_business_id) AS total_enrolled,
    ROUND(COUNT(DISTINCT CASE WHEN program_status = 'ACTIVE' THEN pro_business_id END)::FLOAT / NULLIF(COUNT(DISTINCT pro_business_id), 0) * 100, 1) AS activation_rate_pct
FROM {{ ref('dim_program_opt_in') }}
GROUP BY program_name
ORDER BY total_enrolled DESC
