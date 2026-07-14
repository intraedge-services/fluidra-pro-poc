{{
  config(
    materialized='view',
    schema='MARTS'
  )
}}

SELECT
    event_date,
    COUNT(*) AS total_events,
    COUNT(CASE WHEN funnel_stage = 'GUEST' THEN 1 END) AS guests,
    COUNT(CASE WHEN funnel_stage = 'LEAD_CREATED' THEN 1 END) AS leads_created,
    COUNT(CASE WHEN funnel_stage IN ('LEAD_APPROVED','BUSINESS_APPROVED') THEN 1 END) AS approved,
    COUNT(CASE WHEN funnel_stage IN ('LEAD_REJECTED','BUSINESS_REJECTED') THEN 1 END) AS rejected,
    COUNT(CASE WHEN funnel_stage = 'CREATION_FAILED' THEN 1 END) AS failures,
    ROUND(
        COUNT(CASE WHEN funnel_stage IN ('LEAD_APPROVED','BUSINESS_APPROVED') THEN 1 END)::FLOAT /
        NULLIF(COUNT(CASE WHEN funnel_stage IN ('LEAD_APPROVED','BUSINESS_APPROVED','LEAD_REJECTED','BUSINESS_REJECTED') THEN 1 END), 0) * 100, 1
    ) AS approval_rate_pct,
    ROUND(AVG(CASE WHEN funnel_stage IN ('LEAD_APPROVED','BUSINESS_APPROVED') THEN seconds_in_stage END), 1) AS avg_seconds_to_approve
FROM {{ ref('fct_lead_funnel') }}
GROUP BY event_date
ORDER BY event_date
