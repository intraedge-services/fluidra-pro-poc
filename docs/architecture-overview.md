# Fluidra Pro Analytics Platform — Architecture

## System Architecture Overview

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                        SOURCE SYSTEMS                                        │
│  Kafka CDC (Fluidra Pro)  |  Salesforce  |  Oracle  |  PSOT Revenue          │
└─────────────────────────────────────┬──────────────────────────────────────┘
                                            │
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                    S3 DATA LAKE (us-east-1)                                    │
│  s3://fluidra-data-lake/raw/fluidrapro/   (Kafka CDC JSON)                    │
│  s3://fluidra-data-lake/raw/salesforce/   (Batch CSV)                         │
│  s3://fluidra-data-lake/raw/oracle/        (Batch CSV)                        │
│  s3://fluidra-data-lake/raw/revenue/       (Batch CSV/Parquet)                │
└─────────────────────────────────────┬──────────────────────────────────────┘
                                            │ S3 Event Notification
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│              SNOWFLAKE INGESTION LAYER (WH_INGEST - X-SMALL)                   │
│  Snowpipe (PIPE_FLUIDRAPRO_CDC)  |  External Stages  |  File Formats         │
│  Streams (STRM_RAW_DEALERS_DATA) |  Hourly Batch     |  ON_ERROR=CONTINUE    │
└─────────────────────────────────────┬──────────────────────────────────────┘
                                            │
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│                RAW_DB (Landing Zone - Append Only)                             │
│  FLUIDRAPRO_RAW.RAW_DEALERS_DATA  (100 records, CDC JSON)                     │
│  SALESFORCE_RAW.*                 (placeholder tables)                        │
│  ORACLE_RAW.*                     (placeholder tables)                        │
│  REVENUE_RAW.*                    (placeholder tables)                        │
└─────────────────────────────────────┬──────────────────────────────────────┘
                                            │ dbt source()
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│           dbt Cloud TRANSFORMATION LAYER (WH_DBT_PROD - MEDIUM)                │
│                                                                               │
│  STAGING_DB.STAGING                                                           │
│    ├─ stg_fluidrapro_contacts     (parse JSON, deduplicate, type cast)        │
│    └─ stg_fluidrapro_businesses   (parse JSON, deduplicate, type cast)        │
│                                                                               │
│  ANALYTICS_DB.INTERMEDIATE                                                    │
│    ├─ int_dealer_activity          (dealer-level aggregation)                 │
│    └─ int_user_activity            (user-level activity flags)                │
│                                                                               │
│  ANALYTICS_DB.DIMENSIONS                                                      │
│    ├─ dim_date                     (2020-2030 calendar)                       │
│    ├─ dim_dealer                   (dealer attributes + SCD2 snapshot)        │
│    └─ dim_user                     (user/contact attributes)                  │
│                                                                               │
│  ANALYTICS_DB.MARTS                                                           │
│    ├─ mart_dealer_adoption         (5 dealer KPIs + RAG status)              │
│    ├─ mart_user_adoption           (7 user KPIs + RAG status)                │
│    ├─ mart_engagement              (stickiness ratios - PENDING)             │
│    ├─ mart_lead_performance        (lead funnel - PARTIAL)                   │
│    └─ mart_revenue                 (revenue KPIs - PENDING)                  │
│                                                                               │
│  ANALYTICS_DB.REPORTING                                                       │
│    ├─ vw_dashboard_summary         (all KPIs in one row)                     │
│    ├─ vw_dealer_adoption           (dealer drill-down)                       │
│    └─ vw_user_adoption             (user drill-down)                         │
└─────────────────────────────────────┬──────────────────────────────────────┘
                                            │
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────┐
│              CONSUMPTION LAYER (WH_BI - MEDIUM / WH_ADHOC - SMALL)             │
│  Snowsight Dashboards  |  Product Manager  |  Executive  |  Sales Ops        │
│  Analyst Ad-hoc Queries (WH_ADHOC, 15 min timeout)                            │
└───────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────────────┐
│                        GOVERNANCE_DB                                          │
│  AUDIT (access logs)  |  MONITORING (pipeline health)  |  DATA_QUALITY (dbt)  │
└───────────────────────────────────────────────────────────────────────────────┘
```

---

## Snowflake Account Layout

### Databases (12 = 4 base × 3 environments)

| Base Database | Purpose | DEV | TEST | PROD |
|--------------|---------|-----|------|------|
| RAW_DB | Landing zone (append-only raw data) | RAW_DB_DEV | RAW_DB_TEST | RAW_DB_PROD |
| STAGING_DB | dbt staging models (parse, type, DQ) | STAGING_DB_DEV | STAGING_DB_TEST | STAGING_DB_PROD |
| ANALYTICS_DB | Dimensions, facts, marts, reporting | ANALYTICS_DB_DEV | ANALYTICS_DB_TEST | ANALYTICS_DB_PROD |
| GOVERNANCE_DB | Audit, monitoring, data quality | GOVERNANCE_DB_DEV | GOVERNANCE_DB_TEST | GOVERNANCE_DB_PROD |

### Schemas per Database

| Database | Schemas |
|----------|----------|
| RAW_DB | FLUIDRAPRO_RAW, SALESFORCE_RAW, ORACLE_RAW, REVENUE_RAW |
| STAGING_DB | STAGING |
| ANALYTICS_DB | INTERMEDIATE, DIMENSIONS, FACTS, MARTS, REPORTING |
| GOVERNANCE_DB | AUDIT, MONITORING, DATA_QUALITY |

### Warehouses (6)

| Warehouse | Size | Role | Purpose | Auto-Suspend |
|-----------|------|------|---------|-------------|
| WH_INGEST | X-SMALL | DATA_ENGINEER_ROLE | Snowpipe/batch loads | 60s |
| WH_DBT_DEV | SMALL | DBT_DEV_ROLE | dbt development | 60s |
| WH_DBT_TEST | SMALL | DBT_TEST_ROLE | dbt test (PR merge) | 60s |
| WH_DBT_PROD | MEDIUM | DBT_PROD_ROLE | dbt production (hourly) | 60s |
| WH_BI | MEDIUM | BI_ROLE | Snowsight dashboards | 60s |
| WH_ADHOC | SMALL | ANALYST_ROLE | Ad-hoc queries (15m timeout) | 60s |

---

## RBAC Role Hierarchy

```
ACCOUNTADMIN
├── SECURITYADMIN
└── SYSADMIN
    ├── DATA_ENGINEER_ROLE
    │   ├── DBT_DEV_ROLE      → SVC_DBT_DEV
    │   ├── DBT_TEST_ROLE     → SVC_DBT_TEST
    │   └── DBT_PROD_ROLE     → SVC_DBT_PROD
    └── BI_ROLE
        └── ANALYST_ROLE
