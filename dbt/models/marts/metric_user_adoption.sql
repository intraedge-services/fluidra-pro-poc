{{
  config(
    materialized='view',
    schema='MARTS'
  )
}}

WITH contacts AS (
    SELECT * FROM {{ ref('dim_contact') }}
),
contact_events AS (
    SELECT * FROM {{ ref('fct_contact_events') }}
),
created_contacts AS (
    SELECT DISTINCT pro_contact_id FROM contact_events WHERE is_created_event = 1
),
login_created AS (
    SELECT DISTINCT pro_contact_id FROM contact_events WHERE is_login_created_event = 1
),
technicians_created AS (
    SELECT DISTINCT pro_contact_id FROM contact_events WHERE is_created_event = 1 AND contact_type = 'TECHNICIAN'
)
SELECT
    (SELECT COUNT(*) FROM contacts WHERE login_status = 'ACTIVE') AS kpi_3_1_total_active_users,
    (SELECT COUNT(*) FROM technicians_created) AS kpi_3_2_new_technicians,
    (SELECT COUNT(*) FROM created_contacts WHERE pro_contact_id NOT IN (SELECT pro_contact_id FROM login_created)) AS kpi_3_3_users_never_setup,
    (SELECT COUNT(*) FROM contacts WHERE login_status = 'ACTIVE' AND (last_login_date < DATEADD('day', -30, CURRENT_TIMESTAMP()) OR last_login_date IS NULL)) AS kpi_3_4_inactive_users,
    ROUND((SELECT COUNT(*) FROM login_created)::FLOAT / NULLIF((SELECT COUNT(*) FROM created_contacts), 0) * 100, 1) AS kpi_3_6_first_login_rate_pct,
    (SELECT COUNT(*) FROM created_contacts) AS total_contacts_created,
    (SELECT COUNT(*) FROM login_created) AS total_login_created
