{{
  config(
    materialized='table',
    schema='DIMENSIONS'
  )
}}

WITH contact_standalone AS (
    SELECT * FROM {{ ref('stg_fpro_qa_contacts') }}
),
bridge AS (
    SELECT DISTINCT
        PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING AS pro_business_id,
        PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.proContactId::STRING AS pro_contact_id
    FROM {{ source('fluidrapro_raw', 'fpro_qa') }}
    WHERE RECORD_METADATA != 'RECORD_METADATA'
      AND PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
      AND PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.proContactId IS NOT NULL
      AND PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId IS NOT NULL
)
SELECT
    c.pro_contact_id,
    COALESCE(c.pro_business_id, b.pro_business_id) AS pro_business_id,
    c.contact_type,
    c.first_name,
    c.last_name,
    c.email,
    c.phone_number,
    c.login_status,
    c.username,
    c.cognito_sub_id,
    c.web_user_id,
    c.last_login_date,
    c.contact_status,
    c.assigned_location_count,
    c.user_subscription_count,
    c.is_deleted_event,
    c.created_at,
    c.updated_at,
    c.event_time AS last_event_time,
    CASE
        WHEN c.is_deleted_event THEN 'DELETED'
        WHEN c.login_status = 'ACTIVE' AND c.last_login_date >= DATEADD('day', -30, CURRENT_TIMESTAMP()) THEN 'ACTIVE'
        WHEN c.login_status = 'ACTIVE' AND (c.last_login_date < DATEADD('day', -30, CURRENT_TIMESTAMP()) OR c.last_login_date IS NULL) THEN 'INACTIVE'
        WHEN c.login_status = 'PENDING' THEN 'PENDING_SETUP'
        WHEN c.login_status = 'NOLOGIN' THEN 'NO_LOGIN_REQUIRED'
        ELSE 'UNKNOWN'
    END AS contact_health_status,
    DATEDIFF('day', c.last_login_date, CURRENT_TIMESTAMP()) AS days_since_last_login
FROM contact_standalone c
LEFT JOIN bridge b ON c.pro_contact_id = b.pro_contact_id
