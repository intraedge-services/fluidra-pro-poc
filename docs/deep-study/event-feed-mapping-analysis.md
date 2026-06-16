# Event-to-Entity Mapping & Feed Analysis

## Overview

This document maps the **Pro Business Master entity fields** (from the business specification) to the **actual JSON event payloads** landing in the Snowflake data platform, combined with the **Salesforce** and **Oracle** feed requirements. It provides a complete traceability matrix from business requirement → event schema → staging model → analytics.

---

## 1. Primary Feed: Fluidra Pro Platform (AWS EventBus → Kafka CDC → S3 → Snowpipe)

### 1.1 Event JSON Structure

```json
{
  "id": "<event_uuid>",
  "source": "com.fluidra.pro",
  "detail-type": "pro-business-master-created | pro-business-master-updated | pro-business-master-approved",
  "detail": {
    "metadata": {
      "eventType": "ProBusinessMasterCreated | ProBusinessMasterUpdated | ProBusinessMasterApproved",
      "correlationId": "<uuid>",
      "service": "pro-business-service"
    },
    "data": {
      "proBusinessId": "cf4b2851-4547-4d2c-bbcd-26c104703b92",
      "businessName": "VALLEY POOL SUPPLY",
      "doingBusinessAs": "Valley Pools",
      "status": "LEAD | GUEST | ACTIVE | REJECTED | CLOSED",
      "primaryBusinessType": "BUILDER | RETAILER | SERVICE | INTERNET | COMMERCIAL SERVICE | COMMERCIAL BUILDER",
      "primaryBusinessEmail": "bob@pools.com",
      "primaryBusinessPhoneNumber": "+16126126122",
      "tseViolator": false,
      "termsAccepted": true,
      "rewardsAccount": {
        "fluidraAccountNumber": "2781",
        "programLevel": "ProEdge | Retail Select | Base Rewards",
        "programStatus": "ACTIVE | PENDING | CANCELLED",
        "achieverLevel": "Gold | Silver | Bronze",
        "region": "WEST | EAST | CENTRAL",
        "programSignupDate": "2025-03-15T00:00:00Z"
      },
      "primaryContact": {
        "proContactId": "<uuid>",
        "firstName": "BOB",
        "lastName": "BUILDER",
        "loginStatus": "ACTIVE | PENDING",
        "lastLoginDate": "2025-06-10T14:30:00Z"
      },
      "primaryBillingLocation": {
        "address": {
          "street": "2882 WHIPTAIL LOOP E #100",
          "city": "CARLSBAD",
          "state": "CA",
          "zip": "92010",
          "country": "USA"
        }
      },
      "primaryShippingLocation": {
        "address": {
          "street": "2882 WHIPTAIL LOOP E #100",
          "city": "CARLSBAD",
          "state": "CA",
          "zip": "92010",
          "country": "USA"
        },
        "locationName": "Main Warehouse",
        "locationType": "PRIMARY_SHIPPING"
      },
      "auditInfo": {
        "createdAt": "2025-03-15T10:30:00Z",
        "updatedAt": "2025-06-10T14:30:00Z",
        "createdBy": "system",
        "updatedBy": "sales-rep@fluidra.com"
      }
    }
  }
}
```

### 1.2 Event Types in Platform Feed

| detail-type | eventType | Workflow Phase | Description |
|-------------|-----------|---------------|-------------|
| `pro-business-master-created` | ProBusinessMasterCreated | Phase 2 (Registration) | New business registered on platform |
| `pro-business-master-updated` | ProBusinessMasterUpdated | Phase 5 (Post-Approval) | Business fields modified |
| `pro-business-master-approved` | ProBusinessMasterApproved | Phase 3 (M2 Approval) | Sales rep approved the lead |
| `pro-contact-master-created` | ProContactMasterCreated | Phase 2 | Contact created for business |
| `pro-contact-master-updated` | ProContactMasterUpdated | Phase 5 | Contact details updated |
| `pro-contact-login-created` | ProContactLoginCreated | Phase 5 | Login credentials provisioned |
| `pro-business-lead-created` | ProBusinessLeadCreated | Phase 3 (M2) | Lead submitted for approval |
| `pro-location-master-created` | ProLocationMasterCreated | Phase 2 | Location added to business |

---

## 2. Secondary Feed: Salesforce (CRM)

### 2.1 Feed Specification

