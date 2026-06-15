# Requirements vs Source Data Gap Analysis

## Fluidra Pro Program Adoption & Health Dashboard

This document maps each KPI requirement against the available data in `DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA` to identify what can be built today, what needs additional data sources, and where gaps exist.

---

## Data Source Summary

### Available: RAW_DEALERS_DATA (Kafka CDC Events)

| Property | Value |
|----------|-------|
| Records | 100 (test environment sample) |
| Kafka Topic | `psot_poolpro_inbound` |
| Source Systems | pro-platform-core (97), reconciler (2), salesforce (1) |
| Date Range | June 9-15, 2026 |

### Available Event Types

| Sub-Domain | Events | Count |
|-----------|--------|-------|
| pro-business-master | created, updated, approved | 45 |
| pro-contact-master | created, updated, login-created | 50 |
| pro-location-master | created, updated | 2 |
| pro-business-lead | approved | 1 |
| pro-reconcile | completed | 2 |

### Available Data Fields

**Business Master Entity:**
- `proBusinessId` - Unique business identifier
- `businessName` - Dealer business name
- `status` - ACTIVE, LEAD
- `primaryBusinessType` - SERVICE, BUILDER, RETAILER
- `secondaryBusinessTypes[]` - Array of secondary types
- `primaryBusinessEmail` - Business email
- `primaryBusinessPhoneNumber` - Business phone
- `primaryContact` - Nested object with contact details + `lastLoginDate`
- `primaryBillingLocation` - Address with city, state, zip, country
- `primaryShippingLocation` - Address with city, state, zip, country
- `distributors[]` - Array of distributor associations (name, account number, status)
- `programOptIns[]` - Program enrollments (PROEDGE, RETAIL SELECT, etc.)
- `rewardsAccount` - Rewards details (achieverLevel, programLevel, programStatus, fluidraAccountNumber, region)
- `doingBusinessAs` - DBA name
- `tseViolator` - Boolean flag
- `termsAccepted` - Boolean
- `utm` - Marketing attribution (campaign, content, medium, source, term)
- `auditInfo` - createdAt, createdBy, updatedAt, updatedBy

**Contact Master Entity:**
- `proContactId` - Unique contact identifier
- `firstName`, `lastName` - Contact name
- `email` - Contact email
- `phoneNumber` - Contact phone
- `contactType` - OWNER, CO-OWNER, TECHNICIAN, CSC, OFFICE ADMIN, OTHER
- `loginStatus` - ACTIVE, PENDING
- `status` - ACTIVE
- `cognitoSubId` - AWS Cognito user ID (when login exists)
- `username` - Login username
- `webUserId` - Web portal user ID
- `lastLoginDate` - Last login timestamp (on primaryContact)
- `userSubscriptions[]` - Subscription details (ION POOL CARE, roles)
- `auditInfo` - createdAt, createdBy, updatedAt, updatedBy

**Event Metadata (every event):**
- `correlationId` - Trace ID
- `domain` - Always "fluidrapro"
- `eventType` - created, updated, approved, login-created
- `fieldsUpdated[]` - Which fields changed
- `payloadVersion` - Schema version
- `service` - Source service
- `subDomain` - Entity type

**Location Master Entity:**
- `proLocationId` - Location ID
- `locationName` - Name
- `locationType` - PRIMARY_BILL_TO, PRIMARY_SHIP_TO
- `locationStatus` - ACTIVE
- `address` - city, state, zip, country, streetLine1, streetLine2
- `hideAddress`, `hideLocation`, `isEmailLeadsEnabled` - Flags

---

## KPI Feasibility Assessment

### Legend
- FULL - All data available in current source
- PARTIAL - Some data available, needs enrichment or derivation
- GAP - Data not available in current source, needs additional integration
- DERIVED - Can be calculated from available events with dbt logic

---

## 1. Dealer Adoption KPIs

### 1.1 Total Active Dealer Accounts

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | PARTIAL | |
| Available | `primaryContact.lastLoginDate` on business-master events | Indicates last login |
| Available | `loginStatus` = ACTIVE vs PENDING | Shows login capability |
| Gap | No dedicated login event stream | CDC only captures profile changes, not every login |
| Workaround | Use `login-created` events + `lastLoginDate` field to approximate | |
| Recommendation | Need a dedicated login/session event source OR query Cognito directly |

### 1.2 Total Enrolled Dealers

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | FULL | |
| Available | `pro-business-master.created` events | Captures enrollment |
| Available | `status` = ACTIVE with `rewardsAccount` present | Indicates completed setup |
| Available | `programOptIns[]` with `programStatus` = ACTIVE | Shows program enrollment |
| Calculation | Count businesses with status=ACTIVE AND rewardsAccount.programStatus=ACTIVE |

