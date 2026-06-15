{{ config(materialized='table', schema='DIMENSIONS') }}

SELECT
    {{ dbt_utils.generate_surrogate_key(['pro_business_id']) }} AS dealer_key,
    pro_business_id AS dealer_id,
    business_name AS dealer_name,
    business_status AS dealer_status,
    primary_business_type AS business_type,
    achiever_level,
    program_level,
    program_status,
    rewards_region AS sales_region,
    fluidra_account_number,
    primary_contact_login_status,
    primary_contact_last_login,
    CASE WHEN business_status='ACTIVE' AND program_status='ACTIVE' THEN TRUE ELSE FALSE END AS is_enrolled,
    CASE WHEN primary_contact_login_status='ACTIVE' THEN TRUE ELSE FALSE END AS has_active_login,
    NULL::BOOLEAN AS is_key_account,
    created_at AS enrollment_date,
    event_time AS last_updated_at
FROM {{ ref('stg_fluidrapro_businesses') }}
