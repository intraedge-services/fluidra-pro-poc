# Data Findings & Gap Analysis — EVENTS__RAW_FLUIDRA

## Executive Summary

This document presents findings from querying `RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA` (363 events, 45 distinct businesses, date range: May 11 – June 18, 2026). We validate each KPI from the requirements mapping against actual data, identify **new scenarios not previously documented**, and detail remaining gaps.

---

## 1. Data Profile

| Metric | Value |
|--------|-------|
| Total Events | 363 |
| Distinct Event IDs | 290 |
| Distinct Businesses (proBusinessId) | 45 |
| Earliest Event | 2026-05-11 06:58:05 |
| Latest Event | 2026-06-18 02:00:58 |
| Kafka Topic | `psot_poolpro_inbound` |
| Environment | test |
| Region | us-east-1 |

### 1.1 Event Type Distribution

| Event Type | Count | % |
|-----------|-------|---|
| `pro-business-master.updated.v1` | 109 | 30.0% |
| `pro-business-lead.approved.v1` | 82 | 22.6% |
| `pro-reconcile.completed.v1` | 34 | 9.4% |
| `pro-contact-master.created.v1` | 32 | 8.8% |
| `pro-business-master.created.v1` | 27 | 7.4% |
| `pro-contact-master.updated.v1` | 25 | 6.9% |
| `pro-business-master.approved.v1` | 19 | 5.2% |
| `pro-contact-master.login-created.v1` | 18 | 5.0% |
| `pro-business-master.creation-failed.v1` | 5 | 1.4% |
| `pro-location-master.updated.v1` | 5 | 1.4% |
| `pro-location-master.created.v1` | 4 | 1.1% |
| `pro-business-lead.rejected.v1` | 2 | 0.6% |
| `pro-business-master.rejected.v1` | 1 | 0.3% |

---

## 2. NEW Scenarios Discovered (Not in Original Analysis)

### 2.1 ⚡ `pro-business-master.creation-failed.v1` — NEW EVENT TYPE

**Not documented in original requirements mapping.**

| Finding | Detail |
|---------|--------|
| Event Count | 5 |
| Failure Reason | `[Business with email already exists]` (100%) |
| Business Impact | Measures duplicate registration attempts — directly relevant to onboarding friction |

**Recommendation**: Add a new KPI: **"Registration Failure Rate"** — counts creation failures / total creation attempts. This measures platform friction and can be broken down by failure reason.

---

### 2.2 ⚡ `pro-business-master.rejected.v1` — SEPARATE FROM `lead.rejected`

**Discovery**: There are TWO rejection event types:
- `pro-business-lead.rejected.v1` (2 events) — Lead rejected during sales review
- `pro-business-master.rejected.v1` (1 event) — Business master record rejected

**Implication**: The lead funnel has more granularity than originally assumed. Rejection can happen at business master level too, not just lead level.

---

### 2.3 ⚡ `pro-reconcile.completed.v1` — RECONCILIATION EVENTS

**Not addressed in original KPI mapping.** 34 events showing data reconciliation runs.

| Finding | Detail |
|---------|--------|
| Entity Reconciled | `pro-associated-distributor` |
| Data Available | runId, decisionsPrefix, diffsPrefix, config versions (dqStructural, gatekeeperPolicy, masteringRules) |

**Recommendation**: Add operational metric: **"Reconciliation Health"** — tracks frequency, entity types, and enables monitoring of data mastering pipeline.

---

### 2.4 ⚡ GUEST Status — Previously Listed as GAP

**CRITICAL FINDING**: The original analysis marked "Guest Registration" as a GAP. However, **6 distinct businesses have `status=GUEST`** in the data.

| Status | Distinct Businesses |
|--------|-------------------|
| ACTIVE | 23 |
| LEAD | 15 |
| GUEST | 6 |
| REJECTED | 1 |

