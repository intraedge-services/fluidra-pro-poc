{{ config(materialized='table', schema='MARTS') }}

WITH users AS (SELECT * FROM {{ ref('stg_fluidrapro_contacts') }})
SELECT
    COUNT(*) AS total_users,
    COUNT(CASE WHEN login_status='ACTIVE' THEN 1 END) AS active_users,
    COUNT(CASE WHEN login_status='PENDING' THEN 1 END) AS users_never_set_up,
    COUNT(CASE WHEN contact_type='TECHNICIAN' THEN 1 END) AS total_technicians,
    CASE WHEN COUNT(*)>0 THEN ROUND(COUNT(CASE WHEN login_status='ACTIVE' THEN 1 END)::FLOAT/COUNT(*)::FLOAT, 4) ELSE 0 END AS first_login_rate,
    0.75 AS target_first_login_rate,
    CASE WHEN (COUNT(CASE WHEN login_status='ACTIVE' THEN 1 END)::FLOAT/NULLIF(COUNT(*),0)::FLOAT) >= 0.75 THEN 'GREEN' ELSE 'RED' END AS rag_first_login_rate,
    CURRENT_TIMESTAMP() AS calculated_at
FROM users