| Attribute | Value |
|-----------|-------|
| Source System | Salesforce |
| S3 Path | `s3://fluidra-data-lake/raw/salesforce/` |
| Format | CSV |
| Raw Schema | `SALESFORCE_RAW` |
| Cadence | TBD (likely daily batch or CDC) |
| Tables | `RAW_LEADS`, `RAW_ACCOUNTS`, `RAW_CONTACTS`, `RAW_OPPORTUNITIES` |

### 2.2 Salesforce Lead → Pro Business Master Mapping

| SF Lead Field (Label) | SF Field (API Name) | Pro Business Master Field | Notes |
|----------------------|--------------------|--------------------------|---------|
| FP Business ID | `FPBusinessID__c` | `proBusinessId` | Synced from Platform after creation |
| Account | `Account__c` | `fluidraAccountNumber` | Lookup to Oracle ZP# |
| Company | `Company` | `businessName` | Lead company name |
| Status | `Status` | `status` | Maps: Lead→LEAD, Pending Customer→ACTIVE |
| Primary Business Type | `Business_Type__c` | `primaryBusinessType` | BUILDER, SERVICE, etc. |
| Secondary Business Type | `Secondary_Business_Type__c` | `secondaryBusinessTypes` | Multiple values |
| Email | `Email` | `primaryBusinessEmail` | About consent fields |
| Salutation + First Name + Last Name | `Name` | `primaryContact` | Owner contact |
| Distributor Name 1-5 | `Distributor_Name__c` through `_5__c` | `distributors` | Up to 5 distributors |
| Key Account Group | `Key_Account_Group__c` | `keyAccountTypeName` | Cody Pools, etc. |
| Key Account Role | `Key_Account_Role__c` | `keyAccountTypeRole` | Standard, Restricted, Limited |
| Shipping Address | `Shipping_*__c` fields | `primaryShippingLocation` | Street, City, State, Zip, Country |
| lastModifiedByName | `lastModifiedByName__c` | `salesRep.name` | Sales rep who modified |
| lastModifiedByEmail | `lastModifiedByEmail__c` | `salesRep.email` | Sales rep email |
| CreatedByName | `CreatedByName__c` | `salesRep.name` | SF lead: who created |
| CreatedByEmail | `CreatedByEmail__c` | `salesRep.email` | SF lead: creator email |

### 2.3 Salesforce Staging Model Requirements

```sql
-- stg_salesforce_leads (target schema)
SELECT
  lead_id,
  fp_business_id,           -- Maps to proBusinessId
  account_number,           -- Maps to fluidraAccountNumber  
  company_name,             -- Maps to businessName
  lead_status,              -- Maps to status
  business_type,            -- Maps to primaryBusinessType
  secondary_business_type,  -- Maps to secondaryBusinessTypes
  email,                    -- Maps to primaryBusinessEmail
  first_name, last_name,    -- Maps to primaryContact
  distributor_name_1..5,    -- Maps to distributors[]
  key_account_group,        -- Maps to keyAccountTypeName
  key_account_role,         -- Maps to keyAccountTypeRole
  shipping_street, shipping_city, shipping_state, shipping_zip, shipping_country,
  created_by_name, created_by_email,
  last_modified_by_name, last_modified_by_email,
  created_date,
  last_modified_date
FROM raw_salesforce_leads
```

---

## 3. Secondary Feed: Oracle ERP

### 3.1 Feed Specification

| Attribute | Value |
|-----------|-------|
| Source System | Oracle |
| S3 Path | `s3://fluidra-data-lake/raw/oracle/` |
| Format | CSV |
| Raw Schema | `ORACLE_RAW` |
| Cadence | TBD (daily batch likely) |
| Tables | `RAW_DEALER_MASTER`, `RAW_SALES_REGIONS` |

### 3.2 Oracle → Pro Business Master Mapping

