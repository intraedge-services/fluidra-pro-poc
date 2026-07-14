{{
  config(
    materialized='view',
    schema='STAGING'
  )
}}

/*
  Staging model: stg_fpro_qa_business_distributors
  Source: RAW_DB_PROD.FLUIDRAPRO_RAW.FPRO_QA
  Filter: pro-business-master.* events with non-empty distributors[]
  Grain: One row per (pro_business_id, distributor_name, distributor_account_number) — latest state
  Pattern: LATERAL FLATTEN on distributors[] array
*/

WITH source AS (
    SELECT
        PARSE_JSON(RECORD_METADATA) AS metadata_json,
        PARSE_JSON(RECORD_CONTENT) AS payload
    FROM {{ source('fluidrapro_raw', 'fpro_qa') }}
    WHERE RECORD_METADATA != 'RECORD_METADATA'
      AND PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
      AND PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId IS NOT NULL
      AND PARSE_JSON(RECORD_CONTENT):detail.data.distributors IS NOT NULL
      AND ARRAY_SIZE(PARSE_JSON(RECORD_CONTENT):detail.data.distributors) > 0
),

flattened AS (
    SELECT
        payload:id::STRING AS event_id,
        payload:time::TIMESTAMP_NTZ AS event_time,
        metadata_json:offset::NUMBER AS kafka_offset,
        payload:detail.data.proBusinessId::STRING AS pro_business_id,

        -- Flattened distributor fields
        f.value:distributorName::STRING AS distributor_name,
        f.value:distributorAccountNumber::STRING AS distributor_account_number,
        f.value:distributorAccountStatus::STRING AS distributor_account_status,
        f.value:fluidraAccountNumber::STRING AS fluidra_account_number,
        f.value:source::STRING AS source,
        TRY_TO_TIMESTAMP_NTZ(f.value:activeDate::STRING) AS active_date,

        -- Distributor audit
        TRY_TO_TIMESTAMP_NTZ(f.value:auditInfo.createdAt::STRING) AS distributor_created_at,
        TRY_TO_TIMESTAMP_NTZ(f.value:auditInfo.updatedAt::STRING) AS distributor_updated_at,
        f.value:auditInfo.createdBy::STRING AS distributor_created_by,
        f.value:auditInfo.updatedBy::STRING AS distributor_updated_by

    FROM source,
        LATERAL FLATTEN(input => payload:detail.data.distributors) f
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY pro_business_id, distributor_name, distributor_account_number
            ORDER BY event_time DESC, kafka_offset DESC
        ) AS rn
    FROM flattened
)

SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
