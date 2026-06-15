{{
  config(materialized='view', schema='REPORTING')
}}

/*
  Reporting View: vw_user_adoption
  Purpose: User-level detail for drill-down
  Filters: role, login_status, is_technician
*/

WITH users AS (SELECT * FROM {{ ref('dim_user') }})
SELECT
    user_key, user_id, full_name, email, role, login_status, user_status,
    is_technician, is_dealer_user, has_logged_in, never_set_up,
    registration_date, last_updated_at,
    CASE
        WHEN has_logged_in THEN 'Active'
        WHEN never_set_up THEN 'Never Set Up'
        ELSE 'Inactive'
    END AS activity_status
FROM users
