# Fluidra Pro Analytics Platform — Architecture

## Interactive Diagrams (Draw.io)

Click to open editable diagrams in draw.io:

| Diagram | Link |
|---------|------|
| **Platform Architecture** | [Open in Draw.io](https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=%7B%22type%22%3A%22mermaid%22%2C%22compressed%22%3Atrue%2C%22data%22%3A%22fVLhjsIgEPwaHk2aGuMzlnY18dIUdxOfDLZoySK4UNbs3y9HvDRKTEgJ58xMhzPspT7XLTMdSpN5hRLs9%2Fsi%2BRcaTVCaEv7LpT5xg0aZKjjrnOG%2BPzFM1a3voxF5opZVYJZOSn%2Bs%2BI%2FjtgN6p%2F35yISK8rJZ4DU7cJRJ7ZpQ9X9zQjagQKU43ooDENON2AsOQK3kX9wPphSNQXntfVioMGvRsAD0%2BBm9yKuPPBhZcHOAu763XVYrcr2w0Y2rO6FV3%2FJUOwPOElq3vHGSR1XoEpfXgTMR4IqdbKu9YS%2BSpGiIEwB%2BrrO4QBHoVOnzXrJvDjS8xPPNepbRLZlsL0ZjVILp9EG24tBe0iLMtjvNTGPjLP9CfAgDNMxD6C%2Bv4NH1eb1k3eNCQJHMbohxtuHWf%2B%2FpvMUudYCCv1i0fc%2BraJgPhB9qJKZ3%2FaLXhbn%2BAw%3D%3D%22%7D) |
| **RBAC Role Hierarchy** | [Open in Draw.io](https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=%7B%22type%22%3A%22mermaid%22%2C%22compressed%22%3Atrue%2C%22data%22%3A%22fZFhC8IgEIZ%2FjR8HsdgPOPUIYbmht4GfJILoQxRE0N%2FPMWsjnSCI9z4PnHeX2%2BN9vp6eL1bvSLIdhPt3AFjDWV2DEN2gCeRR6fBkzT9oI2hRDEaRK5DORtTZbUriDEkg8KgPSiMab7oW87iMOCcvcZzBRtztKHys5T1aPEJLiTgV82a%2FmL3pZGJOxazJ1Wxytf0f0HHuGlr3bSsLTq%2BqYnucl1BKw%2BDTVSx5GHkpDm0nK1rJmQWuUiqmfTqhJQX9AQ%3D%3D%22%7D) |
| **CI/CD Pipeline** | [Open in Draw.io](https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=%7B%22type%22%3A%22mermaid%22%2C%22compressed%22%3Atrue%2C%22data%22%3A%22fVLbjsIgFPwaHk2aGuMzlnY18dIUdxOfDLZoySK4UNbs3y9HvDRKTEgJ58xMhzPspT7XLTMdSpN5hRLs9%2Fsi%2BRcaTVCaEv7LpT5xg0aZKjjrnOG%2BPzFM1a3voxF5opZVYJZOSn%2Bs%2BI%2FjtgN6p%2F35yISK8rJZ4DU7cJRJ7ZpQ9X9zQjagQKU43ooDENON2AsOQK3kX9wPphSNQXntfVioMGvRsAD0%2BBm9yKuPPBhZcHOAu763XVYrcr2w0Y2rO6FV3%2FJUOwPOElq3vHGSR1XoEpfXgTMR4IqdbKu9YS%2BSpGiIEwB%2BrrO4QBHoVOnzXrJvDjS8xPPNepbRLZlsL0ZjVILp9EG24tBe0iLMtjvNTGPjLP9CfAgDNMxD6C%2Bv4NH1eb1k3eNCQJHMbohxtuHWf%2B%2FpvMUudYCCv1i0fc%2BraJgPhB9qJKZ3%2FaLXhbn%2BAw%3D%3D%22%7D) |
| **dbt Model DAG** | [Open in Draw.io](https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=%7B%22type%22%3A%22mermaid%22%2C%22compressed%22%3Atrue%2C%22data%22%3A%22jZPtaoMwFIavJrD9KLhYL8CZMjZmN1TYz5Bq2goaJYktvful1tY0O9VBwcL7vOcr52yr5pjvmdQIexlBXmi%2Bt18S%2FqDgFWFs%2FlCyCj9XSUpJmIUoiMRTRCLDfKRf62eDoMB1p9nby8Wu9I5uq64sJGtlQ%2FNGaJZr9ciFQdemU6XgSnHY977Ohmyl0LRTXFKTozyU%2BvSIxyNfcFbNOQi58EVZ04JpDkPYgvqgMOaP2LlWEIqHhmrzPLcKi6bVZSNgA7YMlxFM4r6Fc7FjO15zoWF2abEVZwVtudw2smYihycRB5ZD8gMXHQwmQ5uHoxmr2m8aJguqutoY4YdI8Gj4x1QS%2F4bPzyRdh9%2FD%2BgnWXuMrzXSn%2Bq1PI3I%2BlVNrmvEwvPnnu8HeYoH81fUOZgAM3c5I9Ms9SZiFAu7oLgKQwybIjG42ALg4S3f9ru5W2Jdk6W6HxFYTN%2Fqd2r%2Fanwuz3G7u2K4scTPHeFL1J9XlnfoL%22%7D) |
| **Data Flow + Latency** | [Open in Draw.io](https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=%7B%22type%22%3A%22mermaid%22%2C%22compressed%22%3Atrue%2C%22data%22%3A%22bVFbboMwEDyNPyOlIA7Aq02UpEUQqeoXMmCCVcdLjd0ot%2B8aopIESyxGzM54NNMKuNQdVZp4631O1iGe%2F09Kgoh4XvrLpMXfmGSKataQIJavwvBGUfydKbBvQXUL6oz7JEiehHaT0I6239SS%2BwF02QOIXkHJZQVGjqLEj3H7BWdgtVOp8CcpPNEwlQ2Xp5kZ4Jy5dDOzG1PCpec9s6wNGCWuCEZU152TloefEw8%2FyiQqs%2FwjebTaoYiTmkTHidpUNr7IcNE83FrUHWuMYE72Icxv9PA93H8dt3GB91v%2BAesaxqXIGmQ9KP0Qg3dzZZc0aCrc9sJiM0cy8FNnXSZ06CqganRamGqFTQC2461%2FDFNXp1KKs1oRPx2rfq5%2BxrC0RZt3aLZsbEZtD8tmZtyGvYx%2Fxsc4HQnfKWAefw%3D%3D%22%7D) |

