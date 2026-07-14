{{
  config(
    materialized='view',
    schema='DIMENSIONS'
  )
}}

SELECT
    pro_business_id,
    distributor_name,
    distributor_account_number,
    distributor_account_status,
    fluidra_account_number,
    source,
    active_date,
    distributor_created_at,
    distributor_updated_at,
    event_time AS last_event_time
FROM {{ ref('stg_fpro_qa_business_distributors') }}
