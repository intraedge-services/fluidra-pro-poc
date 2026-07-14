{{
  config(
    materialized='view',
    schema='STAGING'
  )
}}

/*
  Staging model: stg_fpro_qa_businesses
  Source: RAW_DB_PROD.FLUIDRAPRO_RAW.FPRO_QA
  Filter: pro-business-master.* events (created, updated, approved, rejected, creation-failed, update-requested)
  Grain: Latest event per pro_business_id (deduplicated)
  Note: Scalar fields only. Arrays (distributors, programOptIns, subscriptions) are in separate models.
*/

WITH source AS (
    SELECT
        PARSE_JSON(C1) AS metadata_json,
        PARSE_JSON(C2) AS payload
    FROM {{ source('fluidrapro_raw', 'fpro_qa') }}
    WHERE C1 != 'RECORD_METADATA'
      AND PARSE_JSON(C2):"detail-type"::STRING LIKE '%pro-business-master%'
      AND PARSE_JSON(C2):detail.data.proBusinessId IS NOT NULL
),

parsed AS (
    SELECT
        -- Event envelope
        payload:id::STRING AS event_id,
        payload:"detail-type"::STRING AS event_detail_type,
        payload:time::TIMESTAMP_NTZ AS event_time,
        payload:source::STRING AS event_source,
        payload:region::STRING AS event_region,

        -- Kafka metadata
        metadata_json:offset::NUMBER AS kafka_offset,
        metadata_json:partition::NUMBER AS kafka_partition,
        metadata_json:topic::STRING AS kafka_topic,

        -- Event metadata
        payload:detail.metadata.eventType::STRING AS metadata_event_type,
        payload:detail.metadata.correlationId::STRING AS correlation_id,
        payload:detail.metadata.service::STRING AS metadata_service,
        payload:detail.metadata.subDomain::STRING AS metadata_sub_domain,
        payload:detail.metadata.payloadVersion::STRING AS payload_version,
        payload:detail.metadata.fieldsUpdated AS fields_updated_array,

        -- Business Identity
        payload:detail.data.proBusinessId::STRING AS pro_business_id,
        payload:detail.data.businessName::STRING AS business_name,
        payload:detail.data.doingBusinessAs::STRING AS doing_business_as,
        payload:detail.data.status::STRING AS business_status,
        payload:detail.data.loginStatus::STRING AS login_status,
        payload:detail.data.source::STRING AS registration_source,

        -- Classification
        payload:detail.data.customerType::STRING AS customer_type,
        payload:detail.data.primaryBusinessType::STRING AS primary_business_type,
        payload:detail.data.businessSegment::STRING AS business_segment,
        payload:detail.data.channel::STRING AS channel,
        payload:detail.data.customerClass::STRING AS customer_class,
        payload:detail.data.salesChannel::STRING AS sales_channel,

        -- Contact Info
        payload:detail.data.primaryBusinessEmail::STRING AS primary_business_email,
        payload:detail.data.primaryBusinessPhoneNumber::STRING AS primary_business_phone,
        payload:detail.data.website::STRING AS website,

        -- Key Account
        payload:detail.data.isPrimaryKeyAccount::BOOLEAN AS is_primary_key_account,
        payload:detail.data.keyAccountTypeName::STRING AS key_account_type_name,
        payload:detail.data.keyAccountTypeRole::STRING AS key_account_type_role,

        -- External Join Keys
        payload:detail.data.fluidraAccountNumber::STRING AS fluidra_account_number,
        payload:detail.data.crmLeadId::STRING AS crm_lead_id,
        payload:detail.data.webAccountId::STRING AS web_account_id,

        -- Flags
        payload:detail.data.isProLoginAllowed::BOOLEAN AS is_pro_login_allowed,
        payload:detail.data.termsAccepted::BOOLEAN AS terms_accepted,
        payload:detail.data.eStatementEnabled::BOOLEAN AS e_statement_enabled,
        payload:detail.data.isMarComConsent::BOOLEAN AS is_marcom_consent,
        payload:detail.data.tseViolator::BOOLEAN AS tse_violator,

        -- Rewards Account (nested object, 1:1)
        payload:detail.data.rewardsAccount.programLevel::STRING AS rewards_program_level,
        payload:detail.data.rewardsAccount.achieverLevel::STRING AS rewards_achiever_level,
        payload:detail.data.rewardsAccount.programStatus::STRING AS rewards_program_status,
        payload:detail.data.rewardsAccount.rebatePayType::STRING AS rewards_rebate_pay_type,
        payload:detail.data.rewardsAccount.region::STRING AS rewards_region,
        payload:detail.data.rewardsAccount.enableAutoZodiacPremium::BOOLEAN AS rewards_auto_zodiac,
        payload:detail.data.rewardsAccount.overrideAchieverLevelRoll::BOOLEAN AS rewards_override_level,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.rewardsAccount.programSignupDate::STRING) AS rewards_signup_date,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.rewardsAccount.programLevelStartDate::STRING) AS rewards_level_start_date,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.rewardsAccount.achieverLevelStartDate::STRING) AS rewards_achiever_start_date,

        -- Primary Contact (nested object, 1:1)
        payload:detail.data.primaryContact.proContactId::STRING AS primary_contact_id,
        payload:detail.data.primaryContact.contactType::STRING AS primary_contact_type,
        payload:detail.data.primaryContact.firstName::STRING AS primary_contact_first_name,
        payload:detail.data.primaryContact.lastName::STRING AS primary_contact_last_name,
        payload:detail.data.primaryContact.email::STRING AS primary_contact_email,
        payload:detail.data.primaryContact.loginStatus::STRING AS primary_contact_login_status,
        payload:detail.data.primaryContact.username::STRING AS primary_contact_username,
        payload:detail.data.primaryContact.cognitoSubId::STRING AS primary_contact_cognito_sub_id,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.primaryContact.lastLoginDate::STRING) AS primary_contact_last_login,

        -- Primary Billing Location (nested object, 1:1)
        payload:detail.data.primaryBillingLocation.proLocationId::STRING AS billing_location_id,
        payload:detail.data.primaryBillingLocation.address.city::STRING AS billing_city,
        payload:detail.data.primaryBillingLocation.address.state::STRING AS billing_state,
        payload:detail.data.primaryBillingLocation.address.zip::STRING AS billing_zip,
        payload:detail.data.primaryBillingLocation.address.country::STRING AS billing_country,
        payload:detail.data.primaryBillingLocation.address.streetLine1::STRING AS billing_street,

        -- Primary Shipping Location (nested object, 1:1)
        payload:detail.data.primaryShippingLocation.proLocationId::STRING AS shipping_location_id,
        payload:detail.data.primaryShippingLocation.address.city::STRING AS shipping_city,
        payload:detail.data.primaryShippingLocation.address.state::STRING AS shipping_state,
        payload:detail.data.primaryShippingLocation.address.zip::STRING AS shipping_zip,
        payload:detail.data.primaryShippingLocation.address.country::STRING AS shipping_country,

        -- Sales Rep (nested object, 1:1)
        payload:detail.data.salesRep.name::STRING AS sales_rep_name,
        payload:detail.data.salesRep.email::STRING AS sales_rep_email,

        -- UTM Attribution (nested object, 1:1)
        payload:detail.data.utm.utm_source::STRING AS utm_source,
        payload:detail.data.utm.utm_medium::STRING AS utm_medium,
        payload:detail.data.utm.utm_campaign::STRING AS utm_campaign,
        payload:detail.data.utm.utm_content::STRING AS utm_content,
        payload:detail.data.utm.utm_term::STRING AS utm_term,

        -- Array sizes (measures, not flattened here)
        COALESCE(ARRAY_SIZE(payload:detail.data.distributors), 0) AS distributor_count,
        COALESCE(ARRAY_SIZE(payload:detail.data.programOptIns), 0) AS program_opt_in_count,
        COALESCE(ARRAY_SIZE(payload:detail.data.subscriptions), 0) AS subscription_count,
        COALESCE(ARRAY_SIZE(payload:detail.data.secondaryBusinessTypes), 0) AS secondary_type_count,

        -- Secondary business types as array (for reference, not flattened here)
        payload:detail.data.secondaryBusinessTypes AS secondary_business_types_array,

        -- Audit
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.createdAt::STRING) AS created_at,
        payload:detail.data.auditInfo.createdBy::STRING AS created_by,
        TRY_TO_TIMESTAMP_NTZ(payload:detail.data.auditInfo.updatedAt::STRING) AS updated_at,
        payload:detail.data.auditInfo.updatedBy::STRING AS updated_by,

        -- Failure detail (only on creation-failed events)
        payload:detail.data.reason::STRING AS failure_reason

    FROM source
),

deduplicated AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY pro_business_id
            ORDER BY event_time DESC, kafka_offset DESC
        ) AS rn
    FROM parsed
)

SELECT * EXCLUDE (rn)
FROM deduplicated
WHERE rn = 1