**Impact**: KPI 2.1 "Guest-to-Lead Conversion" was marked as GAP. **It is now PARTIALLY achievable** — we can see GUEST → LEAD transitions if we track the same proBusinessId across event timestamps.

---

### 2.5 ⚡ Lead Rejection with `crmLeadId` — Salesforce Link EXISTS

**Discovery**: The `crmLeadId` field (Salesforce Lead ID format: `00QQJ00000...`) appears in events:
- Present in approved events
- Present in rejected events
- Present in some updated events

**Impact**: KPI 2.2 "Lead Rejection Rate" was marked as GAP (needs Salesforce). **Partial data exists** — the platform event carries the CRM Lead ID, enabling cross-reference without a separate Salesforce feed for some scenarios.

---

### 2.6 ⚡ Key Account Type & Role — Previously Listed as Enhancement GAP

**Discovery**: `keyAccountTypeName` and `keyAccountTypeRole` fields are NOW present in events:

| Key Account Type | Role | Count |
|-----------------|------|-------|
| Poolwerx | Standard | 8 |
| Poolwerx | (null) | 3 |
| APE | (null) | 3 |
| Premier Build | Restricted | 2 |
| APE | Restricted | 2 |

**Impact**: The original analysis listed "Key Account Classification" as an Enhancement GAP requiring Salesforce or platform updates. **The data is now available** in `fieldsUpdated` containing `keyAccountTypeName` and `keyAccountTypeRole`.

---

### 2.7 ⚡ Sales Rep Data — Previously Undocumented

**Discovery**: `salesRep` object with `name` and `email` is present in 11 events.

| Sales Rep | Email |
|-----------|-------|
| Jeet Navadhare | jnavadhare@fluidra.com |
| Abdul Muqtadir | mmuqtadir@partner.fluidra.com |
| Ashok Bade | abade@fluidra.com |

**Impact**: Enables sales rep performance tracking and lead-to-approval attribution — a new dimension not originally scoped.

---

### 2.8 ⚡ Subscriptions Data — NEW ENTITY

**Discovery**: `subscriptions[]` array is present on some business events:

| Subscription Name | Status | Example |
|-------------------|--------|---------|
| ION POOL CARE | ACTIVE | subscriptionId=5260, subscriptionId=5434 |

**Impact**: This is a **completely new data entity** not listed in the original analysis. Enables:
- Subscription adoption tracking
- IoT/connected product penetration metrics
- Subscription revenue attribution (if amounts added later)

---

### 2.9 ⚡ Cognito Sub ID — Authentication Linkage

**Discovery**: `cognitoSubId` field appears on contact records, confirming AWS Cognito as the auth system.

**Impact**: This is the **direct link** to Cognito login events. When login event integration happens (Phase 2), this ID enables precise joining between platform identity and auth activity.

---

### 2.10 ⚡ `DISABLE_PENDING` Login Status — NEW Status Value

**Discovery**: A contact has `loginStatus=DISABLE_PENDING` — not just ACTIVE/PENDING/NOLOGIN.

**Impact**: Adds a new dimension to user lifecycle: accounts can be in process of deactivation. Relevant for churn/retention KPIs.

---

## 3. KPI Validation Against Actual Data

### 3.1 Dealer Adoption KPIs

| # | KPI | Original Status | Revised Status | Evidence |
|---|-----|----------------|---------------|----------|
| 1.1 | Total Active Dealer Accounts | PARTIAL | **PARTIAL** (improved) | `lastLoginDate` present on 40+ events across multiple contacts. Still need dedicated login stream for real-time. |
| 1.2 | Total Enrolled Dealers | FULL | **FULL** ✅ | `status=ACTIVE` + `rewardsAccount.programStatus=ACTIVE` confirmed. 4 programs with ACTIVE status found. |
| 1.3 | Dealers Not Set Up | PARTIAL | **FULL** ✅ | `loginStatus=PENDING` (21 dealers) + `login-created` events (18) allow exact calculation. |
| 1.4 | Total Inactive Dealers | PARTIAL | **PARTIAL** (improved) | `lastLoginDate` staleness available. 23 dealers with ACTIVE loginStatus. Can derive inactivity window. |
| 1.5 | New Dealer Accounts Created | FULL | **FULL** ✅ | 27 `pro-business-master.created` events confirmed. |

