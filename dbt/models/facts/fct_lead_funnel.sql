{{
  config(
    materialized='view',
    schema='FACTS'
  )
}}

/*
  Fact: fct_lead_funnel
  Grain: One row per funnel stage transition
  Source: FPRO_QA → created, approved, rejected, creation-failed events
*/

WITH source AS (
    SELECT
        PARSE_JSON(C1) AS metadata_json,
        PARSE_JSON(C2) AS payload
    FROM {{ source('fluidrapro_raw', 'fpro_qa') }}
    WHERE C1 != 'RECORD_METADATA'
      AND PARSE_JSON(C2):"detail-type"::STRING IN (
          'fluidrapro.pro-business-master.created.v1',
          'fluidrapro.pro-business-master.approved.v1',
          'fluidrapro.pro-business-master.rejected.v1',
          'fluidrapro.pro-business-master.creation-failed.v1',
          'fluidrapro.pro-business-lead.approved.v1',
          'fluidrapro.pro-business-lead.rejected.v1'
      )
),
parsed AS (
    SELECT
        payload:id::STRING AS event_id,
        payload:"detail-type"::STRING AS event_detail_type,
        payload:time::TIMESTAMP_NTZ AS event_time,
        payload:time::DATE AS event_date,
        metadata_json:offset::NUMBER AS kafka_offset,
        payload:detail.metadata.correlationId::STRING AS correlation_id,
        payload:detail.data.proBusinessId::STRING AS pro_business_id,
        payload:detail.data.primaryBusinessEmail::STRING AS primary_email,
        payload:detail.data.crmLeadId::STRING AS crm_lead_id,
        payload:detail.data.salesRep.name::STRING AS sales_rep_name,
        payload:detail.data.salesRep.email::STRING AS sales_rep_email,
        payload:detail.data.status::STRING AS business_status,
        payload:detail.data.primaryBusinessType::STRING AS primary_business_type,
        payload:detail.data.source::STRING AS registration_source,
        CASE
            WHEN payload:"detail-type"::STRING LIKE '%created%' AND payload:detail.data.status::STRING = 'GUEST' THEN 'GUEST'
            WHEN payload:"detail-type"::STRING LIKE '%created%' AND payload:detail.data.status::STRING = 'LEAD' THEN 'LEAD_CREATED'
            WHEN payload:"detail-type"::STRING LIKE '%created%' THEN 'BUSINESS_CREATED'
            WHEN payload:"detail-type"::STRING = 'fluidrapro.pro-business-lead.approved.v1' THEN 'LEAD_APPROVED'
            WHEN payload:"detail-type"::STRING = 'fluidrapro.pro-business-master.approved.v1' THEN 'BUSINESS_APPROVED'
            WHEN payload:"detail-type"::STRING LIKE '%lead.rejected%' THEN 'LEAD_REJECTED'
            WHEN payload:"detail-type"::STRING LIKE '%master.rejected%' THEN 'BUSINESS_REJECTED'
            WHEN payload:"detail-type"::STRING LIKE '%creation-failed%' THEN 'CREATION_FAILED'
            ELSE 'OTHER'
        END AS funnel_stage,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.createdAt::STRING) AS submission_time,
        DATEDIFF('second', TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.createdAt::STRING), payload:time::TIMESTAMP_NTZ) AS seconds_in_stage,
        payload:detail.data.reason::STRING AS failure_reason
    FROM source
)
SELECT * FROM parsed
QUALIFY ROW_NUMBER() OVER (PARTITION BY event_id ORDER BY kafka_offset DESC) = 1
