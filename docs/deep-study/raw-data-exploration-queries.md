# RAW_DEALERS_DATA — Deep Exploration Queries

## Source Table

```
DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
```

| Property | Value |
|----------|-------|
| Records | 100 |
| Date Range | June 9–15, 2026 |
| Kafka Topic | `psot_poolpro_inbound` |
| Format | JSON (RECORD_CONTENT) + Kafka metadata (RECORD_METADATA) |

---

## Query 1: Event Landscape

> What event types exist, from which source systems?

```sql
SELECT 
  PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING AS detail_type,
  PARSE_JSON(RECORD_CONTENT):"source"::STRING AS source,
  PARSE_JSON(RECORD_CONTENT):"detail":"metadata":"eventType"::STRING AS event_type,
  PARSE_JSON(RECORD_CONTENT):"detail":"metadata":"domain"::STRING AS domain,
  PARSE_JSON(RECORD_CONTENT):"detail":"metadata":"subDomain"::STRING AS sub_domain,
  PARSE_JSON(RECORD_CONTENT):"detail":"metadata":"service"::STRING AS service,
  COUNT(*) AS event_count
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
GROUP BY 1,2,3,4,5,6
ORDER BY event_count DESC;
```

**Results:**

| detail_type | source | event_type | count |
|-------------|--------|-----------|-------|
| fluidrapro.pro-business-master.updated.v1 | pro-platform-core | updated | 41 |
| fluidrapro.pro-contact-master.updated.v1 | pro-platform-core | updated | 20 |
| fluidrapro.pro-contact-master.created.v1 | pro-platform-core | created | 17 |
| fluidrapro.pro-contact-master.login-created.v1 | pro-platform-core | login-created | 13 |
| fluidrapro.pro-business-master.created.v1 | pro-platform-core | created | 3 |
| fluidrapro.pro-reconcile.completed.v1 | reconciler | (null) | 2 |
| fluidrapro.pro-location-master.created.v1 | pro-platform-core | created | 1 |
| fluidrapro.pro-location-master.updated.v1 | pro-platform-core | updated | 1 |
| fluidrapro.pro-business-lead.approved.v1 | salesforce | approved | 1 |
| fluidrapro.pro-business-master.approved.v1 | pro-platform-core | approved | 1 |

---

## Query 2: Business Master — All Distinct Combinations

> Every combination of status, type, program, achiever level present in the data.

```sql
SELECT 
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"status"::STRING AS business_status,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryBusinessType"::STRING AS primary_biz_type,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"rewardsAccount":"programLevel"::STRING AS program_level,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"rewardsAccount":"programStatus"::STRING AS program_status,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"rewardsAccount":"achieverLevel"::STRING AS achiever_level,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"rewardsAccount":"region"::STRING AS region,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"tseViolator"::STRING AS tse_violator,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"termsAccepted"::STRING AS terms_accepted,
  PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING AS event_detail_type,
  COUNT(*) AS cnt
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
GROUP BY 1,2,3,4,5,6,7,8,9
ORDER BY cnt DESC;
```

**Results:**

| status | type | program_level | program_status | achiever_level | region | cnt |
|--------|------|--------------|---------------|----------------|--------|-----|
| ACTIVE | SERVICE | (null) | (null) | (null) | (null) | 12 |
| ACTIVE | SERVICE | SERVICEPRO | PENDING | SERVICEPRO ELITE | USA | 6 |
| LEAD | BUILDER | PROEDGE | PENDING | BUILDER PROEDGE PARTNER | USA | 5 |
| ACTIVE | BUILDER | RETAIL SELECT | ACTIVE | (null) | USA | 4 |
| ACTIVE | BUILDER | PROEDGE | PENDING | BUILDER PROEDGE PARTNER | USA | 4 |
| ACTIVE | BUILDER | RETAIL SELECT | PENDING | (null) | USA | 3 |
| ACTIVE | SERVICE | SERVICEPRO | ACTIVE | (null) | USA | 3 |
| ACTIVE | RETAILER | RETAIL SELECT | ACTIVE | (null) | USA | 2 |
| ACTIVE | RETAILER | (null) | (null) | (null) | (null) | 2 |
| ACTIVE | SERVICE | BASE REWARDS | ACTIVE | (null) | USA | 1 |
| ACTIVE | SERVICE | FLATRATE SERVICEPRO | ACTIVE | SERVICEPRO ELITE | USA | 1 |
| ACTIVE | BUILDER | BASE REWARDS | ACTIVE | (null) | USA | 1 |
| ACTIVE | BUILDER | PROEDGE | ACTIVE | BUILDER PROEDGE PARTNER | USA | 1 |

