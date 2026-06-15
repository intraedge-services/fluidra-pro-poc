{{
  config(materialized='view', schema='STAGING')
}}

WITH source AS (
    SELECT PARSE_JSON(RECORD_CONTENT) AS payload, EVENT_TIME
    FROM {{ source('fluidrapro_raw', 'raw_dealers_data') }}
    WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
),
parsed AS (
    SELECT
        payload:"id"::STRING AS event_id,
        payload:"detail":"data":"proBusinessId"::STRING AS pro_business_id,
        payload:"detail":"data":"businessName"::STRING AS business_name,
        payload:"detail":"data":"status"::STRING AS business_status,
        payload:"detail":"data":"primaryBusinessType"::STRING AS primary_business_type,
        payload:"detail":"data":"primaryBusinessEmail"::STRING AS primary_business_email,
        payload:"detail":"data":"primaryBusinessPhoneNumber"::STRING AS primary_business_phone,
        payload:"detail":"data":"rewardsAccount":"fluidraAccountNumber"::STRING AS fluidra_account_number,
        payload:"detail":"data":"rewardsAccount":"programLevel"::STRING AS program_level,
        payload:"detail":"data":"rewardsAccount":"programStatus"::STRING AS program_status,
        payload:"detail":"data":"rewardsAccount":"achieverLevel"::STRING AS achiever_level,
        payload:"detail":"data":"rewardsAccount":"region"::STRING AS rewards_region,
        TRY_TO_TIMESTAMP_NTZ(payload:"detail":"data":"rewardsAccount":"programSignupDate"::STRING) AS program_signup_date,
        payload:"detail":"data":"primaryContact":"proContactId"::STRING AS primary_contact_id,
        payload:"detail":"data":"primaryContact":"loginStatus"::STRING AS primary_contact_login_status,
        TRY_TO_TIMESTAMP_NTZ(payload:"detail":"data":"primaryContact":"lastLoginDate"::STRING) AS primary_contact_last_login,
        payload:"detail":"data":"primaryBillingLocation":"address":"city"::STRING AS billing_city,
        payload:"detail":"data":"primaryBillingLocation":"address":"state"::STRING AS billing_state,
        payload:"detail":"data":"primaryBillingLocation":"address":"zip"::STRING AS billing_zip,
        payload:"detail":"metadata":"eventType"::STRING AS event_type,
        payload:"source"::STRING AS source_system,
        TRY_TO_TIMESTAMP_NTZ(payload:"detail":"data":"auditInfo":"createdAt"::STRING) AS created_at,
        TRY_TO_TIMESTAMP_NTZ(payload:"detail":"data":"auditInfo":"updatedAt"::STRING) AS updated_at,
        EVENT_TIME AS event_time,
        ROW_NUMBER() OVER (PARTITION BY payload:"detail":"data":"proBusinessId"::STRING ORDER BY EVENT_TIME DESC) AS rn
    FROM source
    WHERE payload:"detail":"data":"proBusinessId" IS NOT NULL
)
SELECT * EXCLUDE(rn) FROM parsed WHERE rn = 1