| Oracle Table.Column | Pro Business Master Field | Reconciliation | Notes |
|--------------------|--------------------------|----------------|-------|
| `hz_cust_accounts_all.attribute8` | `proBusinessId` (businessID) | Platform | UUID stored in attribute8 |
| `hz_cust_accounts_all.account_number` | `fluidraAccountNumber` | Oracle (SOT) | The ZP# / customer number |
| `hz_parties.party_name` | `businessName` | Oracle (until M4) | Official name |
| `hz_parties.address1` | `primaryBusinessEmail` | Oracle | Note: email stored in address1 for FPro |
| `hz_parties.address2` | `doingBusinessAs` | Oracle (until M3) | DBA in address line 2 |
| `hz_cust_accounts_all.attribute13` | `status` | Platform | Account status |
| `hz_cust_accounts_all.sales_channel_code` | `salesChannel` | Oracle (until M2) | PIP MEMBER, Retail Select, etc. |
| `hz_cust_accounts_all.customer_class_code` | `customerClass` | Oracle (until M2) | AFTERMARKET, PIP MEMBER, etc. |
| `hz_parties.primary_phone_area_code` + `primary_phone_number` | `primaryBusinessPhoneNumber` | Oracle | Concatenate with + prefix |
| `hz_parties.state` | `primaryShippingLocation.state` | Oracle (until M3) | |
| `hz_parties.postal_code` | `primaryShippingLocation.zip` | Oracle (until M3) | |
| `hz_parties.country` | `primaryShippingLocation.country` | Oracle (until M3) | |
| `hz_parties.city` | `primaryShippingLocation.city` | Oracle (until M3) | |
| `xpip_ra_addresses.attribute3` | `primaryBusinessType` | Oracle | Business type attribute |
| `xpip_ra_addresses.attribute17` | `isCSC` | Oracle (until M2) | Contract Service Center |
| `xpip_ra_addresses.pro_edge_start_date` | `rewardsAccount.programSignupDate` | Platform | Program start from Platform |
| `xpip_ra_addresses.pro_edge_end_date` | `rewardsAccount.programLevelEndDate` | Oracle | |
| `hz_cust_accounts_all.attribute9` | `keyAccountTypeName` | Platform | Key account group |

### 3.3 Oracle Staging Model Requirements

```sql
-- stg_oracle_dealers (target schema)
SELECT
  account_number,                -- fluidraAccountNumber (ZP#)
  business_id_attribute8,        -- proBusinessId
  party_name,                    -- businessName
  address1_email,                -- primaryBusinessEmail (Oracle quirk)
  address2_dba,                  -- doingBusinessAs
  status_attribute13,            -- status
  sales_channel_code,            -- salesChannel
  customer_class_code,           -- customerClass
  phone_area_code || phone_number, -- primaryBusinessPhoneNumber
  city, state, postal_code, country,  -- primaryShippingLocation
  business_type_attribute3,      -- primaryBusinessType
  csc_attribute17,               -- isCSC
  key_account_attribute9,        -- keyAccountTypeName
  pro_edge_start_date,           -- rewardsAccount.programSignupDate
  pro_edge_end_date              -- rewardsAccount.programLevelEndDate
FROM raw_oracle_dealer_master
```

---

## 4. Complete Field Traceability Matrix