---

## Query 3: Contact Master — All Contact Types & Login Statuses

> Every combination of contact type, login status, and event type.

```sql
SELECT 
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"contactType"::STRING AS contact_type,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"loginStatus"::STRING AS login_status,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"status"::STRING AS contact_status,
  PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING AS detail_type,
  COUNT(*) AS cnt
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-contact-master%'
GROUP BY 1,2,3,4
ORDER BY cnt DESC;
```

**Results:**

| contact_type | login_status | status | event | cnt |
|-------------|-------------|--------|-------|-----|
| TECHNICIAN | PENDING | ACTIVE | created | 11 |
| TECHNICIAN | ACTIVE | ACTIVE | updated | 7 |
| OWNER | ACTIVE | ACTIVE | updated | 7 |
| TECHNICIAN | ACTIVE | ACTIVE | login-created | 6 |
| OWNER | PENDING | ACTIVE | created | 3 |
| OWNER | ACTIVE | ACTIVE | login-created | 3 |
| CSC | ACTIVE | ACTIVE | login-created | 2 |
| CSC | ACTIVE | ACTIVE | updated | 2 |
| CO-OWNER | PENDING | ACTIVE | updated | 1 |
| OTHER | ACTIVE | ACTIVE | updated | 1 |
| CSC | PENDING | ACTIVE | created | 1 |
| OTHER | ACTIVE | ACTIVE | login-created | 1 |
| TECHNICIAN | PENDING | ACTIVE | updated | 1 |
| OFFICE ADMIN | ACTIVE | ACTIVE | updated | 1 |
| OFFICE ADMIN | ACTIVE | ACTIVE | login-created | 1 |
| OFFICE ADMIN | PENDING | ACTIVE | created | 1 |
| OTHER | PENDING | ACTIVE | created | 1 |

---

## Query 4: Fields Updated in Update Events

> What fields actually change when update events are emitted?

```sql
SELECT 
  PARSE_JSON(RECORD_CONTENT):"detail":"metadata":"fieldsUpdated"::STRING AS fields_updated,
  PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING AS detail_type,
  COUNT(*) AS cnt
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
WHERE PARSE_JSON(RECORD_CONTENT):"detail":"metadata":"eventType"::STRING = 'updated'
GROUP BY 1,2
ORDER BY cnt DESC;
```

**Results:**

| fields_updated | detail_type | cnt |
|---------------|-------------|-----|
| `["distributors"]` | pro-business-master.updated | 13 |
| `["webAccountId","loginStatus","subscriptionId"]` | pro-contact-master.updated | 7 |
| `["webAccountId","loginStatus","subscriptionId"]` | pro-business-master.updated | 6 |
| `["rewardsAccount","fluidraAccountNumber","status"]` | pro-business-master.updated | 4 |
| `["eStatementEnabled"]` | pro-business-master.updated | 1 |
| `["eStatementEnabled","primaryBusinessPhoneNumber"]` | pro-business-master.updated | 1 |

---

## Query 5: Distributors — All Names & Statuses

> Flattens the distributors array to show all distributor relationships.

```sql
SELECT 
  d.value:"distributorName"::STRING AS distributor_name,
  d.value:"distributorAccountNumber"::STRING AS distributor_account_num,
  d.value:"distributorAccountStatus"::STRING AS distributor_status,
  d.value:"source"::STRING AS distributor_source,
  COUNT(*) AS cnt
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA,
  LATERAL FLATTEN(input => PARSE_JSON(RECORD_CONTENT):"detail":"data":"distributors") d
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
GROUP BY 1,2,3,4
ORDER BY cnt DESC;
```

---

## Query 6: Program Opt-Ins

