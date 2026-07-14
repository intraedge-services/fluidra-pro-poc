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
      AND PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-lead%'
),
parsed AS (
    SELECT
        payload:id::STRING AS event_id,
        payload:"detail-type"::STRING AS event_detail_type,
        payload:time::TIMESTAMP_NTZ AS event_time,
        payload:source::STRING AS event_source,
        metadata_json:offset::NUMBER AS kafka_offset,
        payload:detail.metadata.eventType::STRING AS metadata_event_type,
        payload:detail.metadata.correlationId::STRING AS correlation_id,
        payload:detail.metadata.service::STRING AS metadata_service,
        payload:detail.data.proBusinessId::STRING AS pro_business_id,
        payload:detail.data.businessName::STRING AS business_name,
        payload:detail.data.status::STRING AS lead_status,
        payload:detail.data.primaryBusinessType::STRING AS primary_business_type,
        payload:detail.data.primaryBusinessEmail::STRING AS primary_business_email,
        payload:detail.data.source::STRING AS registration_source,
        payload:detail.data.crmLeadId::STRING AS crm_lead_id,
        payload:detail.data.salesRep.name::STRING AS sales_rep_name,
        payload:detail.data.salesRep.email::STRING AS sales_rep_email,
        payload:detail.data.primaryContact.firstName::STRING AS contact_first_name,
        payload:detail.data.primaryContact.lastName::STRING AS contact_last_name,
        payload:detail.data.primaryContact.email::STRING AS contact_email,
        payload:detail.data.primaryBillingLocation.address.city::STRING AS billing_city,
        payload:detail.data.primaryBillingLocation.address.state::STRING AS billing_state,
        payload:detail.data.primaryBillingLocation.address.zip::STRING AS billing_zip,
        COALESCE(ARRAY_SIZE(payload:detail.data.distributors), 0) AS distributor_count,
        COALESCE(ARRAY_SIZE(payload:detail.data.programOptIns), 0) AS program_opt_in_count,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.createdAt::STRING) AS submission_time,
        payload:detail.data.auditInfo.createdBy::STRING AS submitted_by,
        CASE WHEN payload:"detail-type"::STRING LIKE '%approved%' THEN TRUE ELSE FALSE END AS is_approved,
        CASE WHEN payload:"detail-type"::STRING LIKE '%rejected%' THEN TRUE ELSE FALSE END AS is_rejected,
        DATEDIFF('second', TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.createdAt::STRING), payload:time::TIMESTAMP_NTZ) AS seconds_to_decision
    FROM source
)
SELECT * FROM parsed
