# Snowflake Queries — KPI Verification

## Source Table
```
RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
```

**Table Structure**: 2 VARCHAR columns (`RECORD_CONTENT`, `RECORD_METADATA`) containing JSON strings.
All queries use `PARSE_JSON(RECORD_CONTENT)` to access nested fields.

---

## Data Profiling Queries

### Total Event Count
```sql
SELECT COUNT(*) as total_events
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA;
-- Result: 363
```

### Distinct Events & Date Range
```sql
SELECT
  COUNT(*) as total_events,
  COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):id::STRING) as distinct_event_ids,
  MIN(PARSE_JSON(RECORD_CONTENT):time::TIMESTAMP) as earliest_event,
  MAX(PARSE_JSON(RECORD_CONTENT):time::TIMESTAMP) as latest_event
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA;
-- Result: 363 events, 290 distinct IDs, 2026-05-11 to 2026-06-18
```

### Event Type Distribution
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING as event_type,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
GROUP BY 1
ORDER BY 2 DESC;
-- Result: 13 distinct event types. Top: updated(109), lead.approved(82), reconcile(34)
```

### Distinct Businesses
```sql
SELECT COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as distinct_businesses
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId IS NOT NULL;
-- Result: 45
```

---

## KPI 1.1 — Total Active Dealer Accounts

### Active dealers with login history
```sql
SELECT COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as active_dealers_with_login
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.loginStatus::STRING = 'ACTIVE'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.lastLoginDate IS NOT NULL;
-- Result: 11
```

### Inactive >30 days
```sql
SELECT COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as inactive_dealers
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.loginStatus::STRING = 'ACTIVE'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.lastLoginDate::TIMESTAMP
      < DATEADD('day', -30, CURRENT_TIMESTAMP());
-- Result: 8
```

---

## KPI 1.2 — Total Enrolled Dealers

```sql
SELECT COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as total_enrolled
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.status::STRING = 'ACTIVE'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.rewardsAccount.programStatus::STRING = 'ACTIVE';
-- Result: 10
```

### Program Level Breakdown
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.rewardsAccount.programLevel::STRING as program_level,
  PARSE_JSON(RECORD_CONTENT):detail.data.rewardsAccount.programStatus::STRING as program_status,
  COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as dealer_count
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.rewardsAccount IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC;
-- Result: FLATRATE SERVICEPRO/PENDING(8), PROEDGE/PENDING(5), PROEDGE/ACTIVE(4), etc.
```

---

## KPI 1.3 — Dealers Not Set Up

```sql
SELECT COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as dealers_not_setup
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.loginStatus::STRING = 'PENDING';
-- Result: 21
```

---

## KPI 1.4 — Total Inactive Dealers

```sql
-- Uses same query as KPI 1.1 inactive >30 days (see above)
-- Result: 8 dealers with lastLoginDate older than 30 days
```

---

## KPI 1.5 — New Dealer Accounts Created

```sql
SELECT COUNT(*) as new_dealers_created
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-business-master.created.v1';
-- Result: 27
```

---

## KPI 2.1 — Guest-to-Lead Conversion

### Count Guest businesses
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.status::STRING as business_status,
  COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as dealer_count
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
GROUP BY 1
ORDER BY 2 DESC;
-- Result: ACTIVE(23), LEAD(15), GUEST(6), REJECTED(1)
```

---

## KPI 2.2 — Lead Rejection Rate

### Rejection events
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.status::STRING as lead_status,
  PARSE_JSON(RECORD_CONTENT):detail.metadata.eventType::STRING as event_type,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-lead%'
GROUP BY 1, 2
ORDER BY 3 DESC;
-- Result: ACTIVE/approved(82), REJECTED/rejected(2)
```

### Rejection detail (business-master level)
```sql
SELECT PARSE_JSON(RECORD_CONTENT):detail.data
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-business-lead.rejected.v1'
LIMIT 1;
-- Result: Shows salesRep, crmLeadId, businessName, status=REJECTED
```

---