> All programs that dealers have opted into.

```sql
SELECT 
  p.value:"programName"::STRING AS program_name,
  p.value:"programStatus"::STRING AS program_status,
  COUNT(*) AS cnt
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA,
  LATERAL FLATTEN(input => PARSE_JSON(RECORD_CONTENT):"detail":"data":"programOptIns") p
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
GROUP BY 1,2
ORDER BY cnt DESC;
```

---

## Query 7: Secondary Business Types

> All secondary types assigned to businesses.

```sql
SELECT 
  s.value::STRING AS secondary_type,
  COUNT(*) AS cnt
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA,
  LATERAL FLATTEN(input => PARSE_JSON(RECORD_CONTENT):"detail":"data":"secondaryBusinessTypes") s
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
GROUP BY 1
ORDER BY cnt DESC;
```

**Result:** `BUILDER` (found in some SERVICE-primary businesses)

---

## Query 8: UTM Marketing Parameters

> All marketing campaign tracking values in the data.

```sql
SELECT 
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"utm":"utm_source"::STRING AS utm_source,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"utm":"utm_medium"::STRING AS utm_medium,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"utm":"utm_campaign"::STRING AS utm_campaign,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"utm":"utm_content"::STRING AS utm_content,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"utm":"utm_term"::STRING AS utm_term,
  COUNT(*) AS cnt
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
WHERE PARSE_JSON(RECORD_CONTENT):"detail":"data":"utm" IS NOT NULL
GROUP BY 1,2,3,4,5
ORDER BY cnt DESC;
```

**Result:**

| utm_source | utm_medium | utm_campaign | utm_content | utm_term |
|-----------|-----------|-------------|-------------|----------|
| sitecore | email | fp_welcome | complete_setup | added_by_owner |

---

## Query 9: Location Master — All Types & Statuses

> Every location event with its attributes.

```sql
SELECT 
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"locationType"::STRING AS location_type,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"locationStatus"::STRING AS location_status,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"address":"state"::STRING AS state,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"hideLocation"::STRING AS hide_location,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"hideAddress"::STRING AS hide_address,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"isEmailLeadsEnabled"::STRING AS email_leads_enabled,
  PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING AS detail_type
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-location-master%';
```

**Result:**

| location_type | status | state | hide_location | hide_address | event |
|--------------|--------|-------|---------------|-------------|-------|
| STORE | ACTIVE | AZ | false | false | created |
| STORE | ACTIVE | AZ | false | false | updated |

---

## Query 10: User Subscriptions (ION Pool Care)

> Subscription details for contacts with subscriptions.

```sql
SELECT 
  sub.value:"subscriptionName"::STRING AS subscription_name,
  sub.value:"subscriptionUserRole"::STRING AS subscription_role,
  sub.value:"status"::STRING AS subscription_status,
  COUNT(*) AS cnt
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA,
  LATERAL FLATTEN(input => PARSE_JSON(RECORD_CONTENT):"detail":"data":"userSubscriptions") sub
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-contact-master%'
GROUP BY 1,2,3
ORDER BY cnt DESC;
```

**Result:**

| subscription_name | role | status |
|------------------|------|--------|
| ION POOL CARE | POOL CLEANER | ACTIVE |

---

## Query 11: Full Business Snapshot (Latest State Per Business)

> One row per unique business showing their current state (deduplicated).

