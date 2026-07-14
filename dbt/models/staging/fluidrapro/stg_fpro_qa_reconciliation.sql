{{
  config(
    materialized='view',
    schema='STAGING'
  )
}}

WITH source AS (
    SELECT
        PARSE_JSON(C1) AS metadata_json,
        PARSE_JSON(C2) AS payload
    FROM {{ source('fluidrapro_raw', 'fpro_qa') }}
    WHERE C1 != 'RECORD_METADATA'
      AND PARSE_JSON(C2):"detail-type"::STRING = 'fluidrapro.pro-reconcile.completed.v1'
),
parsed AS (
    SELECT
        payload:id::STRING AS event_id,
        payload:time::TIMESTAMP_NTZ AS event_time,
        metadata_json:offset::NUMBER AS kafka_offset,
        payload:detail.data.runId::STRING AS run_id,
        payload:detail.data.entity::STRING AS entity,
        payload:detail.data.config.dqStructural::STRING AS dq_structural_version,
        payload:detail.data.config.gatekeeperPolicy::STRING AS gatekeeper_policy_version,
        payload:detail.data.config.masteringRules::STRING AS mastering_rules_version,
        payload:detail.data.decisionsPrefix::STRING AS decisions_prefix,
        payload:detail.data.diffsPrefix::STRING AS diffs_prefix,
        payload:detail.data.identityLinkagePrefix::STRING AS identity_linkage_prefix
    FROM source
)
SELECT * FROM parsed
