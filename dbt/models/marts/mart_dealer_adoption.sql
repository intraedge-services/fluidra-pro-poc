{{ config(materialized='table', schema='MARTS') }}

WITH dealers AS (SELECT * FROM {{ ref('stg_fluidrapro_businesses') }})
SELECT
    COUNT(*) AS total_dealers,
    COUNT(CASE WHEN primary_contact_login_status='ACTIVE' THEN 1 END) AS active_dealers,
    COUNT(CASE WHEN business_status='ACTIVE' AND program_status='ACTIVE' THEN 1 END) AS enrolled_dealers,
    COUNT(CASE WHEN primary_contact_login_status='PENDING' THEN 1 END) AS dealers_not_set_up,
    CASE WHEN COUNT(*)>0 THEN ROUND(COUNT(CASE WHEN primary_contact_login_status='ACTIVE' THEN 1 END)::FLOAT/COUNT(*)::FLOAT, 4) ELSE 0 END AS active_dealer_rate,
    0.90 AS target_active_rate,
    CASE WHEN (COUNT(CASE WHEN primary_contact_login_status='ACTIVE' THEN 1 END)::FLOAT/NULLIF(COUNT(*),0)::FLOAT) >= 0.90 THEN 'GREEN' ELSE 'RED' END AS rag_active_dealers,
    CURRENT_TIMESTAMP() AS calculated_at
FROM dealers
