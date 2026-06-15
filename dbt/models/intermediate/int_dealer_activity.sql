{{
  config(materialized='table', schema='INTERMEDIATE')
}}

/*
  Intermediate: int_dealer_activity
  Purpose: Dealer-level activity metrics for adoption KPIs
*/

WITH dealers AS (SELECT * FROM {{ ref('stg_fluidrapro_businesses') }})
SELECT
    pro_business_id, business_name, business_status, primary_business_type,
    achiever_level, program_level, program_status, rewards_region,
    fluidra_account_number, primary_contact_login_status, primary_contact_last_login,
    created_at AS enrollment_date,
    CASE WHEN primary_contact_login_status='ACTIVE' THEN TRUE ELSE FALSE END AS is_active,
    CASE WHEN business_status='ACTIVE' AND program_status='ACTIVE' THEN TRUE ELSE FALSE END AS is_enrolled,
    CASE WHEN primary_contact_login_status='PENDING' THEN TRUE ELSE FALSE END AS never_set_up,
    event_time AS last_event_time
FROM dealers
