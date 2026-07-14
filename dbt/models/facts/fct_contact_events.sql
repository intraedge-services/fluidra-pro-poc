{{
  config(
    materialized='view',
    schema='FACTS'
  )
}}

/*
  Fact: fct_contact_events
  Grain: One row per contact event
  Source: FPRO_QA → pro-contact-master.* events
*/

WITH source AS (
    SELECT
        PARSE_JSON(C1) AS metadata_json,
        PARSE_JSON(C2) AS payload
    FROM {{ source('fluidrapro_raw', 'fpro_qa') }}
    WHERE C1 != 'RECORD_METADATA'
      AND PARSE_JSON(C2):"detail-type"::STRING LIKE '%pro-contact-master%'
),
parsed AS (
    SELECT
        payload:id::STRING AS event_id,
        payload:"detail-type"::STRING AS event_detail_type,
        payload:time::TIMESTAMP_NTZ AS event_time,
        payload:time::DATE AS event_date,
        metadata_json:offset::NUMBER AS kafka_offset,
        payload:detail.metadata.eventType::STRING AS metadata_event_type,
        payload:detail.metadata.correlationId::STRING AS correlation_id,
        payload:detail.data.proContactId::STRING AS pro_contact_id,
        payload:detail.data.proBusinessId::STRING AS pro_business_id,
        payload:detail.data.contactType::STRING AS contact_type,
        payload:detail.data.loginStatus::STRING AS login_status,
        payload:detail.data.status::STRING AS contact_status,
        payload:detail.data.email::STRING AS email,
        payload:detail.data.source::STRING AS source,
        CASE WHEN payload:"detail-type"::STRING LIKE '%created.v1' THEN 1 ELSE 0 END AS is_created_event,
        CASE WHEN payload:"detail-type"::STRING LIKE '%updated.v1' THEN 1 ELSE 0 END AS is_updated_event,
        CASE WHEN payload:"detail-type"::STRING LIKE '%login-created%' THEN 1 ELSE 0 END AS is_login_created_event,
        CASE WHEN payload:"detail-type"::STRING LIKE '%deleted%' THEN 1 ELSE 0 END AS is_deleted_event,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.createdAt::STRING) AS record_created_at
    FROM source
    WHERE payload:detail.data.proContactId IS NOT NULL
)
SELECT * FROM parsed
QUALIFY ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY kafka_offset DESC) = 1