### 1.3 Total Dealer Accounts Not Set Up

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | PARTIAL | |
| Available | `loginStatus` = PENDING on primaryContact | Never completed login setup |
| Available | `status` = LEAD | Business not yet activated |
| Gap | No explicit "setup completed" event | |
| Workaround | Dealers where `loginStatus` = PENDING AND no `login-created` event |

### 1.4 Total Inactive Dealers

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | PARTIAL | |
| Available | `lastLoginDate` on primaryContact | Can calculate days since last login |
| Gap | `lastLoginDate` only appears in business-master snapshots, not real-time | |
| Recommendation | Need login event stream or periodic Cognito export |

### 1.5 New Dealer Accounts Created

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | FULL | |
| Available | `pro-business-master.created` events with timestamp | |
| Available | `status` field distinguishes LEAD vs ACTIVE | |
| Calculation | Count `created` events grouped by time period, filtered by status |

---

## 2. Dealer Conversion KPIs

### 2.1 Guest-to-Lead Conversion

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | GAP | |
| Gap | No "guest" concept visible in current data | |
| Gap | No guest registration events captured | |
| Recommendation | Need Salesforce lead source data or a guest registration event stream |

### 2.2 Lead Rejection Rate

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | GAP | |
| Available | `pro-business-lead.approved` event exists (1 record) | |
| Gap | No "rejected" event type in current data | |
| Gap | No Sales Rep attribution | |
| Recommendation | Need Salesforce integration for lead lifecycle (submitted, approved, rejected) |

### 2.3 Time to Approve Lead

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | PARTIAL | |
| Available | `pro-business-lead.approved` event with timestamp | Gives approval time |
| Gap | No lead submission timestamp in current events | |
| Recommendation | Need lead submitted event OR Salesforce lead created date |

### 2.4 Approved Lead to Rewards Activation

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | DERIVED | |
| Available | `pro-business-lead.approved` timestamp | Lead approval time |
| Available | `rewardsAccount.auditInfo.createdAt` | Rewards activation time |
| Calculation | Average(rewardsAccount.createdAt - lead.approved.time) |
| Note | Requires joining business-lead events with business-master rewards data |

---

## 3. User Adoption KPIs

### 3.1 Total Active Users (TAU)

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | PARTIAL | |
| Available | `loginStatus` = ACTIVE on contacts | Shows who has logged in ever |
| Available | `lastLoginDate` on some contacts | Recency indicator |
| Gap | No session/login event stream for period-based counting | |
| Recommendation | Need login event source for accurate period-based TAU |

### 3.2 New Technician Accounts Created

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | FULL | |
| Available | `pro-contact-master.created` events | |
| Available | `contactType` = TECHNICIAN filter | |
| Calculation | Count created events WHERE contactType = 'TECHNICIAN' by period |

### 3.3 Users Never Set Up

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | FULL | |
| Available | `loginStatus` = PENDING on contacts | Never completed setup |
| Available | Absence of `login-created` event for a contact | |
| Calculation | Contacts WHERE loginStatus = 'PENDING' AND no login-created event |

### 3.4 Inactive Users

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | PARTIAL | |
| Available | `lastLoginDate` where present | |
| Gap | `lastLoginDate` not on all contacts, only primaryContact in business snapshots |
| Recommendation | Need login event stream or Cognito data |

### 3.5 Time to First Login

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | DERIVED | |
| Available | `pro-contact-master.created` event timestamp | Account creation time |
| Available | `pro-contact-master.login-created` event timestamp | First login provisioned |
| Calculation | Average(login-created.time - contact.created.time) |
| Note | This measures time to login creation, not actual first login |

### 3.6 First Login Rate

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | DERIVED | |
| Available | Count of `created` events vs `login-created` events per period | |
| Calculation | login-created count / created count within period |
| Limitation | Measures login provisioning rate, not actual first login |

### 3.7 Active Users per Dealer Account

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | PARTIAL | |
| Available | `account` field in events links contacts to business accounts | |
| Available | Contact events with `loginStatus` = ACTIVE per account | |
| Gap | Need reliable active user count per period (login events) | |
| Calculation (approximate) | Active contacts per account from latest snapshots |

---

## 4. Engagement KPIs

### 4.1 Dealer Stickiness Ratio (WAU/MAU)

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | GAP | |
| Gap | No login/session events to calculate WAU or MAU | |
| Recommendation | Need clickstream or session data from the Pro Platform |

### 4.2 Technician Stickiness Ratio (DAU/MAU)

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | GAP | |
| Gap | Same as above - no session/activity data | |
| Recommendation | Need daily active user metrics from application logs |

---

## 5. Revenue KPIs

