{{
  config(
    materialized='view',
    schema='STAGING'
  )
}}

WITH source AS (
    SELECT
        PARSE_JSON(RECORD_METADATA) AS metadata_json,
        PARSE_JSON(RECORD_CONTENT) AS payload
    FROM {{ source('fluidrapro_raw', 'fpro_qa') }}
    WHERE RECORD_METADATA != 'RECORD_METADATA'
      AND PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-guest-technician-master%'
),
parsed AS (
    SELECT
        payload:id::STRING AS event_id,
        payload:"detail-type"::STRING AS event_detail_type,
        payload:time::TIMESTAMP_NTZ AS event_time,
        metadata_json:offset::NUMBER AS kafka_offset,
        payload:detail.metadata.eventType::STRING AS metadata_event_type,
        payload:detail.data.proContactId::STRING AS pro_contact_id,
        payload:detail.data.firstName::STRING AS first_name,
        payload:detail.data.lastName::STRING AS last_name,
        payload:detail.data.email::STRING AS email,
        payload:detail.data.phoneNumber::STRING AS phone_number,
        payload:detail.data.loginStatus::STRING AS login_status,
        payload:detail.data.username::STRING AS username,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.createdAt::STRING) AS created_at,
        payload:detail.data.auditInfo.createdBy::STRING AS created_by,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.updatedAt::STRING) AS updated_at
    FROM source
),
deduplicated AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY pro_contact_id ORDER BY event_time DESC, kafka_offset DESC) AS rn
    FROM parsed
)
SELECT * EXCLUDE (rn) FROM deduplicated WHERE rn = 1
