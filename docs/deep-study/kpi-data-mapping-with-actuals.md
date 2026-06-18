# KPI-to-Data Mapping — 20 KPIs with Actual Data Evidence

## Purpose

This document maps each of the **20 original KPIs** against **actual data** from `RAW_DB_DEV.FLUIDRAPRO_RAW.EVENTS__RAW_FLUIDRA`. For each KPI, we provide:
- The SQL logic to compute it
- Actual measured values from the test data
- Data availability assessment (what fields exist, what's missing)
- Revised feasibility status

---

## Category 1: Dealer Adoption (5 KPIs)

### KPI 1.1 — Total Active Dealer Accounts

| Attribute | Detail |
|-----------|--------|
| **Definition** | Dealers with recent login activity (within 30 days) |
| **SQL Logic** | `loginStatus = 'ACTIVE' AND primaryContact.lastLoginDate > NOW() - 30 days` |
| **Measured Value** | **11 dealers** have `loginStatus=ACTIVE` + a `lastLoginDate` present |
| **Active in Last 30 Days** | **3 dealers** (lastLoginDate within Jun 2026) |
| **Inactive >30 Days** | **8 dealers** (lastLoginDate before May 18, 2026) |
| **Data Fields Used** | `detail.data.loginStatus`, `detail.data.primaryContact.lastLoginDate` |
| **Gap** | `lastLoginDate` only updates on business master events, not real-time. Need Cognito login stream for true DAU/WAU. |
| **Feasibility** | **PARTIAL** — Approximation possible. True real-time requires login event stream. |

---

### KPI 1.2 — Total Enrolled Dealers

| Attribute | Detail |
|-----------|--------|
| **Definition** | Dealers with `status=ACTIVE` + `rewardsAccount.programStatus=ACTIVE` |
| **SQL Logic** | `status = 'ACTIVE' AND rewardsAccount.programStatus = 'ACTIVE'` |
| **Measured Value** | **10 enrolled dealers** |
| **Program Breakdown** | PROEDGE: 4, FLATRATE SERVICEPRO: 1, RETAIL SELECT: 2, BASE REWARDS: 2, SERVICEPRO: 1 |
| **Data Fields Used** | `detail.data.status`, `detail.data.rewardsAccount.programStatus`, `detail.data.rewardsAccount.programLevel` |
| **Gap** | None |
| **Feasibility** | **FULL** ✅ |

---

### KPI 1.3 — Dealers Not Set Up

| Attribute | Detail |
|-----------|--------|
| **Definition** | Dealers with `loginStatus=PENDING` (account created but never logged in) |
| **SQL Logic** | `loginStatus = 'PENDING'` from latest business-master event per proBusinessId |
| **Measured Value** | **21 dealers** with PENDING login status |
| **Cross-check** | 18 `login-created` events exist → 21 - (those who later got login) = accurate pending count at snapshot |
| **Data Fields Used** | `detail.data.loginStatus`, event type `pro-contact-master.login-created.v1` |
| **Gap** | None — can definitively identify who hasn't set up login |
| **Feasibility** | **FULL** ✅ |

---

### KPI 1.4 — Total Inactive Dealers

| Attribute | Detail |
|-----------|--------|
| **Definition** | Dealers with active accounts but no login in >30/60/90 days |
| **SQL Logic** | `loginStatus = 'ACTIVE' AND lastLoginDate < CURRENT_DATE - 30` |
| **Measured Value** | **8 dealers** inactive >30 days (last login before 2026-05-18) |
| **Breakdown** | 2 dealers last active in Feb 2026, 1 in May 2026 early, 5 with no lastLoginDate (never tracked) |
| **Data Fields Used** | `detail.data.primaryContact.lastLoginDate` |
| **Gap** | `lastLoginDate` is a snapshot field — only shows most recent login at time of event emission. Not a continuous feed. |
| **Feasibility** | **PARTIAL** — Good approximation for weekly/monthly reporting. Not real-time. |

---

### KPI 1.5 — New Dealer Accounts Created

| Attribute | Detail |
|-----------|--------|
| **Definition** | Count of `pro-business-master.created.v1` events per period |
| **SQL Logic** | `WHERE detail-type = 'fluidrapro.pro-business-master.created.v1' GROUP BY DATE_TRUNC('week', time)` |
| **Measured Value** | **27 new dealers** created (May 11 – Jun 18, 2026) |
| **Weekly Trend** | Avg ~4.5 new dealers/week in test period |
| **Data Fields Used** | Event type `pro-business-master.created.v1`, `time` field |
| **Gap** | None |
| **Feasibility** | **FULL** ✅ |

---

## Category 2: Dealer Conversion (4 KPIs)

### KPI 2.1 — Guest-to-Lead Conversion

| Attribute | Detail |
|-----------|--------|
| **Definition** | Rate at which GUEST-status businesses transition to LEAD |
| **SQL Logic** | Track `proBusinessId` where earliest event has `status=GUEST` and later event has `status=LEAD` |
| **Measured Value** | **6 GUEST businesses** found in data |
| **Conversion Observable** | YES — if the same `proBusinessId` appears later with `status=LEAD`, conversion is confirmed |
| **Data Fields Used** | `detail.data.status` (values: GUEST, LEAD, ACTIVE, REJECTED) |
| **Gap** | Original analysis said GAP (no guest events). **NOW PARTIALLY AVAILABLE** — Guest status exists. However, no dedicated "guest-registered" event type — must infer from `created` events with `status=GUEST`. |
| **Feasibility** | **PARTIAL** 🆕 (upgraded from GAP) |

---

### KPI 2.2 — Lead Rejection Rate

| Attribute | Detail |
|-----------|--------|
| **Definition** | Rejected leads / Total leads submitted |
| **SQL Logic** | `rejected events (2+1) / (approved events (82) + rejected events (3))` |
| **Measured Value** | **3 rejections / 85 total = 3.5% rejection rate** |
| **Rejection Types** | `pro-business-lead.rejected.v1` (2) + `pro-business-master.rejected.v1` (1) |
| **Rejection Reasons** | Rejection reason field is NULL in lead rejected events. Business rejection shows `status=REJECTED`. |
| **CRM Linkage** | `crmLeadId` present (format: `00QQJ00000...`) — Salesforce cross-reference available |
| **Data Fields Used** | Event types `lead.rejected`, `business-master.rejected`, `detail.data.crmLeadId`, `detail.data.salesRep` |
| **Gap** | Rejection *reason* is not populated in test data. Sales rep data available for attribution. |
| **Feasibility** | **PARTIAL** 🆕 (upgraded from GAP) |

---

### KPI 2.3 — Time to Approve Lead

| Attribute | Detail |
|-----------|--------|
| **Definition** | Time between lead submission and approval |
| **SQL Logic** | `DATEDIFF('second', detail.data.auditInfo.createdAt, time)` on approved events |
| **Measured Value** | **Avg: 5.7 seconds, Max: 11 seconds, Min: 3 seconds** |
| **Interpretation** | Test environment uses auto-approval — not meaningful for business insight. Production data needed. |
| **Data Fields Used** | `detail.data.auditInfo.createdAt` (submission time), `time` (approval event timestamp) |
| **Gap** | The data STRUCTURE supports this KPI perfectly. But test data shows auto-approve. Need production event stream for meaningful measurement. |
| **Feasibility** | **PARTIAL** — Data structure supports it. Needs production data for meaningful values. |

---

### KPI 2.4 — Approved to Rewards Activation

| Attribute | Detail |
|-----------|--------|
| **Definition** | Time from lead approval to rewards account becoming ACTIVE |
| **SQL Logic** | Match `pro-business-master.approved.v1` time → `rewardsAccount.createdAt` on same `proBusinessId` |
| **Measured Value** | Measurable — 19 approved events + 10 active rewards accounts. Join by `proBusinessId` yields the gap. |
| **Example** | Business `2e1d785b`: approved event exists + `rewardsAccount.programStatus=ACTIVE` with timestamps |
| **Data Fields Used** | Event `approved.v1` time, `detail.data.rewardsAccount.auditInfo.createdAt` |
| **Gap** | None — both timestamps available |
| **Feasibility** | **DERIVED** ✅ |

---

## Category 3: User Adoption (7 KPIs)

### KPI 3.1 — Total Active Users (TAU)

| Attribute | Detail |
|-----------|--------|
| **Definition** | Users (contacts) with `loginStatus=ACTIVE` and recent activity |
| **SQL Logic** | Count distinct contacts with `loginStatus=ACTIVE` from contact and business events |
| **Measured Value** | **40+ events** show contacts with `loginStatus=ACTIVE` across multiple contact types |
| **Contact Types Active** | OWNER (40), TECHNICIAN (20), OFFICE ADMIN (13), CO-OWNER (10) |
| **Data Fields Used** | `detail.data.primaryContact.loginStatus`, `detail.data.primaryContact.lastLoginDate` |
| **Gap** | Count gives "ever active" not "currently active". Need login event stream for true TAU. |
| **Feasibility** | **PARTIAL** — Snapshot of active-flagged users available. True TAU needs login timestamps. |

---

### KPI 3.2 — New Technician Accounts

| Attribute | Detail |
|-----------|--------|
| **Definition** | Count of new contacts created with `contactType=TECHNICIAN` |
| **SQL Logic** | `WHERE detail-type = 'pro-contact-master.created.v1' AND detail.data.contactType = 'TECHNICIAN'` |
| **Measured Value** | **7 new technicians** created in test period |
| **Other Contact Types Created** | OWNER: 5, OFFICE ADMIN: 5, CO-OWNER: 5, CSC: 5, OTHER: 5 |
| **Data Fields Used** | Event type `pro-contact-master.created.v1`, `detail.data.contactType` |
| **Gap** | None |
| **Feasibility** | **FULL** ✅ |

---

### KPI 3.3 — Users Never Set Up

| Attribute | Detail |
|-----------|--------|
| **Definition** | Contacts created but never completed login setup |
| **SQL Logic** | Contacts in `created` events where `loginStatus=PENDING` and no matching `login-created` event |
| **Measured Value** | **29 contacts** created with `loginStatus=PENDING`, **3 with NOLOGIN** |
| **Login Created** | 18 contacts got `login-created` events → **~14 never set up** (30 created - 18 login-created + 3 NOLOGIN) |
| **Data Fields Used** | `detail.data.loginStatus` on created events, existence of `login-created` event for same `proContactId` |
| **Gap** | None — fully derivable |
| **Feasibility** | **FULL** ✅ |

---

### KPI 3.4 — Inactive Users

| Attribute | Detail |
|-----------|--------|
| **Definition** | Users who were active but haven't logged in recently |
| **SQL Logic** | `loginStatus = 'ACTIVE' AND lastLoginDate < threshold` |
| **Measured Value** | 8 contacts with `lastLoginDate` older than 30 days |
| **Data Fields Used** | `detail.data.primaryContact.lastLoginDate` |
| **Gap** | Same as KPI 1.4 — `lastLoginDate` is a snapshot, not continuous. A user could have logged in yesterday via Cognito but this field wouldn't reflect it until next business-master event is emitted. |
| **Feasibility** | **PARTIAL** — Reasonable approximation for periodic reporting. |

---

### KPI 3.5 — Time to First Login

| Attribute | Detail |
|-----------|--------|
| **Definition** | Duration between contact creation and first login setup |
| **SQL Logic** | `login-created.time - contact-created.auditInfo.createdAt` for matching `proContactId` |
| **Measured Value** | **15 contacts** with both created + login-created events joinable |
| **Actual Times** | Avg: ~2 minutes, Max: ~3 minutes, Min: <1 minute (test environment = immediate setup) |
| **Data Fields Used** | `pro-contact-master.created.v1` → `auditInfo.createdAt`, `pro-contact-master.login-created.v1` → `time` |
| **Gap** | None — fully derivable. Production data will show real-world onboarding delays. |
| **Feasibility** | **DERIVED** ✅ |

---

### KPI 3.6 — First Login Rate

| Attribute | Detail |
|-----------|--------|
| **Definition** | % of created contacts who complete login setup |
| **SQL Logic** | `COUNT(DISTINCT login-created contacts) / COUNT(DISTINCT created contacts)` |
| **Measured Value** | **18 / 30 = 60.0% first login rate** |
| **Interpretation** | 40% of created contacts in test period never completed login setup |
| **Data Fields Used** | Distinct `proContactId` counts from `created` vs `login-created` event types |
| **Gap** | None |
| **Feasibility** | **DERIVED** ✅ |

---

### KPI 3.7 — Active Users per Dealer

| Attribute | Detail |
|-----------|--------|
| **Definition** | Average number of active-login users per business account |
| **SQL Logic** | Count distinct active contacts per `proBusinessId` from business-master events |
| **Measured Value** | Range: **1–2 active users per dealer** (most have 1, one has 2) |
| **Contact Diversity** | 6 contact types observed: OWNER, TECHNICIAN, OFFICE ADMIN, CO-OWNER, CSC, OTHER |
| **Data Fields Used** | `detail.data.primaryContact.proContactId`, `detail.data.primaryContact.loginStatus`, `detail.data.proBusinessId` |
| **Gap** | Business-master events only carry `primaryContact`. Additional contacts visible in separate `contact-master` events but `proBusinessId` is often NULL on those. Need join key improvement. |
| **Feasibility** | **PARTIAL** — Undercounts because contact events lack `proBusinessId` |

---

## Category 4: Engagement (2 KPIs)

### KPI 4.1 — Dealer Stickiness (WAU/MAU)

| Attribute | Detail |
|-----------|--------|
| **Definition** | Weekly Active Users / Monthly Active Users ratio |
| **SQL Logic** | Requires per-session login timestamps to compute weekly vs monthly unique users |
| **Measured Value** | **NOT COMPUTABLE** |
| **Data Available** | Only `lastLoginDate` (single timestamp per contact) — cannot determine weekly recurrence |
| **Data Fields Used** | N/A |
| **Gap** | **No login/session event stream.** Need Cognito CloudWatch exports or application-level session tracking. `cognitoSubId` field confirms Cognito is the auth system — integration path exists. |
| **Feasibility** | **GAP** ❌ — Requires external login event stream |

---

### KPI 4.2 — Technician Stickiness (DAU/MAU)

| Attribute | Detail |
|-----------|--------|
| **Definition** | Daily Active Technicians / Monthly Active Technicians |
| **SQL Logic** | Same as 4.1 but filtered to `contactType=TECHNICIAN` |
| **Measured Value** | **NOT COMPUTABLE** |
| **Data Available** | Same limitation as 4.1 |
| **Gap** | Same as 4.1 |
| **Feasibility** | **GAP** ❌ — Requires external login event stream |

---

## Category 5: Revenue (2 KPIs)

### KPI 5.1 — Revenue from Active Dealers

| Attribute | Detail |
|-----------|--------|
| **Definition** | Total revenue generated by dealers who are active on the platform |
| **SQL Logic** | Join `fluidraAccountNumber` (from events) to revenue/transaction data |
| **Measured Value** | **NOT COMPUTABLE** — no revenue data in this table |
| **Join Key Available** | YES — `fluidraAccountNumber` present on 10 distinct businesses (e.g., 10121, 10427, 10155, 4055165) |
| **Data Fields Used** | `detail.data.fluidraAccountNumber` |
| **Gap** | **No revenue/transaction/purchase data** in Snowflake. Need PSOT revenue feed or Oracle extract. |
| **Feasibility** | **GAP** ❌ — Join key exists but no revenue table to join against |

---

### KPI 5.2 — Revenue Growth Comparison

| Attribute | Detail |
|-----------|--------|
| **Definition** | Revenue before vs after platform enrollment |
| **SQL Logic** | Compare revenue in period before `rewardsAccount.programSignupDate` vs after |
| **Measured Value** | **NOT COMPUTABLE** |
| **Data Available** | `rewardsAccount.programSignupDate` exists (can determine "before/after" boundary) but no revenue data |
| **Data Fields Used** | `detail.data.rewardsAccount.programSignupDate`, `detail.data.fluidraAccountNumber` |
| **Gap** | Same as 5.1 — need revenue table |
| **Feasibility** | **GAP** ❌ — Temporal boundary available, revenue data not |

---

## Summary: All 20 KPIs Mapped

| # | KPI | Category | Feasibility | Actual Value (Test) |
|---|-----|----------|:-----------:|---------------------|
| 1.1 | Total Active Dealer Accounts | Dealer Adoption | **PARTIAL** | 11 with active login, 3 active in last 30d |
| 1.2 | Total Enrolled Dealers | Dealer Adoption | **FULL** ✅ | 10 enrolled |
| 1.3 | Dealers Not Set Up | Dealer Adoption | **FULL** ✅ | 21 pending |
| 1.4 | Total Inactive Dealers | Dealer Adoption | **PARTIAL** | 8 inactive >30d |
| 1.5 | New Dealer Accounts Created | Dealer Adoption | **FULL** ✅ | 27 created |
| 2.1 | Guest-to-Lead Conversion | Dealer Conversion | **PARTIAL** 🆕 | 6 guests trackable |
| 2.2 | Lead Rejection Rate | Dealer Conversion | **PARTIAL** 🆕 | 3.5% (3/85) |
| 2.3 | Time to Approve Lead | Dealer Conversion | **PARTIAL** | 5.7s avg (auto-approve in test) |
| 2.4 | Approved to Rewards Activation | Dealer Conversion | **DERIVED** ✅ | Timestamps joinable |
| 3.1 | Total Active Users (TAU) | User Adoption | **PARTIAL** | 40+ active-flagged contacts |
| 3.2 | New Technician Accounts | User Adoption | **FULL** ✅ | 7 technicians created |
| 3.3 | Users Never Set Up | User Adoption | **FULL** ✅ | ~14 never completed setup |
| 3.4 | Inactive Users | User Adoption | **PARTIAL** | 8 stale contacts |
| 3.5 | Time to First Login | User Adoption | **DERIVED** ✅ | ~2 min avg (test) |
| 3.6 | First Login Rate | User Adoption | **DERIVED** ✅ | 60% (18/30) |
| 3.7 | Active Users per Dealer | User Adoption | **PARTIAL** | 1-2 per dealer |
| 4.1 | Dealer Stickiness (WAU/MAU) | Engagement | **GAP** ❌ | Not computable |
| 4.2 | Technician Stickiness (DAU/MAU) | Engagement | **GAP** ❌ | Not computable |
| 5.1 | Revenue from Active Dealers | Revenue | **GAP** ❌ | Not computable (join key exists) |
| 5.2 | Revenue Growth Comparison | Revenue | **GAP** ❌ | Not computable (join key exists) |

---

## Feasibility Scorecard

| Status | Count | % | KPIs |
|--------|:-----:|:-:|------|
| **FULL** | 5 | 25% | 1.2, 1.3, 1.5, 3.2, 3.3 |
| **DERIVED** | 3 | 15% | 2.4, 3.5, 3.6 |
| **PARTIAL** | 8 | 40% | 1.1, 1.4, 2.1, 2.2, 2.3, 3.1, 3.4, 3.7 |
| **GAP** | 4 | 20% | 4.1, 4.2, 5.1, 5.2 |

**Total immediately buildable (FULL + DERIVED): 8 KPIs (40%)**
**Total partially buildable: 8 KPIs (40%)**
**Hard gaps remaining: 4 KPIs (20%)**

---

## What's Needed to Close Remaining Gaps

| Gap KPIs | Blocking Data | Source | Integration Effort |
|----------|--------------|--------|-------------------|
| 4.1, 4.2 (Stickiness) | Per-login timestamps, session data | AWS Cognito CloudWatch → S3 → Snowpipe | Medium (2-3 weeks) — `cognitoSubId` join key confirmed |
| 5.1, 5.2 (Revenue) | Transaction amounts by dealer | PSOT/Oracle revenue extract → S3 → Snowpipe | Medium (2-3 weeks) — `fluidraAccountNumber` join key confirmed |

---

## Key Data Fields for Each KPI (Quick Reference)

```
KPI 1.1: detail.data.loginStatus + detail.data.primaryContact.lastLoginDate
KPI 1.2: detail.data.status + detail.data.rewardsAccount.programStatus
KPI 1.3: detail.data.loginStatus = 'PENDING'
KPI 1.4: detail.data.primaryContact.lastLoginDate (staleness check)
KPI 1.5: event type 'pro-business-master.created.v1' (count)
KPI 2.1: detail.data.status = 'GUEST' → track to 'LEAD'
KPI 2.2: event types 'lead.rejected' + 'business-master.rejected' (count)
KPI 2.3: detail.data.auditInfo.createdAt → event time (diff)
KPI 2.4: approved event time → detail.data.rewardsAccount.auditInfo.createdAt
KPI 3.1: detail.data.primaryContact.loginStatus + lastLoginDate
KPI 3.2: event 'pro-contact-master.created.v1' + detail.data.contactType = 'TECHNICIAN'
KPI 3.3: created contacts without matching 'login-created' event
KPI 3.4: contacts with loginStatus=ACTIVE but stale lastLoginDate
KPI 3.5: login-created.time - contact-created.auditInfo.createdAt
KPI 3.6: COUNT(login-created contacts) / COUNT(created contacts)
KPI 3.7: distinct active contacts per proBusinessId
KPI 4.1: NEEDS: per-session login timestamps (Cognito)
KPI 4.2: NEEDS: per-session login timestamps (Cognito) filtered by contactType
KPI 5.1: NEEDS: revenue table JOIN ON fluidraAccountNumber
KPI 5.2: NEEDS: revenue table + rewardsAccount.programSignupDate as pivot
```
