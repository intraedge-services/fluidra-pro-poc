{{
  config(materialized='table', schema='INTERMEDIATE')
}}

/*
  Intermediate: int_user_activity
  Purpose: User-level activity metrics for adoption and engagement KPIs
*/

WITH contacts AS (SELECT * FROM {{ ref('stg_fluidrapro_contacts') }})
SELECT
    pro_contact_id AS user_id, first_name, last_name, email, contact_type,
    login_status, status AS user_status,
    CASE WHEN login_status='ACTIVE' THEN TRUE ELSE FALSE END AS is_active,
    CASE WHEN login_status='PENDING' THEN TRUE ELSE FALSE END AS never_set_up,
    CASE WHEN contact_type='TECHNICIAN' THEN TRUE ELSE FALSE END AS is_technician,
    CASE WHEN contact_type IN ('OWNER','CO-OWNER') THEN TRUE ELSE FALSE END AS is_dealer_user,
    created_at AS registration_date, updated_at, event_time, event_type,
    CASE WHEN event_type='login-created' THEN DATEDIFF('hour', created_at, event_time) ELSE NULL END AS hours_to_login_creation
FROM contacts