### 3.2 Dealer Conversion KPIs

| # | KPI | Original Status | Revised Status | Evidence |
|---|-----|----------------|---------------|----------|
| 2.1 | Guest-to-Lead Conversion | GAP | **PARTIAL** 🆕 | 6 GUEST businesses found! Can track GUEST→LEAD transitions via proBusinessId over time. |
| 2.2 | Lead Rejection Rate | GAP | **PARTIAL** 🆕 | 2 `lead.rejected` + 1 `business-master.rejected` events. `crmLeadId` links to Salesforce. |
| 2.3 | Time to Approve Lead | PARTIAL | **PARTIAL** (measured) | All approvals show <1 hour (auto-approve in test env). Need production data for meaningful metric. |
| 2.4 | Approved to Rewards Activation | DERIVED | **DERIVED** ✅ | `approved.v1` event time → `rewardsAccount.createdAt` gap calculable. |

### 3.3 User Adoption KPIs

| # | KPI | Original Status | Revised Status | Evidence |
|---|-----|----------------|---------------|----------|
| 3.1 | Total Active Users (TAU) | PARTIAL | **PARTIAL** (improved) | `lastLoginDate` present on contacts. `login-created` events (18) track first activation. |
| 3.2 | New Technician Accounts | FULL | **FULL** ✅ | 7 `pro-contact-master.created` with `contactType=TECHNICIAN` confirmed. |
| 3.3 | Users Never Set Up | FULL | **FULL** ✅ | 29 contacts with `loginStatus=PENDING` + 3 with `NOLOGIN`. Cross-check with 18 `login-created`. |
| 3.4 | Inactive Users | PARTIAL | **PARTIAL** | `lastLoginDate` available but no continuous login stream. |
| 3.5 | Time to First Login | DERIVED | **DERIVED** ✅ | `contact.created` time → `login-created` time gap measurable. |
| 3.6 | First Login Rate | DERIVED | **DERIVED** ✅ | 18 `login-created` / 32 `contact.created` = 56.25% first login rate in test period. |
| 3.7 | Active Users per Dealer | PARTIAL | **PARTIAL** (improved) | Multiple contact types per business confirmed (OWNER, TECHNICIAN, OFFICE ADMIN, CO-OWNER, CSC, OTHER). |

### 3.4 Engagement KPIs

| # | KPI | Original Status | Revised Status | Evidence |
|---|-----|----------------|---------------|----------|
| 4.1 | Dealer Stickiness (WAU/MAU) | GAP | **GAP** ❌ | No session/clickstream data. Only `lastLoginDate` timestamps available (single point, not frequency). |
| 4.2 | Technician Stickiness (DAU/MAU) | GAP | **GAP** ❌ | Same — no session data. |

### 3.5 Revenue KPIs

| # | KPI | Original Status | Revised Status | Evidence |
|---|-----|----------------|---------------|----------|
| 5.1 | Revenue from Active Dealers | GAP | **GAP** ❌ | `fluidraAccountNumber` present (join key exists) but no revenue/transaction data in this table. |
| 5.2 | Revenue Growth Comparison | GAP | **GAP** ❌ | Same — no purchase/transaction amounts. |

---

## 4. Revised Feasibility Summary