| Pro Business Master Field | Platform Event JSON Path | Salesforce Field | Oracle Column | Current SOT | dbt Staging Column |
|--------------------------|-------------------------|-----------------|--------------|-------------|-------------------|
| `proBusinessId` | `detail.data.proBusinessId` | `FPBusinessID__c` | `attribute8` | Platform | `pro_business_id` |
| `fluidraAccountNumber` | `detail.data.rewardsAccount.fluidraAccountNumber` | `Account__c` | `account_number` | Oracle | `fluidra_account_number` |
| `businessName` | `detail.data.businessName` | `Company` | `party_name` | Oracle→Platform (M4) | `business_name` |
| `doingBusinessAs` | `detail.data.doingBusinessAs` | — | `address2` | Oracle→Platform (M3) | `doing_business_as` |
| `status` | `detail.data.status` | `Status` | `attribute13` | Platform | `business_status` |
| `primaryBusinessType` | `detail.data.primaryBusinessType` | `Business_Type__c` | `attribute3` | Platform | `primary_business_type` |
| `primaryBusinessEmail` | `detail.data.primaryBusinessEmail` | `Email` | `address1` | Platform | `primary_business_email` |
| `primaryBusinessPhoneNumber` | `detail.data.primaryBusinessPhoneNumber` | — | `phone_area_code+phone_number` | Oracle→Platform | `primary_business_phone` |
| `primaryContact.firstName` | `detail.data.primaryContact.firstName` | `FirstName` | — | Platform | `primary_contact_first_name` |
| `primaryContact.lastName` | `detail.data.primaryContact.lastName` | `LastName` | — | Platform | `primary_contact_last_name` |
| `primaryContact.loginStatus` | `detail.data.primaryContact.loginStatus` | — | — | Platform | `primary_contact_login_status` |
| `rewardsAccount.programLevel` | `detail.data.rewardsAccount.programLevel` | — | `achiever_level` | Oracle | `program_level` |
| `rewardsAccount.programStatus` | `detail.data.rewardsAccount.programStatus` | — | — | Oracle | `program_status` |
| `rewardsAccount.achieverLevel` | `detail.data.rewardsAccount.achieverLevel` | — | — | Oracle | `achiever_level` |
| `rewardsAccount.region` | `detail.data.rewardsAccount.region` | — | — | Oracle | `rewards_region` |
| `primaryBillingLocation.city` | `detail.data.primaryBillingLocation.address.city` | — | `city` (billing) | Oracle→Platform (M3) | `billing_city` |
| `primaryBillingLocation.state` | `detail.data.primaryBillingLocation.address.state` | — | `state` (billing) | Oracle→Platform (M3) | `billing_state` |
| `primaryShippingLocation.city` | `detail.data.primaryShippingLocation.address.city` | `Shipping_City__c` | `city` | Oracle→Platform (M3) | — (not yet in model) |
| `salesChannel` | — (derived) | — | `sales_channel_code` | Oracle→Platform (M2) | — (not yet in model) |
| `customerClass` | — (derived) | — | `customer_class_code` | Oracle→Platform (M2) | — (not yet in model) |
| `keyAccountTypeName` | — | `Key_Account_Group__c` | `attribute9` | Platform | — (not yet in model) |
| `tseViolator` | `detail.data.tseViolator` | — | — | Platform | `tse_violator` |
| `salesRep` | — | `CreatedByName__c`, `CreatedByEmail__c` | — | Salesforce | — (not yet in model) |

---

## 5. Workflow Event → Feed Mapping

| Workflow Phase | Event Emitted | Lands In | Feed | Staging Model |
|---------------|--------------|----------|------|---------------|
| Phase 2: Registration | `ProBusinessMasterCreated` | `RAW_DEALERS_DATA` | Platform (Kafka→S3) | `stg_fluidrapro_businesses` |
| Phase 2: Registration | `ProContactMasterCreated` | `RAW_DEALERS_DATA` | Platform (Kafka→S3) | `stg_fluidrapro_contacts` |
| Phase 3: M2 Approval | `ProBusinessLeadCreated` | `RAW_DEALERS_DATA` | Platform (Kafka→S3) | `stg_fluidrapro_leads` |
| Phase 3: M2 Approval | `ProBusinessMasterApproved` | `RAW_DEALERS_DATA` | Platform (Kafka→S3) | `stg_fluidrapro_businesses` |
| Phase 4: CRM Sync | Lead Created in SF | `RAW_LEADS` | Salesforce (CSV→S3) | `stg_salesforce_leads` |
| Phase 4: CRM Approval | Lead Approved/Rejected | `RAW_LEADS` (updated) | Salesforce (CSV→S3) | `stg_salesforce_leads` |
| Phase 5: Post-Approval | `ProBusinessMasterUpdated` | `RAW_DEALERS_DATA` | Platform (Kafka→S3) | `stg_fluidrapro_businesses` |
| Phase 5: Login Created | `ProContactLoginCreated` | `RAW_DEALERS_DATA` | Platform (Kafka→S3) | `stg_fluidrapro_contacts` |
| Phase 7: Oracle Setup | Account Created | `RAW_DEALER_MASTER` | Oracle (CSV→S3) | `stg_oracle_dealers` |
| Phase 7: Loyalty Setup | Rewards Enabled | `RAW_DEALER_MASTER` (updated) | Oracle (CSV→S3) | `stg_oracle_dealers` |

---

## 6. Reconciliation Logic Between Feeds

### 6.1 Dual-Key Join Pattern