## KPI 2.3 — Time to Approve Lead

```sql
SELECT
  AVG(seconds_to_approve) as avg_seconds,
  MAX(seconds_to_approve) as max_seconds,
  MIN(seconds_to_approve) as min_seconds
FROM (
  SELECT DATEDIFF('second',
    PARSE_JSON(RECORD_CONTENT):detail.data.auditInfo.createdAt::TIMESTAMP,
    PARSE_JSON(RECORD_CONTENT):time::TIMESTAMP
  ) as seconds_to_approve
  FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
  WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-business-lead.approved.v1'
);
-- Result: Avg 5.7 seconds, Max 11 seconds, Min 3 seconds (auto-approve in test)
```

---

## KPI 2.4 — Approved to Rewards Activation

```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING as biz_id,
  PARSE_JSON(RECORD_CONTENT):detail.data.status::STRING as status,
  PARSE_JSON(RECORD_CONTENT):detail.data.rewardsAccount.programStatus::STRING as program_status,
  PARSE_JSON(RECORD_CONTENT):detail.data.rewardsAccount.auditInfo.createdAt::TIMESTAMP as rewards_created,
  PARSE_JSON(RECORD_CONTENT):time::TIMESTAMP as event_time
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.status::STRING = 'ACTIVE'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.rewardsAccount.programStatus::STRING = 'ACTIVE'
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING
  ORDER BY PARSE_JSON(RECORD_CONTENT):time::TIMESTAMP DESC
) = 1;
-- Result: 10 enrolled dealers with rewards timestamps for gap calculation
```

---

## KPI 3.1 — Total Active Users (TAU)

```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.contactType::STRING as contact_type,
  PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.loginStatus::STRING as login_status,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC;
-- Result: OWNER/PENDING(54), OWNER/ACTIVE(40), TECHNICIAN/ACTIVE(20), etc.
```

---

## KPI 3.2 — New Technician Accounts

```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.contactType::STRING as contact_type,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-contact-master.created.v1'
GROUP BY 1
ORDER BY 2 DESC;
-- Result: TECHNICIAN(7), OTHER(5), OWNER(5), OFFICE ADMIN(5), CSC(5), CO-OWNER(5)
```

---

## KPI 3.3 — Users Never Set Up

### Contacts created with PENDING login
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.loginStatus::STRING as login_status,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-contact-master.created.v1'
GROUP BY 1
ORDER BY 2 DESC;
-- Result: PENDING(29), NOLOGIN(3)
```

### Login-created events (contacts who DID set up)
```sql
SELECT COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proContactId::STRING) as login_created_contacts
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-contact-master.login-created.v1';
-- Result: 18
```

---

## KPI 3.4 — Inactive Users

```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.lastLoginDate::STRING as last_login_date,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.lastLoginDate IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC
LIMIT 10;
-- Result: Shows lastLoginDate distribution from Feb 2026 to Jun 2026
```

---

## KPI 3.5 — Time to First Login

```sql
SELECT
  c.contact_id,
  c.contact_created,
  l.login_time,
  DATEDIFF('hour', c.contact_created, l.login_time) as hours_to_first_login
FROM (
  SELECT
    PARSE_JSON(RECORD_CONTENT):detail.data.proContactId::STRING as contact_id,
    PARSE_JSON(RECORD_CONTENT):detail.data.auditInfo.createdAt::TIMESTAMP as contact_created
  FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
  WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-contact-master.created.v1'
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY PARSE_JSON(RECORD_CONTENT):detail.data.proContactId::STRING
    ORDER BY PARSE_JSON(RECORD_CONTENT):time::TIMESTAMP
  ) = 1
) c
INNER JOIN (
  SELECT
    PARSE_JSON(RECORD_CONTENT):detail.data.proContactId::STRING as contact_id,
    PARSE_JSON(RECORD_CONTENT):time::TIMESTAMP as login_time
  FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
  WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-contact-master.login-created.v1'
) l ON c.contact_id = l.contact_id
ORDER BY hours_to_first_login DESC;
-- Result: 15 matched contacts. Max: 1 hour, most: 0 hours (minutes in test env)
```

---

## KPI 3.6 — First Login Rate

```sql
-- Total contacts created (distinct)
SELECT COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proContactId::STRING) as total_contacts_created
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-contact-master.created.v1';
-- Result: 30

