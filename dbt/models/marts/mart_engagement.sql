{{
  config(materialized='table', schema='MARTS')
}}

/*
  Mart: mart_engagement
  KPIs: Dealer Stickiness (WAU/MAU), Technician Stickiness (DAU/MAU)
  Status: PENDING - requires login event stream for WAU/DAU
*/

WITH users AS (SELECT * FROM {{ ref('int_user_activity') }})
SELECT
    COUNT(DISTINCT user_id) AS total_users,
    COUNT(DISTINCT CASE WHEN is_active THEN user_id END) AS monthly_active_users,
    COUNT(DISTINCT CASE WHEN is_technician AND is_active THEN user_id END) AS monthly_active_technicians,
    NULL::FLOAT AS dealer_stickiness_ratio,
    NULL::FLOAT AS technician_stickiness_ratio,
    'PENDING_LOGIN_EVENTS' AS stickiness_data_status,
    0.20 AS target_dealer_stickiness,
    0.40 AS target_technician_stickiness,
    'PENDING' AS rag_dealer_stickiness,
    'PENDING' AS rag_technician_stickiness,
    CURRENT_TIMESTAMP() AS calculated_at
FROM users
