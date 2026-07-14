{{
  config(
    materialized='view',
    schema='DIMENSIONS'
  )
}}

SELECT
    pro_business_id,
    program_name,
    program_status,
    program_opt_in_date,
    program_start_date,
    fluidra_account_number,
    source,
    program_created_at,
    program_updated_at,
    event_time AS last_event_time
FROM {{ ref('stg_fpro_qa_business_program_optins') }}
