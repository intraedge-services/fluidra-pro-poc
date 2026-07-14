{{
  config(
    materialized='view',
    schema='MARTS'
  )
}}

SELECT
    COUNT(DISTINCT CASE WHEN d.login_status = 'ACTIVE' AND d.primary_contact_last_login >= DATEADD('day', -30, CURRENT_TIMESTAMP()) THEN d.pro_business_id END) AS kpi_1_1_active_dealers_30d,
    COUNT(DISTINCT CASE WHEN d.business_status = 'ACTIVE' AND d.rewards_program_status = 'ACTIVE' THEN d.pro_business_id END) AS kpi_1_2_enrolled_dealers,
    COUNT(DISTINCT CASE WHEN d.login_status = 'PENDING' THEN d.pro_business_id END) AS kpi_1_3_dealers_not_setup,
    COUNT(DISTINCT CASE WHEN d.login_status = 'ACTIVE' AND (d.primary_contact_last_login < DATEADD('day', -30, CURRENT_TIMESTAMP()) OR d.primary_contact_last_login IS NULL) THEN d.pro_business_id END) AS kpi_1_4_inactive_dealers,
    (SELECT COUNT(*) FROM {{ ref('fct_dealer_events') }} WHERE is_created_event = 1) AS kpi_1_5_new_dealers_created,
    COUNT(DISTINCT d.pro_business_id) AS total_dealers
FROM {{ ref('dim_pro_business_master') }} d
