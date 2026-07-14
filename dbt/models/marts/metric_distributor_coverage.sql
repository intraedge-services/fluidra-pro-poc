{{
  config(
    materialized='view',
    schema='MARTS'
  )
}}

SELECT
    distributor_name,
    COUNT(DISTINCT CASE WHEN distributor_account_status = 'ACTIVE' THEN pro_business_id END) AS active_dealers,
    COUNT(DISTINCT CASE WHEN distributor_account_status = 'PENDING ACTIVE' THEN pro_business_id END) AS pending_dealers,
    COUNT(DISTINCT CASE WHEN distributor_account_status IN ('INACTIVE','PENDING INACTIVE') THEN pro_business_id END) AS inactive_dealers,
    COUNT(DISTINCT pro_business_id) AS total_dealers,
    ROUND(COUNT(DISTINCT CASE WHEN distributor_account_status = 'ACTIVE' THEN pro_business_id END)::FLOAT / NULLIF(COUNT(DISTINCT pro_business_id), 0) * 100, 1) AS active_rate_pct
FROM {{ ref('dim_distributor') }}
GROUP BY distributor_name
ORDER BY total_dealers DESC
