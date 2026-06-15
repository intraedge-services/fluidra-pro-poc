/*
  Custom Test: Validate user adoption KPI business rules
*/
WITH mart AS (SELECT * FROM {{ ref('mart_user_adoption') }})
SELECT * FROM mart
WHERE active_users > total_users
    OR first_login_rate < 0 OR first_login_rate > 1
    OR users_never_set_up > total_users