---

## System Architecture Overview

```
┌───────────────────────────────────────────────────────────────────────────────────┐
│                        SOURCE SYSTEMS                                        │
│  Kafka CDC (Fluidra Pro)  |  Salesforce  |  Oracle  |  PSOT Revenue          │
└─────────────────────────────────────────┬────────────────────────────────────────┘
                                            │
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
│                    S3 DATA LAKE (us-east-1)                                    │
│  s3://fluidra-data-lake/raw/fluidrapro/   (Kafka CDC JSON)                    │
│  s3://fluidra-data-lake/raw/salesforce/   (Batch CSV)                         │
│  s3://fluidra-data-lake/raw/oracle/        (Batch CSV)                        │
│  s3://fluidra-data-lake/raw/revenue/       (Batch CSV/Parquet)                │
└─────────────────────────────────────────┬────────────────────────────────────────┘
                                            │ S3 Event Notification
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
│              SNOWFLAKE INGESTION LAYER (WH_INGEST - X-SMALL)                   │
│  Snowpipe (PIPE_FLUIDRAPRO_CDC)  |  External Stages  |  File Formats         │
│  Streams (STRM_RAW_DEALERS_DATA) |  Hourly Batch     |  ON_ERROR=CONTINUE    │
└─────────────────────────────────────────┬────────────────────────────────────────┘
                                            │
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
│                RAW_DB (Landing Zone - Append Only)                             │
│  FLUIDRAPRO_RAW.RAW_DEALERS_DATA  (100 records, CDC JSON)                     │
│  SALESFORCE_RAW.*                 (placeholder tables)                        │
│  ORACLE_RAW.*                     (placeholder tables)                        │
│  REVENUE_RAW.*                    (placeholder tables)                        │
└─────────────────────────────────────────┬────────────────────────────────────────┘
                                            │ dbt source()
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
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
└─────────────────────────────────────────┬────────────────────────────────────────┘
                                            │
                                            ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
│              CONSUMPTION LAYER (WH_BI - MEDIUM / WH_ADHOC - SMALL)             │
│  Snowsight Dashboards  |  Product Manager  |  Executive  |  Sales Ops        │
│  Analyst Ad-hoc Queries (WH_ADHOC, 15 min timeout)                            │
└───────────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────────────────────┐
│                        GOVERNANCE_DB                                          │
│  AUDIT (access logs)  |  MONITORING (pipeline health)  |  DATA_QUALITY (dbt)  │
└───────────────────────────────────────────────────────────────────────────────────┘
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
