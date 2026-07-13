# Facts & Metrics — Latest Analysis

## All Objects Live in Snowflake

**Database:** `ANALYTICS_DB_DEV`

---

## FACTS Layer (4 Views)

| View | Rows | Grain | Source Events |
|------|:----:|-------|---------------|
| `FCT_DEALER_EVENTS` | ~1,016 | 1 per business event | pro-business-master.* (all 6 types) |
| `FCT_CONTACT_EVENTS` | ~2,723 | 1 per contact event | pro-contact-master.* (all 4 types) |
| `FCT_LEAD_FUNNEL` | ~610 | 1 per funnel stage transition | created + approved + rejected + failed |
| `FCT_RECONCILIATION` | 86 | 1 per reconciliation run | pro-reconcile.completed |

---

## MARTS Layer (7 Metric Views)

### METRIC_DEALER_ADOPTION (KPIs 1.1–1.5)

| KPI | Metric | Value |
|:---:|--------|:-----:|
| 1.1 | Active Dealers (login in 30d) | **8** |
| 1.2 | Enrolled Dealers (ACTIVE + rewards ACTIVE) | **26** |
| 1.3 | Dealers Not Setup (PENDING login) | **142** |
| 1.4 | Inactive Dealers (ACTIVE but no login 30d) | **85** |
| 1.5 | New Dealer Accounts Created | **200** |
| — | Total Dealers | **240** |

### METRIC_DEALER_CONVERSION (KPIs 2.1–2.4)

| KPI | Metric | Value |
|:---:|--------|:-----:|
| 2.1 | Guests Trackable | **41** |
| 2.1 | Leads Created | **159** |
| — | Leads Approved | **176** |
| — | Businesses Approved | **144** |
| 2.2 | Rejection Rate | **0.93%** |
| 2.3 | Avg Seconds to Approve | **~956K** (QA data includes old records) |
| — | Creation Failures | **87** |
| — | Total Funnel Events | **610** |

### METRIC_USER_ADOPTION (KPIs 3.1–3.7)

| KPI | Metric | Value |
|:---:|--------|:-----:|
| 3.1 | Total Active Users | **211** |
| 3.2 | New Technicians Created | **68** |
| 3.3 | Users Never Setup | **220** |
| 3.4 | Inactive Users | **82** |
| 3.6 | First Login Rate | **36.6%** |
| — | Total Contacts Created | **347** |
| — | Total Login-Created Events | **127** |

### METRIC_PROGRAM_ENROLLMENT

| Program | Active | Pending | Declined | Total | Activation Rate |
|---------|:------:|:-------:|:--------:|:-----:|:-:|
| FLATRATE SERVICEPRO | 10 | 57 | 4 | 73 | 13.7% |
| PROEDGE | 15 | 29 | 2 | 55 | 27.3% |
| BASE REWARDS | 10 | 23 | 3 | 39 | 25.6% |
| SERVICEPRO | 14 | 17 | 2 | 36 | 38.9% |
| RETAIL SELECT | 8 | 18 | 1 | 31 | 25.8% |
| RETAIL SELECT STAR | 2 | 0 | 0 | 2 | 100.0% |

### METRIC_CONTACT_ONBOARDING

| Contact Type | Created | Completed Login | Never Setup | Login Rate | Avg Min to Login |
|-------------|:-------:|:-:|:-:|:-:|:-:|
| OWNER | 205 | 69 | 136 | 33.7% | 4.8 min |
| TECHNICIAN | 68 | 19 | 49 | 27.9% | 4.8 min |
| CO-OWNER | 29 | 18 | 11 | 62.1% | 5.8 min |
| OFFICE ADMIN | 18 | 10 | 8 | 55.6% | 2.5 min |
| CSC | 16 | 9 | 7 | 56.3% | 1.1 min |
| OTHER | 15 | 6 | 9 | 40.0% | 6.0 min |

### METRIC_DISTRIBUTOR_COVERAGE (Top 10)

