{{
  config(materialized='view', schema='REPORTING')
}}

/*
  Reporting View: vw_dealer_adoption
  Purpose: Dealer-level detail for drill-down
  Filters: business_type, achiever_level, dealer_status, sales_region
*/

WITH dealers AS (SELECT * FROM {{ ref('dim_dealer') }})
SELECT
    dealer_key, dealer_id, dealer_name, dealer_status, business_type,
    achiever_level, program_level, program_status, sales_region,
    fluidra_account_number, is_enrolled, has_active_login, is_key_account,
    enrollment_date, last_updated_at,
    CASE
        WHEN has_active_login THEN 'Active'
        WHEN NOT has_active_login AND is_enrolled THEN 'Inactive'
        WHEN NOT is_enrolled THEN 'Not Set Up'
        ELSE 'Unknown'
    END AS activity_status
FROM dealers
