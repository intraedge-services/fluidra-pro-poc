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
      AND PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-key-account-type-master%'
),
parsed AS (
    SELECT
        payload:id::STRING AS event_id,
        payload:"detail-type"::STRING AS event_detail_type,
        payload:time::TIMESTAMP_NTZ AS event_time,
        metadata_json:offset::NUMBER AS kafka_offset,
        payload:detail.metadata.eventType::STRING AS metadata_event_type,
        payload:detail.data.keyAccountTypeId::STRING AS key_account_type_id,
        payload:detail.data.keyAccountTypeName::STRING AS key_account_type_name,
        payload:detail.data.keyAccountTypeRole::STRING AS key_account_type_role,
        payload:detail.data.customerClass::STRING AS customer_class,
        payload:detail.data.salesChannel::STRING AS sales_channel,
        payload:detail.data.programName::STRING AS program_name,
        payload:detail.data.achieverLevel::STRING AS achiever_level,
        payload:detail.data.enableZodiacPremium::BOOLEAN AS enable_zodiac_premium,
        payload:detail.data.overrideAchieverLevelRole::BOOLEAN AS override_achiever_level_role,
        payload:detail.data.eStatementEnabled::BOOLEAN AS e_statement_enabled,
        payload:detail.data.printStatements::BOOLEAN AS print_statements,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.createdAt::STRING) AS created_at,
        payload:detail.data.auditInfo.createdBy::STRING AS created_by
    FROM source
),
deduplicated AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY key_account_type_id ORDER BY event_time DESC, kafka_offset DESC) AS rn
    FROM parsed
)
SELECT * EXCLUDE (rn) FROM deduplicated WHERE rn = 1