### 5.1 Revenue Associated to Active Dealers

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | GAP | |
| Available | `fluidraAccountNumber` in rewardsAccount | Can link to revenue |
| Gap | No revenue/transaction data in current stream | |
| Recommendation | Need PSOT Revenue Data integration |

### 5.2 Revenue Growth Comparison

| Aspect | Assessment | Details |
|--------|-----------|----------|
| Feasibility | GAP | |
| Gap | No revenue data available | |
| Recommendation | Need PSOT Revenue Data with August 2025 baseline |

---

## 6. Required Filters Assessment

### Account Attributes

| Filter | Feasibility | Source Field |
|--------|------------|-------------|
| Key Account vs Non-Key Account | GAP | Not in current data |
| Primary Business Type | FULL | `primaryBusinessType` (SERVICE, BUILDER, RETAILER) |
| Achiever Level | FULL | `rewardsAccount.achieverLevel` (SERVICEPRO ELITE, BUILDER PROEDGE PARTNER) |
| Account Status | FULL | `status` (ACTIVE, LEAD) |
| Sales Region | GAP | Not in current data (need Oracle/Salesforce) |

### User Attributes

| Filter | Feasibility | Source Field |
|--------|------------|-------------|
| Contact Role | FULL | `contactType` (OWNER, CO-OWNER, TECHNICIAN, CSC, OFFICE ADMIN, OTHER) |
| Dealer vs Technician | FULL | `contactType` = OWNER/CO-OWNER vs TECHNICIAN |

### Platform Attributes

| Filter | Feasibility | Source Field |
|--------|------------|-------------|
| Web vs Mobile | GAP | No platform/device info in events |

### Time Filters

| Filter | Feasibility | Source Field |
|--------|------------|-------------|
| Last 30/90/12M | FULL | `EVENT_TIME` field |
| Custom Date Range | FULL | `EVENT_TIME` field |

---

## Summary: Data Availability Matrix

| Category | FULL | PARTIAL | DERIVED | GAP |
|----------|------|---------|---------|-----|
| Dealer Adoption (5 KPIs) | 2 | 3 | 0 | 0 |
| Dealer Conversion (4 KPIs) | 0 | 1 | 1 | 2 |
| User Adoption (7 KPIs) | 2 | 2 | 2 | 1 |
| Engagement (2 KPIs) | 0 | 0 | 0 | 2 |
| Revenue (2 KPIs) | 0 | 0 | 0 | 2 |
| **TOTAL (20 KPIs)** | **4** | **6** | **3** | **7** |

---

## Additional Data Sources Required

| Data Source | KPIs Enabled | Priority |
|------------|-------------|----------|
| **Login/Session Events** | Active Dealers, TAU, Inactive Users, Stickiness Ratios | HIGH |
| **PSOT Revenue Data** | Revenue KPIs, Revenue Growth | HIGH |
| **Salesforce Leads** | Guest-to-Lead, Lead Rejection, Time to Approve | MEDIUM |
| **Oracle Sales Region** | Sales Region filter, Regional drill-downs | MEDIUM |
| **Platform/Device Data** | Web vs Mobile filter | LOW |
| **Key Account Classification** | Key Account filter | LOW |

---

## Recommended Approach

### Phase 1: Build with Available Data (Current Source)
Build dbt models for KPIs marked FULL and DERIVED:
- New Dealer Accounts Created
- Total Enrolled Dealers
- New Technician Accounts Created
- Users Never Set Up
- Time to First Login (proxy)
- First Login Rate (proxy)
- Approved Lead to Rewards Activation

### Phase 2: Enrich with Login Events
Integrate login/session event stream to enable:
- Total Active Dealer Accounts
- Total Active Users
- Inactive Dealers/Users
- Stickiness Ratios

### Phase 3: External System Integration
Integrate Salesforce and Oracle data for:
- Lead conversion funnel
- Sales region analysis
- Revenue association

---

## Available Program Levels (from data)

| Program | Achiever Levels Observed |
|---------|-------------------------|
| SERVICEPRO | SERVICEPRO ELITE |
| FLATRATE SERVICEPRO | (base level) |
| PROEDGE | BUILDER PROEDGE PARTNER |
| RETAIL SELECT | (base level) |
| ION POOL CARE | (subscription) |

## Available Distributor Names (from data)

POOLCORP, HERITAGE, COVERPOOLS, CINDERELLA, PEP, AUBURN, KELLER, KELLERSUPPLY, ROYAL PALM POOLS, ATB LEISURE PRODUCTS, A & M Dist, Aqua Tech Pool Supply, SOLAR POOLS, Aqua Spa & Pool Supply, RBF INTERNATIONAL, AQUA GON INC.