```sql
SELECT 
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"proBusinessId"::STRING AS pro_business_id,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"businessName"::STRING AS business_name,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"doingBusinessAs"::STRING AS dba,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"status"::STRING AS status,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryBusinessType"::STRING AS primary_type,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryBusinessEmail"::STRING AS email,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryBusinessPhoneNumber"::STRING AS phone,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"rewardsAccount":"programLevel"::STRING AS program_level,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"rewardsAccount":"programStatus"::STRING AS program_status,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"rewardsAccount":"achieverLevel"::STRING AS achiever_level,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"rewardsAccount":"fluidraAccountNumber"::STRING AS fluidra_acct_num,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"rewardsAccount":"region"::STRING AS region,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryContact":"firstName"::STRING AS contact_first,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryContact":"lastName"::STRING AS contact_last,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryContact":"loginStatus"::STRING AS contact_login_status,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryContact":"lastLoginDate"::STRING AS last_login,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryBillingLocation":"address":"city"::STRING AS billing_city,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryBillingLocation":"address":"state"::STRING AS billing_state,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"primaryShippingLocation":"address":"state"::STRING AS shipping_state,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"tseViolator"::BOOLEAN AS tse_violator,
  ARRAY_SIZE(PARSE_JSON(RECORD_CONTENT):"detail":"data":"distributors") AS distributor_count,
  ARRAY_SIZE(PARSE_JSON(RECORD_CONTENT):"detail":"data":"programOptIns") AS program_optin_count,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"auditInfo":"createdAt"::STRING AS created_at,
  PARSE_JSON(RECORD_CONTENT):"detail":"data":"auditInfo":"updatedAt"::STRING AS updated_at,
  EVENT_TIME
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY PARSE_JSON(RECORD_CONTENT):"detail":"data":"proBusinessId"::STRING 
  ORDER BY EVENT_TIME DESC
) = 1
ORDER BY EVENT_TIME DESC;
```

---

## Query 12: Reconcile Events

> Full payload of data reconciliation events.

```sql
SELECT 
  PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING AS detail_type,
  PARSE_JSON(RECORD_CONTENT):"source"::STRING AS source,
  PARSE_JSON(RECORD_CONTENT):"detail" AS full_detail,
  EVENT_TIME
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%reconcile%';
```

---

## Query 13: Event Timeline

> Distribution of events over time for trend analysis.

```sql
SELECT 
  DATE(EVENT_TIME) AS event_date,
  PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING AS detail_type,
  COUNT(*) AS events
FROM DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA
GROUP BY 1,2
ORDER BY 1,2;
```

---

## Summary: Distinct Values Found in Data

| Dimension | Distinct Values |
|-----------|----------------|
| **Event Types (detail-type)** | 10 unique event types |
| **Business Statuses** | ACTIVE, LEAD |
| **Primary Business Types** | SERVICE, BUILDER, RETAILER |
| **Program Levels** | PROEDGE, SERVICEPRO, RETAIL SELECT, BASE REWARDS, FLATRATE SERVICEPRO |
| **Program Statuses** | ACTIVE, PENDING |
| **Achiever Levels** | SERVICEPRO ELITE, BUILDER PROEDGE PARTNER |
| **Regions** | USA |
| **Contact Types** | OWNER, CO-OWNER, TECHNICIAN, CSC, OFFICE ADMIN, OTHER |
| **Contact Login Statuses** | ACTIVE, PENDING, DISABLE_PENDING |
| **Location Types** | STORE |
| **Location Statuses** | ACTIVE |
| **Distributor Statuses** | PENDING INACTIVE, PENDING ACTIVE |
| **Subscription Names** | ION POOL CARE |
| **Subscription Roles** | POOL CLEANER |
| **UTM Sources** | sitecore |
| **UTM Campaigns** | fp_welcome |
| **Fields Updated (business)** | distributors, webAccountId, loginStatus, subscriptionId, rewardsAccount, fluidraAccountNumber, status, eStatementEnabled, primaryBusinessPhoneNumber |
| **Source Systems** | pro-platform-core (97), reconciler (2), salesforce (1) |

---

## Key Observations

1. **Business events dominate** — 45 out of 100 records are pro-business-master events
2. **Most updates are distributor changes** — 13 of 41 update events change only distributors
3. **Technicians are the most created contacts** — 11 of 17 new contacts are TECHNICIAN type
4. **All businesses are in USA region** — No international data in this sample
5. **LEAD status only on BUILDER+PROEDGE** — SERVICE and RETAILER businesses are all ACTIVE
6. **Login provisioning is active** — 13 login-created events show onboarding is happening
7. **ION POOL CARE subscription** — Only subscription type present, linked to POOL CLEANER role
8. **Reconcile events have no metadata** — domain, subDomain, service are all null for reconciler events
9. **DISABLE_PENDING login status exists** — Not documented in spec but present in data (1 record)
10. **Some businesses have no rewards account** — 14 events have null programLevel/programStatus
