{{ config(materialized='view', schema='REPORTING') }}

WITH d AS (SELECT * FROM {{ ref('mart_dealer_adoption') }}),
     u AS (SELECT * FROM {{ ref('mart_user_adoption') }})
SELECT
    d.total_dealers, d.active_dealers, d.enrolled_dealers, d.dealers_not_set_up,
    d.active_dealer_rate, d.target_active_rate, d.rag_active_dealers,
    u.total_users, u.active_users, u.users_never_set_up, u.total_technicians,
    u.first_login_rate, u.target_first_login_rate, u.rag_first_login_rate,
    CURRENT_TIMESTAMP() AS refreshed_at
FROM d CROSS JOIN u
