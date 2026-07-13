# Dimensional Model — Latest Analysis

## Source Data

- **Table:** `RAW_DB_PROD.FLUIDRAPRO_RAW.FPRO_QA`
- **Total Events:** 4,043
- **Distinct Businesses:** 243
- **Date Range:** Apr 20 – Jul 13, 2026
- **Event Types:** 18
- **Environment:** QA (actual Fluidra Pro data)

---

## Snowflake Objects Created

### INTERMEDIATE (Staging Layer)

| View | Rows | Source Events | Grain |
|------|:----:|---------------|-------|
| `STG_FPRO_QA_BUSINESSES` | 240 | pro-business-master.* (6 types) | 1 per pro_business_id (latest) |
| `STG_FPRO_QA_BUSINESS_DISTRIBUTORS` | 292 | distributors[] flattened | 1 per (biz, dist_name, acct#) |
| `STG_FPRO_QA_BUSINESS_PROGRAM_OPTINS` | 236 | programOptIns[] flattened | 1 per (biz, program_name) |
| `STG_FPRO_QA_BUSINESS_SUBSCRIPTIONS` | 16 | subscriptions[] flattened | 1 per (biz, subscription_id) |
| `STG_FPRO_QA_CONTACTS` | 482 | pro-contact-master.* (4 types) | 1 per pro_contact_id (latest) |
| `STG_FPRO_QA_LEADS` | 178 | pro-business-lead.* (2 types) | 1 per lead decision event |
| `STG_FPRO_QA_KEY_ACCOUNT_TYPES` | 12 | pro-key-account-type-master.* (2 types) | 1 per key_account_type_id |
| `STG_FPRO_QA_LOCATIONS` | 4 | pro-location-master.* (2 types) | 1 per pro_location_id |
| `STG_FPRO_QA_RECONCILIATION` | 86 | pro-reconcile.completed (1 type) | 1 per reconciliation run |
| `STG_FPRO_QA_GUEST_TECHNICIANS` | 7 | pro-guest-technician-master.* (1 type) | 1 per pro_contact_id |

### DIMENSIONS Layer

| View | Rows | Description |
|------|:----:|-------------|
| `DIM_PRO_BUSINESS_MASTER` | 240 | Complete dealer profile with aggregated distributor/program/subscription counts |
| `DIM_CONTACT` | 485 | All contacts with bridge-resolved dealer linkage |
| `DIM_LOCATION` | 236 | Standalone + embedded locations (billing/shipping) |
| `DIM_KEY_ACCOUNT_TYPE` | 12 | Key account type definitions (Poolwerx, APE, etc.) |
| `DIM_DISTRIBUTOR` | 292 | Distributor associations per dealer |
| `DIM_PROGRAM_OPT_IN` | 236 | Program enrollments per dealer |
| `DIM_SUBSCRIPTION` | 16 | IoT subscriptions (ION POOL CARE) |
| `BRIDGE_CONTACT_DEALER` | 249 | Contact ↔ Dealer linkage (resolves NULL FK) |

---

## Event Type Coverage (All 18 Covered)

| Event Type | Count | Staging Model |
|-----------|:-----:|---------------|
| `pro-business-master.updated.v1` | 461 | STG_FPRO_QA_BUSINESSES |
| `pro-business-master.created.v1` | 200 | STG_FPRO_QA_BUSINESSES |
| `pro-business-master.approved.v1` | 144 | STG_FPRO_QA_BUSINESSES |
| `pro-business-master.update-requested.v1` | 123 | STG_FPRO_QA_BUSINESSES |
| `pro-business-master.creation-failed.v1` | 87 | STG_FPRO_QA_BUSINESSES |
| `pro-business-master.rejected.v1` | 1 | STG_FPRO_QA_BUSINESSES |
| `pro-business-lead.approved.v1` | 176 | STG_FPRO_QA_LEADS |
| `pro-business-lead.rejected.v1` | 2 | STG_FPRO_QA_LEADS |
| `pro-contact-master.updated.v1` | 2,252 | STG_FPRO_QA_CONTACTS |
| `pro-contact-master.created.v1` | 342 | STG_FPRO_QA_CONTACTS |
| `pro-contact-master.login-created.v1` | 127 | STG_FPRO_QA_CONTACTS |
| `pro-contact-master.deleted.v1` | 2 | STG_FPRO_QA_CONTACTS |
| `pro-guest-technician-master.deleted.v1` | 7 | STG_FPRO_QA_GUEST_TECHNICIANS |
| `pro-key-account-type-master.updated.v1` | 11 | STG_FPRO_QA_KEY_ACCOUNT_TYPES |
| `pro-key-account-type-master.created.v1` | 10 | STG_FPRO_QA_KEY_ACCOUNT_TYPES |
| `pro-location-master.updated.v1` | 5 | STG_FPRO_QA_LOCATIONS |
| `pro-location-master.created.v1` | 4 | STG_FPRO_QA_LOCATIONS |
| `pro-reconcile.completed.v1` | 86 | STG_FPRO_QA_RECONCILIATION |

---

## Key Design Decisions

### Two-Tier Staging Pattern

```
Raw JSON Event
    │
    ├── Tier 1: Scalar Staging (one row per entity, deduped)
    │   └── stg_fpro_qa_businesses (240 rows from 1,016 events)
    │
    └── Tier 2: Array Staging (LATERAL FLATTEN, one row per array element)
        ├── stg_fpro_qa_business_distributors (292 rows)
        ├── stg_fpro_qa_business_program_optins (236 rows)
        └── stg_fpro_qa_business_subscriptions (16 rows)
```

### Why Two Tiers?

A single business event contains scalar fields AND nested arrays:

```json
{
  "proBusinessId": "biz-123",
  "businessName": "PRIDE POOLS",        ← scalar (Tier 1)
  "status": "ACTIVE",                   ← scalar (Tier 1)
  "distributors": [                     ← array (Tier 2)
    {"distributorName": "POOLCORP", "status": "ACTIVE"},
    {"distributorName": "HERITAGE", "status": "ACTIVE"}
  ],
  "programOptIns": [                    ← array (Tier 2)
    {"programName": "PROEDGE", "programStatus": "ACTIVE"}
  ]
}
```

You cannot flatten multiple arrays in one model without creating a Cartesian product (2 distributors × 1 program = 2 rows with duplicated program data). Each array gets its own model.

### Materialization Strategy

| Layer | Materialization | Rationale |
|-------|:-:|---|
| Staging | **view** | Small data (<5K events), always fresh, no storage cost |
| Dimension | **table** (full refresh) | 240 dealers — rebuilds in <5 seconds, simple and correct |

### When to Change

- Raw events > 500K → switch staging to **incremental**
- DIM rebuild > 60 seconds → switch DIM to **incremental** with merge
- Need history tracking → add **dbt snapshot** (SCD Type 2)

---

## BRIDGE_CONTACT_DEALER — Why It Exists

### The Problem

Contact events (`pro-contact-master.created.v1`) have `proBusinessId = NULL` in 99% of cases.

```
482 total contacts
  5 have proBusinessId directly (1%)
477 have NULL proBusinessId (99%)
```

### The Solution

The dealer-to-contact link lives inside **business-master events** as an embedded object:

```json
// pro-business-master.updated.v1
{
  "proBusinessId": "biz-123",          ← dealer ID
  "primaryContact": {
    "proContactId": "6047695d-..."     ← contact ID
  }
}
```

The BRIDGE extracts this relationship:

```sql
BRIDGE_CONTACT_DEALER:
| pro_business_id | pro_contact_id | relationship_type |
|-----------------|----------------|-------------------|
| biz-123         | 6047695d-...   | PRIMARY_CONTACT   |
```

### Results

| Metric | Without Bridge | With Bridge |
|--------|:-:|:-:|
| Contacts linked to a dealer | 5 | **241** |
| Orphaned contacts | 477 | 244 |

### Why 244 Remain Orphaned

These are **secondary contacts** (technicians, office admins added to a business) who never appeared as `primaryContact` in any business-master event. The platform only embeds the primary contact — secondary contacts exist only in their own events without a back-reference.

**To resolve:** Would need either:
1. Platform to emit `proBusinessId` on all contact events (source fix)
2. A separate "contact-added-to-business" event type
3. Match by email across business and contact events (fuzzy, not reliable)

---

## DIM_PRO_BUSINESS_MASTER — Health Status Distribution

| Health Status | Count | % | Definition |
|:---:|:---:|:---:|---|
| NOT_ONBOARDED | 142 | 59% | `loginStatus = PENDING` — never completed setup |
| AT_RISK | 85 | 35% | Active account but no login in 30+ days |
| HEALTHY | 8 | 3% | Active login within last 30 days |
| GUEST | 0 | 0% | Guest status |
| REJECTED | 0 | 0% | Rejected |

### Key Insight

Only **3% of dealers are healthy** (active login within 30 days). This is QA data so the numbers reflect test patterns, but the model correctly identifies onboarding friction — 59% never completed login setup.

---

## DIM_CONTACT — Login Status Distribution

| Contact Type | Total | Active | Pending | Activation Rate |
|-------------|:-----:|:------:|:-------:|:-:|
| OWNER | 265 | 129 | 136 | 49% |
| TECHNICIAN | 130 | 43 | 65 | 33% |
| OFFICE ADMIN | 32 | 12 | 11 | 38% |
| CO-OWNER | 27 | 14 | 11 | 52% |
| OTHER | 16 | 4 | 5 | 25% |
| CSC | 12 | 6 | 4 | 50% |

### Key Insight

Technicians have the **lowest activation rate (33%)** — significant onboarding friction for the user type most critical to daily platform usage.

---

## Lead Funnel Analysis (STG_FPRO_QA_LEADS)

| Metric | Value |
|--------|:-----:|
| Total lead decisions | 178 |
| Approved | 176 (98.9%) |
| Rejected | 2 (1.1%) |
| Avg time to decision | 26.3 seconds |
| Sources | pro-platform-core (3,632), Salesforce (322) |

---

## Architecture Flow

```
RAW_DB_PROD.FLUIDRAPRO_RAW.FPRO_QA
    │
    │ PARSE_JSON + FILTER + DEDUPLICATE
    │
    ▼
ANALYTICS_DB_DEV.INTERMEDIATE (10 staging views)
    │
    │ AGGREGATE + JOIN + BRIDGE
    │
    ▼
ANALYTICS_DB_DEV.DIMENSIONS (8 dimension views)
    │
    │ (Next: Fact tables + Metric views)
    │
    ▼
ANALYTICS_DB_DEV.FACTS (to be built)
    │
    ▼
ANALYTICS_DB_DEV.MARTS (KPI metrics — to be built)
```
