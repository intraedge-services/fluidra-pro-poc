{{
  config(
    materialized='view',
    schema='DIMENSIONS'
  )
}}

SELECT
    pro_business_id,
    subscription_id,
    subscription_name,
    subscription_status,
    program_start_date,
    source,
    subscription_created_at,
    subscription_updated_at,
    event_time AS last_event_time
FROM {{ ref('stg_fpro_qa_business_subscriptions') }}
