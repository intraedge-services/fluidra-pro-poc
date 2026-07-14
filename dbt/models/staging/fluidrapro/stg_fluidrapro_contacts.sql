{{
  config(
    materialized='view',
    schema='STAGING'
  )
}}

/*
  Staging model: stg_fluidrapro_contacts
  Source: RAW_DB.FLUIDRAPRO_RAW.RAW_DEALERS_DATA
  Filter: pro-contact-master events (created, updated, login-created)
  Grain: Latest event per pro_contact_id (deduplicated)
*/

WITH source AS (
    SELECT
        PARSE_JSON(RECORD_CONTENT) AS payload,
        EVENT_TIME
    FROM {{ source('fluidrapro_raw', 'raw_dealers_data') }}
    WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-contact-master%'
),

parsed AS (
    SELECT
        payload:"id"::STRING AS event_id,
        payload:"detail":"data":"proContactId"::STRING AS pro_contact_id,
        payload:"detail":"data":"firstName"::STRING AS first_name,
        payload:"detail":"data":"lastName"::STRING AS last_name,
        payload:"detail":"data":"email"::STRING AS email,
        payload:"detail":"data":"phoneNumber"::STRING AS phone_number,
        payload:"detail":"data":"contactType"::STRING AS contact_type,
        payload:"detail":"data":"loginStatus"::STRING AS login_status,
        payload:"detail":"data":"status"::STRING AS status,
        payload:"detail":"data":"cognitoSubId"::STRING AS cognito_sub_id,
        payload:"detail":"data":"username"::STRING AS username,
        payload:"detail":"data":"webUserId"::STRING AS web_user_id,
        payload:"detail":"metadata":"eventType"::STRING AS event_type,
        payload:"detail":"metadata":"correlationId"::STRING AS correlation_id,
        payload:"detail":"metadata":"service"::STRING AS service,
        payload:"source"::STRING AS source_system,
        TRY_TO_TIMESTAMP_NTZ(payload:"detail":"data":"auditInfo":"createdAt"::STRING) AS created_at,
        TRY_TO_TIMESTAMP_NTZ(payload:"detail":"data":"auditInfo":"updatedAt"::STRING) AS updated_at,
        EVENT_TIME AS event_time,
        ROW_NUMBER() OVER (
            PARTITION BY payload:"detail":"data":"proContactId"::STRING
            ORDER BY EVENT_TIME DESC
        ) AS rn
    FROM source
    WHERE payload:"detail":"data":"proContactId" IS NOT NULL
)

SELECT
    event_id,
    pro_contact_id,
    first_name,
    last_name,
    email,
    phone_number,
    contact_type,
    login_status,
    status,
    cognito_sub_id,
    username,
    web_user_id,
    event_type,
    correlation_id,
    service,
    source_system,
    created_at,
    updated_at,
    event_time
FROM parsed
WHERE rn = 1
