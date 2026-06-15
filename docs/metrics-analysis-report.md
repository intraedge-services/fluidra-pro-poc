# Fluidra Pro Adoption Dashboard — Metrics Analysis Report

**Generated**: June 15, 2026 
**Data Source**: RAW_DB_PROD.FLUIDRAPRO_RAW.RAW_DEALERS_DATA (100 CDC events) 
**Environment**: Test 
**Refresh**: Live from Snowflake via dbt models

---

## Executive Summary

The Fluidra Pro platform currently has **13 dealers** and **21 users** tracked in the system. Key metrics indicate significant gaps against targets:

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Active Dealer Rate | 53.8% | 90% | 🔴 RED (-36.2%) |
| First Login Rate | 61.9% | 75% | 🔴 RED (-13.1%) |
| Active Users per Dealer | 1.86 | 3.0 | 🔴 RED (-1.14) |
| Dealer Stickiness | — | >20% | ⏳ PENDING |
| Technician Stickiness | — | >40% | ⏳ PENDING |
| Revenue Growth | — | — | ⏳ PENDING |

---

## Dealer Adoption Metrics

### Overall Counts

| Metric | Value |
|--------|-------|
| Total Dealers | 13 |
| Active Dealers | 7 (53.8%) |
| Enrolled Dealers | 7 |
| Inactive Dealers | 1 |
| Dealers Not Set Up | 5 |
| New Dealers (Last 30 days) | 4 |

### Dealer Activity by Business Type

| Business Type | Active | Inactive | Not Set Up | Total |
|--------------|--------|----------|-----------|-------|
| BUILDER | 4 | 0 | 2 | 6 |
| SERVICE | 3 | 0 | 2 | 5 |
| RETAILER | 0 | 1 | 1 | 2 |

**Insight**: Builders have the highest activation rate (67%), followed by Service (60%). Retailers have 0% activation — both retailer accounts are either inactive or not set up.

### Dealer Detail

| Dealer | Type | Achiever Level | Program | Status |
|--------|------|---------------|---------|--------|
| BLUEBIRD POOL SERVICE LLC | SERVICE | — | SERVICEPRO | ✅ Active |
| HUNTINGTON WOODS POOLS & SPAS | SERVICE | SERVICEPRO ELITE | FLATRATE SERVICEPRO | ✅ Active |
| SWIMMING POOL SERVICE | SERVICE | — | BASE REWARDS | ✅ Active |
| Sales ProEdge Test | BUILDER | — | RETAIL SELECT | ✅ Active |
| TRI MAR INVESTMENTS LLC | BUILDER | — | BASE REWARDS | ✅ Active |
| Test Bizz | BUILDER | BUILDER PROEDGE PARTNER | PROEDGE | ✅ Active |
| Test10 | BUILDER | — | RETAIL SELECT | ✅ Active |
| GECKLER POOLS & SPAS | RETAILER | — | RETAIL SELECT | 🟡 Inactive |
| J & S POOL AND SPA SERVICE | SERVICE | SERVICEPRO ELITE | SERVICEPRO | 🔴 Not Set Up |
| JOSEPH MENA POOLS | SERVICE | — | — | 🔴 Not Set Up |
| NCC | BUILDER | BUILDER PROEDGE PARTNER | PROEDGE | 🔴 Not Set Up |
| TOWN & COUNTRY POOLS, INC. | RETAILER | — | — | 🔴 Not Set Up |
| Test owner | BUILDER | BUILDER PROEDGE PARTNER | PROEDGE | 🔴 Not Set Up |

---

## User Adoption Metrics

### Overall Counts

| Metric | Value |
|--------|-------|
| Total Users | 21 |
| Active Users | 13 (61.9%) |
| Users Never Set Up | 8 (38.1%) |
| Inactive Users | 0 |
| Total Technicians | 12 |
| New Technicians (30d) | 12 |
| Monthly Active Users | 13 |
| Active Users per Dealer | 1.86 |

### Users by Role and Login Status