```

### Permission Matrix (PROD)

| Role | RAW_DB | STAGING_DB | ANALYTICS_DB | GOVERNANCE_DB | Warehouse |
|------|--------|-----------|--------------|--------------|------------|
| DATA_ENGINEER_ROLE | ALL | ALL | ALL | ALL | WH_INGEST |
| DBT_PROD_ROLE | SELECT | ALL | ALL | INSERT (DQ) | WH_DBT_PROD |
| BI_ROLE | — | — | SELECT (MARTS, REPORTING) | — | WH_BI |
| ANALYST_ROLE | — | SELECT | SELECT (all schemas) | SELECT (DQ) | WH_ADHOC |

---

## dbt Model Architecture

### Layer Responsibilities

| Layer | Database | Purpose | Materialization |
|-------|----------|---------|----------------|
| **Staging** | STAGING_DB | Parse JSON, type cast, deduplicate, DQ checks | View |
| **Intermediate** | ANALYTICS_DB | Reusable business logic aggregations | Table |
| **Dimensions** | ANALYTICS_DB | Conformed dimensions (surrogate keys, SCD2) | Table |
| **Facts** | ANALYTICS_DB | Grain-specific event/transaction tables | Incremental |
| **Marts** | ANALYTICS_DB | KPI calculations by business domain | Table |
| **Reporting** | ANALYTICS_DB | Pre-joined views for Snowsight | View |

### dbt Model DAG

```
RAW_DEALERS_DATA
    │
    ▼
stg_fluidrapro_contacts    stg_fluidrapro_businesses
    │                              │
    ├──────────────┬──────────────┤
    ▼              ▼              ▼
int_user_activity  int_dealer_activity  dim_dealer
    │              │              │
    ▼              ▼              ▼
dim_user     mart_dealer_adoption   mart_lead_performance
    │              │
    ▼              ▼
mart_user_adoption  mart_engagement
    │              │
    └──────┬───────┘
         ▼
  vw_dashboard_summary
  vw_dealer_adoption
  vw_user_adoption
```

---

## KPI Coverage (20 Total)

| Category | KPIs | Status |
|----------|------|--------|
| Dealer Adoption | Active Dealers, Enrolled, Inactive, Not Set Up, New Accounts | ✅ 5/5 Live |
| User Adoption | TAU, Technicians, Never Set Up, First Login Rate, Users per Dealer | ✅ 5/7 Live |
| Engagement | Dealer Stickiness, Technician Stickiness | ⏳ 0/2 Pending |
| Lead Performance | Rewards Activation Time | ⚠️ 1/4 Partial |
| Revenue | Revenue, Growth | ⏳ 0/2 Pending |

---

## Data Flow Summary

| Step | Component | Latency |
|------|-----------|--------|
| 1. Events generated | Fluidra Pro Platform | Real-time |
| 2. Published to Kafka | Kafka (psot_poolpro_inbound) | < 1 second |
| 3. Written to S3 | Kafka Connect | < 5 minutes |
| 4. Loaded to Snowflake | Snowpipe (hourly batch) | ≤ 1 hour |
| 5. Transformed by dbt | dbt Cloud (hourly schedule) | ≤ 2 hours total |
| 6. Queried by users | Snowsight dashboards | Sub-second |

**End-to-end latency**: Event → Dashboard = approximately 2 hours

---

## Security Architecture

- **Authentication**: Key-pair (RSA) for service accounts, Password + MFA for humans
- **Authorization**: Role-based (RBAC) with least-privilege grants
- **Data Protection**: Time Travel (1 day) + Fail-safe (7 days)
- **Network**: IP allowlisting available (not yet configured)
- **Cost Controls**: Resource monitors (100 credits/month account cap)
- **Audit**: Snowflake ACCOUNT_USAGE + GOVERNANCE_DB.AUDIT schema
- **Future Grants**: New dbt objects auto-inherit role permissions

---

## Technology Stack

| Component | Technology | Version |
|-----------|-----------|--------|
| Data Warehouse | Snowflake | Enterprise |
| Transformation | dbt Core / dbt Cloud | 2.0 / Latest |
| Orchestration | dbt Cloud Jobs | Hourly |
| Source Control | GitHub | intraedge-services/fluidra-pro-poc |
| Streaming | Kafka → S3 → Snowpipe | — |
| BI Tool | Snowsight | Native |
| CI/CD | dbt Cloud (DEV/TEST/PROD jobs) | — |
| MCP Servers | Snowflake MCP + dbt MCP + GitHub MCP | Connected |
