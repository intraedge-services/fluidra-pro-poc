{{
  config(
    materialized='view',
    schema='STAGING'
  )
}}

/*
  Staging model: stg_fpro_qa_business_program_optins
  Source: RAW_DB_PROD.FLUIDRAPRO_RAW.FPRO_QA
  Filter: pro-business-master.* events with non-empty programOptIns[]
  Grain: One row per (pro_business_id, program_name) — latest state
  Pattern: LATERAL FLATTEN on programOptIns[] array
*/

WITH source AS (
    SELECT
        PARSE_JSON(C1) AS metadata_json,
        PARSE_JSON(C2) AS payload
    FROM {{ source('fluidrapro_raw', 'fpro_qa') }}
    WHERE C1 != 'RECORD_METADATA'
      AND PARSE_JSON(C2):"detail-type"::STRING LIKE '%pro-business-master%'
      AND PARSE_JSON(C2):detail.data.proBusinessId IS NOT NULL
      AND PARSE_JSON(C2):detail.data.programOptIns IS NOT NULL
      AND ARRAY_SIZE(PARSE_JSON(C2):detail.data.programOptIns) > 0
),

flattened AS (
    SELECT
        payload:id::STRING AS event_id,
        payload:time::TIMESTAMP_NTZ AS event_time,
        metadata_json:offset::NUMBER AS kafka_offset,
        payload:detail.data.proBusinessId::STRING AS pro_business_id,

        -- Flattened program opt-in fields
        f.value:programName::STRING AS program_name,
        f.value:programStatus::STRING AS program_status,
        TRY_TO_TIMESTAMP_NTZ(f.value:programOptInDate::STRING) AS program_opt_in_date,
        TRY_TO_TIMESTAMP_NTZ(f.value:programStartDate::STRING) AS program_start_date,
        f.value:source::STRING AS source,
        f.value:fluidraAccountNumber::STRING AS fluidra_account_number,
        f.value:proBusinessId::STRING AS program_pro_business_id,

        -- Program audit
        TRY_TO_TIMESTAMP_NTZ(f.value:auditInfo.createdAt::STRING) AS program_created_at,
        TRY_TO_TIMESTAMP_NTZ(f.value:auditInfo.updatedAt::STRING) AS program_updated_at,
        f.value:auditInfo.createdBy::STRING AS program_created_by,
        f.value:auditInfo.updatedBy::STRING AS program_updated_by

    FROM source,
        LATERAL FLATTEN(input => payload:detail.data.programOptIns) f
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY pro_business_id, program_name
            ORDER BY event_time DESC, kafka_offset DESC
        ) AS rn
    FROM flattened
)

SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
