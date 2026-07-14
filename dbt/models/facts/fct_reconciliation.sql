{{
  config(
    materialized='view',
    schema='FACTS'
  )
}}

/*
  Fact: fct_reconciliation
  Grain: One row per reconciliation run
  Source: STG_FPRO_QA_RECONCILIATION
*/

SELECT
    event_id,
    event_time,
    event_time::DATE AS event_date,
    run_id,
    entity,
    dq_structural_version,
    gatekeeper_policy_version,
    mastering_rules_version,
    decisions_prefix,
    diffs_prefix,
    identity_linkage_prefix
FROM {{ ref('stg_fpro_qa_reconciliation') }}
