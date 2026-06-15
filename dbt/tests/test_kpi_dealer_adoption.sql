/*
  Custom Test: Validate dealer adoption KPI business rules
*/
WITH mart AS (SELECT * FROM {{ ref('mart_dealer_adoption') }})
SELECT * FROM mart
WHERE active_dealers > total_dealers
    OR active_dealer_rate < 0 OR active_dealer_rate > 1
    OR enrolled_dealers > total_dealers
