{{
  config(
    materialized='view',
    schema='STAGING'
  )
}}

/*
  Staging model: stg_fpro_qa_business_subscriptions
  Source: RAW_DB_PROD.FLUIDRAPRO_RAW.FPRO_QA
  Filter: pro-business-master.* events with non-empty subscriptions[]
  Grain: One row per (pro_business_id, subscription_id) — latest state
  Pattern: LATERAL FLATTEN on subscriptions[] array
*/

WITH source AS (
    SELECT
        PARSE_JSON(RECORD_METADATA) AS metadata_json,
        PARSE_JSON(RECORD_CONTENT) AS payload
    FROM {{ source('fluidrapro_raw', 'fpro_qa') }}
    WHERE RECORD_METADATA != 'RECORD_METADATA'
      AND PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
      AND PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId IS NOT NULL
      AND PARSE_JSON(RECORD_CONTENT):detail.data.subscriptions IS NOT NULL
      AND ARRAY_SIZE(PARSE_JSON(RECORD_CONTENT):detail.data.subscriptions) > 0
),

flattened AS (
    SELECT
        payload:id::STRING AS event_id,
        payload:time::TIMESTAMP_NTZ AS event_time,
        metadata_json:offset::NUMBER AS kafka_offset,
        payload:detail.data.proBusinessId::STRING AS pro_business_id,

        -- Flattened subscription fields
        f.value:subscriptionId::STRING AS subscription_id,
        f.value:subscriptionName::STRING AS subscription_name,
        f.value:subscriptionStatus::STRING AS subscription_status,
        TRY_TO_TIMESTAMP_NTZ(f.value:programStartDate::STRING) AS program_start_date,
        f.value:source::STRING AS source,
        f.value:proBusinessId::STRING AS subscription_pro_business_id,

        -- Subscription audit
        TRY_TO_TIMESTAMP_NTZ(f.value:auditInfo.createdAt::STRING) AS subscription_created_at,
        TRY_TO_TIMESTAMP_NTZ(f.value:auditInfo.updatedAt::STRING) AS subscription_updated_at,
        f.value:auditInfo.createdBy::STRING AS subscription_created_by,
        f.value:auditInfo.updatedBy::STRING AS subscription_updated_by

    FROM source,
        LATERAL FLATTEN(input => payload:detail.data.subscriptions) f
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY pro_business_id, subscription_id
            ORDER BY event_time DESC, kafka_offset DESC
        ) AS rn
    FROM flattened
)

SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
