{{
  config(
    materialized='view',
    schema='MARTS'
  )
}}

WITH funnel AS (
    SELECT * FROM {{ ref('fct_lead_funnel') }}
)
SELECT
    COUNT(CASE WHEN funnel_stage = 'GUEST' THEN 1 END) AS guests,
    COUNT(CASE WHEN funnel_stage = 'LEAD_CREATED' THEN 1 END) AS leads_created,
    COUNT(CASE WHEN funnel_stage = 'LEAD_APPROVED' THEN 1 END) AS leads_approved,
    COUNT(CASE WHEN funnel_stage = 'BUSINESS_APPROVED' THEN 1 END) AS businesses_approved,
    COUNT(CASE WHEN funnel_stage IN ('LEAD_REJECTED','BUSINESS_REJECTED') THEN 1 END) AS total_rejected,
    COUNT(CASE WHEN funnel_stage = 'CREATION_FAILED' THEN 1 END) AS creation_failures,
    ROUND(
        COUNT(CASE WHEN funnel_stage IN ('LEAD_REJECTED','BUSINESS_REJECTED') THEN 1 END)::FLOAT /
        NULLIF(COUNT(CASE WHEN funnel_stage IN ('LEAD_APPROVED','BUSINESS_APPROVED','LEAD_REJECTED','BUSINESS_REJECTED') THEN 1 END), 0) * 100, 2
    ) AS kpi_2_2_rejection_rate_pct,
    ROUND(AVG(CASE WHEN funnel_stage IN ('LEAD_APPROVED','BUSINESS_APPROVED') THEN seconds_in_stage END), 1) AS kpi_2_3_avg_seconds_to_approve,
    COUNT(*) AS total_funnel_events
FROM funnel
