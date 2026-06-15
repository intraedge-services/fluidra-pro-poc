{{
  config(materialized='table', schema='MARTS')
}}

/*
  Mart: mart_revenue
  KPIs: Revenue Associated to Active Dealers, Revenue Growth
  Status: PENDING - Requires PSOT Revenue Data
*/

SELECT
    NULL::FLOAT AS revenue_active_dealers,
    NULL::FLOAT AS revenue_previous_period,
    NULL::FLOAT AS revenue_growth_rate,
    NULL::FLOAT AS revenue_per_active_dealer,
    NULL::DATE AS baseline_date,
    'PENDING_REVENUE_DATA' AS revenue_data_status,
    'August 2025' AS revenue_baseline_period,
    'PENDING' AS rag_revenue_growth,
    CURRENT_TIMESTAMP() AS calculated_at