| Role | Active | Pending (Never Logged In) | Total |
|------|--------|--------------------------|-------|
| TECHNICIAN | 6 | 6 | 12 |
| OWNER | 3 | 1 | 4 |
| CSC | 2 | 0 | 2 |
| OFFICE ADMIN | 1 | 0 | 1 |
| OTHER | 1 | 0 | 1 |
| CO-OWNER | 0 | 1 | 1 |

**Insight**: Technicians represent 57% of all users, but only 50% have logged in. Owners have 75% login rate. CSC, Office Admin, and Other roles have 100% activation.

### Key User Adoption Concerns

- **8 users (38%) have NEVER logged in** — primarily Technicians (6) and Owners/Co-owners (2)
- **Active Users per Dealer (1.86) is below target (3.0)** — indicates dealers aren't onboarding their full teams
- **First Login Rate (61.9%) below 75% target** — onboarding friction exists

---

## Engagement Metrics

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Monthly Active Users | 13 | — | — |
| Dealer Stickiness (WAU/MAU) | — | >20% | ⏳ PENDING |
| Technician Stickiness (DAU/MAU) | — | >40% | ⏳ PENDING |

**Blocked by**: No login event stream available. Stickiness ratios require daily/weekly login data.

---

## Lead Performance Metrics

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Current Leads | 1 | — | — |
| Avg Hours to Rewards Activation | 18,656 hrs | 24 hrs | 🔴 RED |
| Guest-to-Lead Conversion | — | — | ⏳ PENDING |
| Lead Rejection Rate | — | <5% | ⏳ PENDING |
| Lead Approval Time | — | <24 hrs | ⏳ PENDING |

**Note**: The 18,656 hours figure is an artifact of test data — it measures time between account creation dates (some from 2016-2024) and recent program signup dates. In production with real-time data, this will reflect actual approval-to-activation latency.

**Blocked by**: Salesforce integration needed for full lead funnel (rejection rate, approval time, guest-to-lead).

---

## Revenue Metrics

| Metric | Value | Status |
|--------|-------|--------|
| Revenue — Active Dealers | — | ⏳ PENDING |
| Revenue Growth | — | ⏳ PENDING |
| Revenue per Active Dealer | — | ⏳ PENDING |

**Blocked by**: PSOT Revenue Data integration not yet established.

---

## Data Availability Summary

| KPI Category | Calculable Now | Pending Data Source |
|-------------|---------------|--------------------|
| Dealer Adoption (5 KPIs) | ✅ 5/5 | — |
| User Adoption (7 KPIs) | ✅ 5/7 | Login events (2) |
| Engagement (2 KPIs) | ❌ 0/2 | Login event stream |
| Lead Performance (4 KPIs) | ⚠️ 1/4 | Salesforce (3) |
| Revenue (2 KPIs) | ❌ 0/2 | PSOT Revenue |
| **TOTAL** | **11/20** | **9 pending** |

---

## Recommendations

1. **Immediate**: Address the 5 dealers with "Not Set Up" status — reach out to activate their accounts
2. **Immediate**: Investigate why 50% of Technicians haven't logged in — possible onboarding friction
3. **Short-term**: Integrate login event stream to enable Stickiness KPIs
4. **Short-term**: Connect Salesforce for lead funnel visibility (rejection rate is reportedly ~70%)
5. **Medium-term**: Integrate PSOT Revenue to show program ROI
6. **Retailer Focus**: Both retailer accounts are underperforming — segment-specific intervention needed

---

## Program Levels Observed

| Program Level | Active Dealers | Total Dealers |
|--------------|---------------|---------------|
| SERVICEPRO | 1 | 2 |
| FLATRATE SERVICEPRO | 1 | 1 |
| BASE REWARDS | 2 | 2 |
| PROEDGE | 1 | 3 |
| RETAIL SELECT | 2 | 3 |

## Achiever Levels Observed

| Achiever Level | Count |
|---------------|-------|
| SERVICEPRO ELITE | 2 |
| BUILDER PROEDGE PARTNER | 3 |
| (None assigned) | 8 |