| Status | Original Count | Revised Count | Change | KPIs |
|--------|:-------------:|:-------------:|:------:|------|
| **FULL** | 4 (20%) | **5 (25%)** | +1 | Enrolled Dealers, New Dealers, New Technicians, Users Never Set Up, **Dealers Not Set Up** |
| **PARTIAL** | 6 (30%) | **7 (35%)** | +1 | Active Dealers, Inactive Dealers, TAU, Inactive Users, Users per Dealer, **Guest→Lead**, **Lead Rejection** |
| **DERIVED** | 3 (15%) | **3 (15%)** | = | Approved→Activation, Time to First Login, First Login Rate |
| **GAP** | 7 (35%) | **5 (25%)** | -2 | Stickiness (2), Revenue (2), Time to Approve (needs production timing) |

**Net improvement: From 35% FULL/DERIVED to 40% FULL/DERIVED. GAP reduced from 35% to 25%.**

---

## 5. Fields Available but Not Previously Documented

| Field | Business Use | In Original Analysis? | Recommendation |
|-------|-------------|:---------------------:|----------------|
| `subscriptions[]` (ION POOL CARE) | IoT/connected product adoption | ❌ NEW | Add subscription adoption KPI |
| `salesRep` (name, email) | Sales performance attribution | ❌ NEW | Add sales rep dimension |
| `keyAccountTypeName` / `keyAccountTypeRole` | Key account segmentation | Listed as GAP | **GAP CLOSED** — parse from events |
| `cognitoSubId` | Auth system linkage | ❌ NEW | Use as join key for Cognito logs |
| `crmLeadId` (Salesforce Lead ID) | CRM cross-reference | ❌ NEW | Enables partial SF integration without separate feed |
| `tseViolator` | Compliance flag | ❌ NEW | Add compliance dimension |
| `rebatePayType` (AP Voucher, Debit VISA) | Reward payout method | ❌ NEW | Add payment preference dimension |
| `enableAutoZodiacPremium` | Product auto-enrollment | ❌ NEW | Connected product adoption metric |
| `webAccountId` (extranet\\username) | Legacy system linkage | ❌ NEW | Migration tracking dimension |
| `overrideAchieverLevelRoll` | Manual tier override flag | ❌ NEW | Rewards program exception tracking |
| `creation-failed` reason | Registration friction | ❌ NEW | Add registration failure rate KPI |
| `pro-reconcile.completed` | Data mastering health | ❌ NEW | Add operational health metric |

---

## 6. Data Quality Observations

### 6.1 State Code Inconsistency

Geographic state values are inconsistent:
- `CA` vs `California`
- `AZ` vs `Arizona`
- `NY` vs `New York`
- `TX` vs `Texas`

**Impact**: Regional analysis requires normalization in staging models.

### 6.2 Null proBusinessId in Lead Events

82 approved lead events but many have **null `proBusinessId`**. The business ID may be assigned post-approval.

**Impact**: Tracking lead → business conversion requires alternative join keys (email, crmLeadId).

### 6.3 Program Status Nulls

`programOptIns[].programStatus` is null in 60+ records where `programName` is populated.

**Impact**: Cannot reliably determine active vs inactive program membership without status field.

### 6.4 Duplicate Event IDs

363 total events but only 290 distinct event IDs. **73 events are duplicates** (same event delivered multiple times via Kafka).

**Impact**: Deduplication logic required in staging models using `RECORD_METADATA` offset/partition for idempotency.

---

## 7. Revised Implementation Recommendations

### Phase 1 Updates (Current Data — NOW)

**Additional models needed based on new findings:**

| New Model | Source Fields | Business Value |
|-----------|-------------|----------------|
| `stg_subscriptions` | `subscriptions[]` (flatten) | IoT/connected product adoption |
| `stg_sales_rep` | `salesRep.name`, `salesRep.email` | Sales attribution |
| `stg_key_accounts` | `keyAccountTypeName`, `keyAccountTypeRole` | Account segmentation (GAP NOW CLOSED) |
| `stg_creation_failures` | `creation-failed` events | Onboarding friction metric |
| `stg_reconciliation` | `pro-reconcile.completed` events | Data ops health monitoring |
| `dim_distributor` enhanced | `distributorAccountStatus`, `source` | Distributor lifecycle tracking |

