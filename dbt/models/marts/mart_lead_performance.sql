{{
  config(materialized='table', schema='MARTS')
}}

/*
  Mart: mart_lead_performance
  KPIs: Lead Approval Time, Lead Rejection Rate, Rewards Activation Time
  Status: PARTIAL - rewards activation from Fluidra Pro, leads require Salesforce
*/

WITH businesses AS (SELECT * FROM {{ ref('stg_fluidrapro_businesses') }})
SELECT
    COUNT(CASE WHEN business_status='LEAD' THEN 1 END) AS current_leads,
    COUNT(CASE WHEN business_status='ACTIVE' THEN 1 END) AS active_businesses,
    COUNT(*) AS total_businesses,
    AVG(CASE WHEN program_signup_date IS NOT NULL AND created_at IS NOT NULL
        THEN DATEDIFF('hour', created_at, program_signup_date) END) AS avg_hours_to_rewards_activation,
    NULL::FLOAT AS guest_to_lead_conversion_rate,
    NULL::FLOAT AS lead_rejection_rate,
    NULL::FLOAT AS avg_hours_to_lead_approval,
    'PARTIAL_DATA' AS lead_data_status,
    0.05 AS target_rejection_rate,
    24.00 AS target_approval_hours,
    24.00 AS target_activation_hours,
    CASE WHEN AVG(CASE WHEN program_signup_date IS NOT NULL AND created_at IS NOT NULL
        THEN DATEDIFF('hour', created_at, program_signup_date) END) <= 24 THEN 'GREEN'
        WHEN AVG(CASE WHEN program_signup_date IS NOT NULL AND created_at IS NOT NULL
        THEN DATEDIFF('hour', created_at, program_signup_date) END) IS NULL THEN 'PENDING'
        ELSE 'RED' END AS rag_rewards_activation,
    'PENDING' AS rag_lead_rejection,
    'PENDING' AS rag_lead_approval,
    CURRENT_TIMESTAMP() AS calculated_at
FROM businesses