```sql
-- Reconciliation join between Platform and Oracle feeds
SELECT
  p.pro_business_id,
  p.business_name AS platform_name,
  o.party_name AS oracle_name,
  p.business_status AS platform_status,
  o.status AS oracle_status,
  p.fluidra_account_number AS platform_account_num,
  o.account_number AS oracle_account_num,
  CASE 
    WHEN p.pro_business_id = o.business_id_attribute8 
     AND p.fluidra_account_number = o.account_number 
    THEN 'MATCHED'
    WHEN p.pro_business_id = o.business_id_attribute8 
     AND p.fluidra_account_number != o.account_number 
    THEN 'MISMATCH_ACCOUNT_NUMBER'
    WHEN p.pro_business_id IS NOT NULL AND o.business_id_attribute8 IS NULL
    THEN 'PLATFORM_ONLY'
    WHEN p.pro_business_id IS NULL AND o.business_id_attribute8 IS NOT NULL
    THEN 'ORACLE_ONLY'
  END AS reconciliation_status
FROM stg_fluidrapro_businesses p
FULL OUTER JOIN stg_oracle_dealers o
  ON p.pro_business_id = o.business_id_attribute8
```

### 6.2 Field-Level SOT Resolution

```sql
-- Field-level Source of Truth resolution based on milestone
SELECT
  COALESCE(p.pro_business_id, o.business_id_attribute8) AS pro_business_id,
  
  -- businessName: Oracle until M4, then Platform
  CASE WHEN current_milestone < 'M4' 
    THEN COALESCE(o.party_name, p.business_name)
    ELSE COALESCE(p.business_name, o.party_name)
  END AS business_name,
  
  -- status: Always Platform
  p.business_status AS status,
  
  -- salesChannel: Oracle until M2, then Platform
  CASE WHEN current_milestone < 'M2'
    THEN o.sales_channel_code
    ELSE p.sales_channel  -- derived by platform
  END AS sales_channel,
  
  -- fluidraAccountNumber: Always Oracle
  o.account_number AS fluidra_account_number
  
FROM stg_fluidrapro_businesses p
LEFT JOIN stg_oracle_dealers o 
  ON p.pro_business_id = o.business_id_attribute8
```

---

## 7. Gaps & Missing Fields (Not Yet in Staging Models)

| Field | Required Source | Gap Description | Priority |
|-------|----------------|-----------------|----------|
| `salesChannel` | Platform (derived) | Not in event JSON yet; needs Oracle feed until M2 | High |
| `customerClass` | Platform (derived) | Not in event JSON yet; needs Oracle feed until M2 | High |
| `businessSegment` | Platform (derived) | Not in event JSON yet; needs Oracle feed | High |
| `channel` | Platform (derived) | Not in event JSON; derived from businessType | Medium |
| `keyAccountTypeId` | Platform | Not in current events | Medium |
| `keyAccountTypeName` | Salesforce | Needs SF feed implementation | Medium |
| `keyAccountTypeRole` | Salesforce | Needs SF feed implementation | Medium |
| `isPrimaryKeyAccount` | Salesforce | Needs SF feed implementation | Medium |
| `distributors[]` | Platform | Not in current events; available in SF | Medium |
| `secondaryBusinessTypes` | Platform | Not in current events | Low |
| `isProLoginAllowed` | Platform | Not in current events | Low |
| `identityOrgId` | Platform | Added M2; needs event schema update | Low |
| `crmLeadId` | Salesforce | Needs SF feed | Low |
| `crmAccountId` | Salesforce | Needs SF feed | Low |
| `webAccountId` | Sitecore | No feed defined yet | Low |
| `subscriptions` | Platform | No event defined yet | Low |
| `utm` | Platform | Added M2 (FPW-4494); needs event inclusion | Low |

---

## 8. Recommendations

### Immediate Actions
1. **Implement Oracle feed** (`stg_oracle_dealers`) — Critical for `salesChannel`, `customerClass`, `fluidraAccountNumber`
2. **Implement Salesforce feed** (`stg_salesforce_leads`) — Needed for `keyAccount*` fields and `salesRep`
3. **Add reconciliation model** — `int_business_reconciled` that joins all 3 sources
4. **Add missing fields to business staging** — `primaryShippingLocation` fields are available in JSON but not extracted

### Platform Event Schema Requests
5. Request `salesChannel`, `customerClass`, `businessSegment`, `channel` in business events (post-M2)
6. Request `keyAccountTypeId`, `keyAccountTypeName`, `isPrimaryKeyAccount` in business events
7. Request `identityOrgId` in business events (M2 addition)
8. Request `distributors[]` array in business events

### Architecture Decisions
9. **SOT resolution should be configurable** — Use a config table mapping field→source→milestone for dynamic resolution
10. **Reconciliation failures need alerting** — Implement dbt test that flags `MISMATCH_ACCOUNT_NUMBER` cases
11. **Event ordering matters** — Ensure deduplication keeps latest event, not first
