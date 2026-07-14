{{
  config(
    materialized='view',
    schema='DIMENSIONS'
  )
}}

SELECT
    pro_location_id,
    pro_business_id,
    location_name,
    location_type,
    location_status,
    street_line_1,
    street_line_2,
    city,
    state,
    zip,
    country,
    phone_number,
    lead_management_email,
    hide_address,
    hide_location,
    service_zip_count,
    created_at,
    event_time AS last_event_time
FROM {{ ref('stg_fpro_qa_locations') }}