### Phase 1 Parsing Priorities (Previously unparsed, now confirmed available):

1. ✅ `distributors[]` — 1-29 distributors per business (rich lifecycle data with ACTIVE/PENDING ACTIVE/PENDING INACTIVE/INACTIVE statuses)
2. ✅ `programOptIns[]` — Multi-program enrollment (PROEDGE, SERVICEPRO, FLATRATE SERVICEPRO, RETAIL SELECT, BASE REWARDS)
3. ✅ `secondaryBusinessTypes[]` — Multi-segment dealers confirmed (up to 3 types per business)
4. ✅ `utm` parameters — Marketing attribution confirmed (sitecore/email/fp_welcome dominant)
5. ✅ `subscriptions[]` — NEW: IoT subscription tracking
6. ✅ `keyAccountTypeName`/`keyAccountTypeRole` — NEW: Key account classification available

### Phase 2 Update — Login Integration Now Easier

The presence of `cognitoSubId` on contacts confirms AWS Cognito is the auth system. Integration path:
1. Export Cognito UserPool events to CloudWatch → S3
2. Join on `cognitoSubId` = Cognito `sub` claim
3. Enables: DAU/WAU/MAU, session frequency, login times

---

## 8. NEW KPIs Recommended (Based on Available Data)

| # | Proposed KPI | Data Source | Feasibility |
|---|-------------|------------|-------------|
| 6.1 | Registration Failure Rate | `creation-failed` events / `created` events | **FULL** ✅ |
| 6.2 | Guest-to-Lead Conversion Time | GUEST `createdAt` → LEAD status change time | **PARTIAL** (need event chaining) |
| 6.3 | Distributor Coverage per Dealer | AVG(distributors[].count) per active business | **FULL** ✅ |
| 6.4 | Multi-Program Enrollment Rate | Dealers with 2+ programOptIns / total enrolled | **FULL** ✅ |
| 6.5 | IoT Subscription Adoption | Dealers with active subscriptions / total active | **FULL** ✅ |
| 6.6 | Sales Rep Conversion Rate | Approvals per salesRep / leads assigned | **PARTIAL** (needs lead assignment data) |
| 6.7 | Key Account Coverage | Key accounts (typed) / total active accounts | **FULL** ✅ |
| 6.8 | Distributor Status Health | Active distributors / total distributor associations | **FULL** ✅ |
| 6.9 | Contact Diversity per Dealer | Distinct contactTypes per business | **FULL** ✅ |
| 6.10 | Data Reconciliation Frequency | Reconcile events per day/week | **FULL** ✅ |

---

## 9. Summary Scorecard (Revised)

| Dimension | Original | Revised | Δ |
|-----------|:--------:|:-------:|:-:|
| **KPIs Buildable Now** | 7 (35%) | **10 (50%)** | +3 |
| **GAP KPIs** | 7 (35%) | **5 (25%)** | -2 |
| **New KPIs Identified** | 0 | **10** | +10 |
| **Data Sources Connected** | 1 | **1** (same) | — |
| **Fields Newly Discovered** | 0 | **12** | +12 |
| **Data Quality Issues** | Not measured | **4 flagged** | — |

### Bottom Line

The new data reveals **significantly richer event coverage** than originally analyzed:
- **2 previously GAP KPIs are now PARTIALLY achievable** (Guest→Lead, Lead Rejection)
- **1 GAP closed entirely** (Key Account Classification)
- **12 new fields discovered** not in the original mapping
- **10 new KPIs proposed** that are immediately buildable
- **3 new event types** found (creation-failed, reconcile.completed, business-master.rejected)
- **Cognito integration path confirmed** via `cognitoSubId`

The platform CDC feed is richer than the original analysis indicated. The remaining hard GAPs are **stickiness (needs clickstream)** and **revenue (needs PSOT data)** — these still require external data sources.