-- Total login-created (distinct)
SELECT COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proContactId::STRING) as login_created_contacts
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-contact-master.login-created.v1';
-- Result: 18

-- First Login Rate = 18/30 = 60%
```

---

## KPI 3.7 — Active Users per Dealer

```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING as biz_id,
  COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.proContactId::STRING) as active_users
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.loginStatus::STRING = 'ACTIVE'
  AND PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId IS NOT NULL
GROUP BY 1
HAVING COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.proContactId::STRING) > 0
ORDER BY 2 DESC
LIMIT 10;
-- Result: Range 1-2 active users per dealer
```

---

## KPI 4.1 & 4.2 — Stickiness (WAU/MAU)

```sql
-- NOT COMPUTABLE — No per-session login data available
-- Only lastLoginDate (single timestamp snapshot) exists
-- Would need query like:
--   SELECT COUNT(DISTINCT user_id) as WAU FROM login_events WHERE login_date >= CURRENT_DATE - 7
--   / SELECT COUNT(DISTINCT user_id) as MAU FROM login_events WHERE login_date >= CURRENT_DATE - 30
-- Requires: AWS Cognito event export → S3 → Snowpipe
```

---

## KPI 5.1 & 5.2 — Revenue KPIs

### Join key availability (fluidraAccountNumber)
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.fluidraAccountNumber::STRING as fluidra_account_number,
  COUNT(*) as event_count
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.fluidraAccountNumber IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;
-- Result: 10121(19), 10427(13), 10155(11), 4055165(7), etc.
-- Join key EXISTS but no revenue table to join against
```

---

## Additional Discovery Queries

### New Event: Creation Failed
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.reason::STRING as failure_reason,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-business-master.creation-failed.v1'
GROUP BY 1;
-- Result: [Business with email already exists](5)
```

### Key Account Classification (previously GAP, now available)
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.keyAccountTypeName::STRING as key_account_type,
  PARSE_JSON(RECORD_CONTENT):detail.data.keyAccountTypeRole::STRING as key_account_role,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.keyAccountTypeName IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC;
-- Result: Poolwerx/Standard(8), Poolwerx/null(3), APE/null(3), Premier Build/Restricted(2)
```

### Sales Rep Data (new dimension)
```sql
SELECT PARSE_JSON(RECORD_CONTENT):detail.data.salesRep as sales_rep
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.salesRep IS NOT NULL
LIMIT 5;
-- Result: salesRep objects with name + email (Jeet Navadhare, Abdul Muqtadir, Ashok Bade)
```

### Subscriptions (new entity)
```sql
SELECT PARSE_JSON(RECORD_CONTENT):detail.data.subscriptions as subscriptions
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.subscriptions IS NOT NULL
  AND ARRAY_SIZE(PARSE_JSON(RECORD_CONTENT):detail.data.subscriptions) > 0
LIMIT 3;
-- Result: ION POOL CARE subscriptions with subscriptionId, status=ACTIVE
```

### CRM Lead ID (Salesforce linkage)
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.crmLeadId::STRING as crm_lead_id,
  PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING as pro_business_id,
  PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING as event_type
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.crmLeadId IS NOT NULL
LIMIT 10;
-- Result: Salesforce Lead IDs (00QQJ00000...) present on approved/rejected/updated events
```

### Cognito Sub ID (auth linkage)
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.cognitoSubId::STRING as cognito_sub_id,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.primaryContact.cognitoSubId IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;
-- Result: 5 distinct Cognito sub IDs confirmed (join key for login events)
```

### Distributor Coverage
```sql
SELECT
  ARRAY_SIZE(PARSE_JSON(RECORD_CONTENT):detail.data.distributors) as distributor_count,
  COUNT(*) as event_count
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.distributors IS NOT NULL
GROUP BY 1
ORDER BY 1;
-- Result: 0-29 distributors per business event
```

