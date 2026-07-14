{{
  config(
    materialized='view',
    schema='DIMENSIONS'
  )
}}

SELECT
    key_account_type_id,
    key_account_type_name,
    key_account_type_role,
    customer_class,
    sales_channel,
    program_name,
    achiever_level,
    enable_zodiac_premium,
    override_achiever_level_role,
    e_statement_enabled,
    print_statements,
    created_at,
    created_by,
    event_time AS last_event_time
FROM {{ ref('stg_fpro_qa_key_account_types') }}
