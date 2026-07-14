{{
  config(
    materialized='view',
    schema='MARTS'
  )
}}

WITH ce AS (
    SELECT * FROM {{ ref('fct_contact_events') }}
),
created AS (
    SELECT pro_contact_id, contact_type, MIN(event_time) AS created_time
    FROM ce WHERE is_created_event = 1
    GROUP BY pro_contact_id, contact_type
),
login_created AS (
    SELECT pro_contact_id, MIN(event_time) AS login_time
    FROM ce WHERE is_login_created_event = 1
    GROUP BY pro_contact_id
)
SELECT
    c.contact_type,
    COUNT(DISTINCT c.pro_contact_id) AS total_created,
    COUNT(DISTINCT l.pro_contact_id) AS completed_login,
    COUNT(DISTINCT c.pro_contact_id) - COUNT(DISTINCT l.pro_contact_id) AS never_setup,
    ROUND(COUNT(DISTINCT l.pro_contact_id)::FLOAT / NULLIF(COUNT(DISTINCT c.pro_contact_id), 0) * 100, 1) AS first_login_rate_pct,
    ROUND(AVG(DATEDIFF('minute', c.created_time, l.login_time)), 1) AS avg_minutes_to_login,
    MAX(DATEDIFF('minute', c.created_time, l.login_time)) AS max_minutes_to_login
FROM created c
LEFT JOIN login_created l ON c.pro_contact_id = l.pro_contact_id
GROUP BY c.contact_type
ORDER BY total_created DESC
