{{ config(materialized='table', schema='DIMENSIONS') }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['pro_contact_id']) }} AS user_key,
    pro_contact_id AS user_id,
    first_name,
    last_name,
    first_name || ' ' || last_name AS full_name,
    email,
    contact_type AS role,
    login_status,
    status AS user_status,
    CASE WHEN contact_type='TECHNICIAN' THEN TRUE ELSE FALSE END AS is_technician,
    CASE WHEN contact_type IN ('OWNER','CO-OWNER') THEN TRUE ELSE FALSE END AS is_dealer_user,
    CASE WHEN login_status='ACTIVE' THEN TRUE ELSE FALSE END AS has_logged_in,
    CASE WHEN login_status='PENDING' THEN TRUE ELSE FALSE END AS never_set_up,
    created_at AS registration_date,
    event_time AS last_updated_at
FROM {{ ref('stg_fluidrapro_contacts') }}
