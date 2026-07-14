{{
  config(
    materialized='table',
    schema='DIMENSIONS'
  )
}}

/*
  Dimension: dim_pro_business_master
  Grain: 1 row per pro_business_id (complete dealer profile)
  Sources: stg_businesses (base) + aggregated distributors/programs/subscriptions
*/

WITH base AS (
    SELECT * FROM {{ ref('stg_fpro_qa_businesses') }}
),
distributor_agg AS (
    SELECT
        pro_business_id,
        COUNT(*) AS total_distributor_count,
        COUNT(CASE WHEN distributor_account_status = 'ACTIVE' THEN 1 END) AS active_distributor_count,
        COUNT(CASE WHEN distributor_account_status = 'PENDING ACTIVE' THEN 1 END) AS pending_distributor_count,
        COUNT(CASE WHEN distributor_account_status IN ('INACTIVE','PENDING INACTIVE') THEN 1 END) AS inactive_distributor_count,
        LISTAGG(DISTINCT distributor_name, ', ') WITHIN GROUP (ORDER BY distributor_name) AS distributor_names_list
    FROM {{ ref('stg_fpro_qa_business_distributors') }}
    GROUP BY pro_business_id
),
program_agg AS (
    SELECT
        pro_business_id,
        COUNT(*) AS total_program_count,
        COUNT(CASE WHEN program_status = 'ACTIVE' THEN 1 END) AS active_program_count,
        COUNT(CASE WHEN program_status = 'PENDING' THEN 1 END) AS pending_program_count,
        COUNT(CASE WHEN program_status = 'DECLINED' THEN 1 END) AS declined_program_count,
        LISTAGG(DISTINCT program_name, ', ') WITHIN GROUP (ORDER BY program_name) AS program_names_list,
        MAX(CASE WHEN program_name = 'PROEDGE' AND program_status = 'ACTIVE' THEN TRUE ELSE FALSE END) AS has_active_proedge,
        MAX(CASE WHEN program_name LIKE '%SERVICEPRO%' AND program_status = 'ACTIVE' THEN TRUE ELSE FALSE END) AS has_active_servicepro,
        MAX(CASE WHEN program_name = 'RETAIL SELECT' AND program_status = 'ACTIVE' THEN TRUE ELSE FALSE END) AS has_active_retail_select
    FROM {{ ref('stg_fpro_qa_business_program_optins') }}
    GROUP BY pro_business_id
),
subscription_agg AS (
    SELECT
        pro_business_id,
        COUNT(*) AS total_subscription_count,
        COUNT(CASE WHEN subscription_status = 'ACTIVE' THEN 1 END) AS active_subscription_count,
        LISTAGG(DISTINCT subscription_name, ', ') WITHIN GROUP (ORDER BY subscription_name) AS subscription_names_list,
        MAX(CASE WHEN subscription_name = 'ION POOL CARE' AND subscription_status = 'ACTIVE' THEN TRUE ELSE FALSE END) AS has_active_ion_pool_care
    FROM {{ ref('stg_fpro_qa_business_subscriptions') }}
    GROUP BY pro_business_id
)
SELECT
    b.pro_business_id,
    b.business_name,
    b.doing_business_as,
    b.business_status,
    b.login_status,
    b.registration_source,
    b.customer_type,
    b.primary_business_type,
    b.business_segment,
    b.channel,
    b.customer_class,
    b.sales_channel,
    b.primary_business_email,
    b.primary_business_phone,
    b.website,
    b.is_primary_key_account,
    b.key_account_type_name,
    b.key_account_type_role,
    b.fluidra_account_number,
    b.crm_lead_id,
    b.web_account_id,
    b.is_pro_login_allowed,
    b.terms_accepted,
    b.e_statement_enabled,
    b.is_marcom_consent,
    b.tse_violator,
    b.rewards_program_level,
    b.rewards_achiever_level,
    b.rewards_program_status,
    b.rewards_rebate_pay_type,
    b.rewards_region,
    b.rewards_auto_zodiac,
    b.rewards_signup_date,
    b.primary_contact_id,
    b.primary_contact_type,
    b.primary_contact_first_name,
    b.primary_contact_last_name,
    b.primary_contact_login_status,
    b.primary_contact_cognito_sub_id,
    b.primary_contact_last_login,
    b.billing_location_id,
    b.billing_city,
    b.billing_state,
    b.billing_zip,
    b.billing_country,
    b.shipping_location_id,
    b.shipping_city,
    b.shipping_state,
    b.sales_rep_name,
    b.sales_rep_email,
    b.utm_source,
    b.utm_medium,
    b.utm_campaign,
    COALESCE(d.total_distributor_count, 0) AS total_distributor_count,
    COALESCE(d.active_distributor_count, 0) AS active_distributor_count,
    COALESCE(d.pending_distributor_count, 0) AS pending_distributor_count,
    COALESCE(d.inactive_distributor_count, 0) AS inactive_distributor_count,
    d.distributor_names_list,
    COALESCE(p.total_program_count, 0) AS total_program_count,
    COALESCE(p.active_program_count, 0) AS active_program_count,
    COALESCE(p.pending_program_count, 0) AS pending_program_count,
    COALESCE(p.declined_program_count, 0) AS declined_program_count,
    p.program_names_list,
    COALESCE(p.has_active_proedge, FALSE) AS has_active_proedge,
    COALESCE(p.has_active_servicepro, FALSE) AS has_active_servicepro,
    COALESCE(p.has_active_retail_select, FALSE) AS has_active_retail_select,
    COALESCE(s.total_subscription_count, 0) AS total_subscription_count,
    COALESCE(s.active_subscription_count, 0) AS active_subscription_count,
    s.subscription_names_list,
    COALESCE(s.has_active_ion_pool_care, FALSE) AS has_active_ion_pool_care,
    CASE
        WHEN b.login_status = 'ACTIVE' AND b.primary_contact_last_login >= DATEADD('day', -30, CURRENT_TIMESTAMP()) THEN 'HEALTHY'
        WHEN b.login_status = 'ACTIVE' AND (b.primary_contact_last_login < DATEADD('day', -30, CURRENT_TIMESTAMP()) OR b.primary_contact_last_login IS NULL) THEN 'AT_RISK'
        WHEN b.login_status = 'PENDING' THEN 'NOT_ONBOARDED'
        WHEN b.business_status = 'GUEST' THEN 'GUEST'
        WHEN b.business_status = 'REJECTED' THEN 'REJECTED'
        ELSE 'UNKNOWN'
    END AS health_status,
    DATEDIFF('day', b.primary_contact_last_login, CURRENT_TIMESTAMP()) AS days_since_last_login,
    b.created_at,
    b.created_by,
    b.updated_at,
    b.event_time AS last_event_time,
    b.event_detail_type AS last_event_type
FROM base b
LEFT JOIN distributor_agg d ON b.pro_business_id = d.pro_business_id
LEFT JOIN program_agg p ON b.pro_business_id = p.pro_business_id
LEFT JOIN subscription_agg s ON b.pro_business_id = s.pro_business_id