| Distributor | Active Dealers | Pending | Inactive | Total | Active Rate |
|------------|:-:|:-:|:-:|:-:|:-:|
| ALLIOWA POOLS | 11 | 20 | 4 | 35 | 31.4% |
| ALPHA WATER | 7 | 7 | 5 | 18 | 38.9% |
| POOLCORP | 7 | 1 | 2 | 10 | 70.0% |
| COVERPOOLS | 7 | 1 | 3 | 9 | 77.8% |
| Cinderella, Inc. | 1 | 6 | 1 | 8 | 12.5% |
| AQUA GON INC. | 3 | 4 | 1 | 7 | 42.9% |
| COVER POOLS INC | 0 | 3 | 3 | 5 | 0.0% |
| BLUE WATER PRODUCTS | 3 | 3 | 1 | 5 | 60.0% |
| AMERICAN POOL SUPPLY | 2 | 1 | 2 | 5 | 40.0% |
| BEL-AQUA POOL SUPPLY | 0 | 2 | 2 | 4 | 0.0% |

### METRIC_FUNNEL_DAILY (sample)

Daily funnel showing approvals, rejections, failures, and approval rate per day.

---

## Key Insights from Live Data

### 1. Onboarding is the #1 Problem
- **59% of dealers** (142/240) never completed login setup
- **63% of contacts** (220/347 created) never setup login
- Technicians have the worst rate: only **27.9%** complete login

### 2. Program Activation is Slow
- FLATRATE SERVICEPRO has 73 enrollments but only **13.7% activated**
- 57 dealers stuck in PENDING — potential revenue leak

### 3. Distributor Network Health Varies
- POOLCORP and COVERPOOLS have **70-78% active rates** (healthy)
- ALLIOWA POOLS has 35 dealers but only **31% active** (needs attention)
- COVER POOLS INC has **0% active** — all pending or inactive

### 4. Lead Funnel is Efficient
- Only **0.93% rejection rate** — almost all leads get approved
- **87 creation failures** (all duplicate email) — significant onboarding friction
- 41 GUEST registrations tracked — conversion funnel is measurable

---

## Complete Object Inventory

```
ANALYTICS_DB_DEV
├── INTERMEDIATE/ (10 staging views)
│   ├── STG_FPRO_QA_BUSINESSES (240)
│   ├── STG_FPRO_QA_BUSINESS_DISTRIBUTORS (292)
│   ├── STG_FPRO_QA_BUSINESS_PROGRAM_OPTINS (236)
│   ├── STG_FPRO_QA_BUSINESS_SUBSCRIPTIONS (16)
│   ├── STG_FPRO_QA_CONTACTS (482)
│   ├── STG_FPRO_QA_LEADS (178)
│   ├── STG_FPRO_QA_KEY_ACCOUNT_TYPES (12)
│   ├── STG_FPRO_QA_LOCATIONS (4)
│   ├── STG_FPRO_QA_RECONCILIATION (86)
│   └── STG_FPRO_QA_GUEST_TECHNICIANS (7)
│
├── DIMENSIONS/ (8 dimension views)
│   ├── DIM_PRO_BUSINESS_MASTER (240)
│   ├── DIM_CONTACT (485)
│   ├── DIM_LOCATION (236)
│   ├── DIM_KEY_ACCOUNT_TYPE (12)
│   ├── DIM_DISTRIBUTOR (292)
│   ├── DIM_PROGRAM_OPT_IN (236)
│   ├── DIM_SUBSCRIPTION (16)
│   └── BRIDGE_CONTACT_DEALER (249)
│
├── FACTS/ (4 fact views)
│   ├── FCT_DEALER_EVENTS (~1,016)
│   ├── FCT_CONTACT_EVENTS (~2,723)
│   ├── FCT_LEAD_FUNNEL (~610)
│   └── FCT_RECONCILIATION (86)
│
└── MARTS/ (7 metric views)
    ├── METRIC_DEALER_ADOPTION (KPI 1.1-1.5)
    ├── METRIC_DEALER_CONVERSION (KPI 2.1-2.4)
    ├── METRIC_USER_ADOPTION (KPI 3.1-3.7)
    ├── METRIC_FUNNEL_DAILY (daily breakdown)
    ├── METRIC_PROGRAM_ENROLLMENT (by program)
    ├── METRIC_DISTRIBUTOR_COVERAGE (by distributor)
    └── METRIC_CONTACT_ONBOARDING (by contact type)
```

**Total: 29 Snowflake views** covering all 18 event types and computing 16 of 20 KPIs.
