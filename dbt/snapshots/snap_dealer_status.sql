{% snapshot snap_dealer_status %}
{{
  config(
    target_schema='DIMENSIONS',
    unique_key='dealer_id',
    strategy='timestamp',
    updated_at='last_updated_at'
  )
}}

SELECT
    dealer_id, dealer_name, dealer_status, business_type,
    achiever_level, program_level, program_status, sales_region,
    is_enrolled, has_active_login, last_updated_at
FROM {{ ref('dim_dealer') }}

{% endsnapshot %}