### Distributor Detail (flattened)
```sql
SELECT
  f.value:distributorName::STRING as distributor_name,
  f.value:distributorAccountStatus::STRING as dist_status,
  COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as dealer_count
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA,
  LATERAL FLATTEN(input => PARSE_JSON(RECORD_CONTENT):detail.data.distributors) f
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.distributors IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 20;
-- Result: POOLCORP/ACTIVE(4), COVERPOOLS/ACTIVE(4), AQUA GON/PENDING ACTIVE(3), etc.
```

### Program Opt-Ins (flattened)
```sql
SELECT
  f.value:programName::STRING as program_name,
  f.value:programStatus::STRING as program_status,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA,
  LATERAL FLATTEN(input => PARSE_JSON(RECORD_CONTENT):detail.data.programOptIns) f
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.programOptIns IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC;
-- Result: 5 program types × multiple statuses (ACTIVE, PENDING, DECLINED, INACTIVE)
```

### UTM / Marketing Attribution
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.utm.utm_source::STRING as utm_source,
  PARSE_JSON(RECORD_CONTENT):detail.data.utm.utm_medium::STRING as utm_medium,
  PARSE_JSON(RECORD_CONTENT):detail.data.utm.utm_campaign::STRING as utm_campaign,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.utm IS NOT NULL
  AND PARSE_JSON(RECORD_CONTENT):detail.data.utm.utm_source::STRING != ''
GROUP BY 1, 2, 3
ORDER BY 4 DESC;
-- Result: sitecore/email/fp_welcome(45), google/email/april_campaign(4)
```

### Business Segment & Channel
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.businessSegment::STRING as segment,
  PARSE_JSON(RECORD_CONTENT):detail.data.channel::STRING as channel,
  PARSE_JSON(RECORD_CONTENT):detail.data.customerClass::STRING as customer_class,
  PARSE_JSON(RECORD_CONTENT):detail.data.salesChannel::STRING as sales_channel,
  COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as dealer_count
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.businessSegment IS NOT NULL
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC;
-- Result: SERVICE/AFTERMARKET/INDIRECT(10), BUILD/NEW CONSTRUCTION/PIP MEMBER(7), etc.
```

### Geographic Distribution (with data quality issue)
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.primaryBillingLocation.address.state::STRING as state,
  COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as dealer_count
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.primaryBillingLocation.address.state IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 15;
-- Result: CA(7), AZ(5), Arizona(5), California(4) — note inconsistent state codes!
```

### Fields Updated Tracking
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.metadata.fieldsUpdated as fields_updated,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING = 'fluidrapro.pro-business-master.updated.v1'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 15;
-- Result: distributors(31), webAccountId+loginStatus+subscriptionId(27), etc.
```

### Rebate Pay Type
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.rewardsAccount.rebatePayType::STRING as rebate_pay_type,
  COUNT(*) as cnt
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.rewardsAccount.rebatePayType IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;
-- Result: AP Voucher(47), Debit VISA(18)
```

---

## Data Quality Queries

### Duplicate Events
```sql
-- 363 total events but 290 distinct IDs = 73 duplicates
SELECT COUNT(*) as total_events FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA;
SELECT COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):id::STRING) as distinct_ids
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA;
```

### Source Systems
```sql
SELECT
  PARSE_JSON(RECORD_CONTENT):detail.data.source::STRING as source,
  COUNT(DISTINCT PARSE_JSON(RECORD_CONTENT):detail.data.proBusinessId::STRING) as dealer_count
FROM RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA
WHERE PARSE_JSON(RECORD_CONTENT):detail.data.source IS NOT NULL
  AND PARSE_JSON(RECORD_CONTENT):"detail-type"::STRING LIKE '%pro-business-master%'
GROUP BY 1
ORDER BY 2 DESC;
-- Result: PROWEB(28), SALESFORCE(11)
```
