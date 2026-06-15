# CI/CD Setup Guide — dbt Cloud + GitHub

## Overview

The Fluidra Pro Analytics Platform uses **dbt Cloud** for managed orchestration with a **DEV → TEST → PROD** promotion workflow. Code lives in GitHub and dbt Cloud auto-deploys on merge.

---

## Environment Architecture

| Environment | Database Pattern | Warehouse | dbt Target | Trigger |
|-------------|-----------------|-----------|------------|---------|
| **DEV** | *_DB_DEV | WH_DBT_DEV | `dev` | On commit (IDE/manual) |
| **TEST** | *_DB_TEST | WH_DBT_TEST | `test` | On PR merge to `main` |
| **PROD** | *_DB_PROD | WH_DBT_PROD | `prod` | Scheduled hourly |

---

## Step 1: Connect GitHub Repository

1. Open [dbt Cloud](https://cloud.getdbt.com) → **Account Settings** → **Integrations** → **GitHub**
2. Authorize the `intraedge-services` GitHub organization
3. In your dbt Cloud project (DBT_AI_POC):
   - **Settings** → **Repository** → Select `intraedge-services/fluidra-pro-poc`
   - **Project sub-directory**: `dbt`
   - **Default branch**: `main`

---

## Step 2: Configure Snowflake Connection

In dbt Cloud project → **Settings** → **Connection**:

| Field | Value |
|-------|-------|
| Connection Type | Snowflake |
| Account | `hvypinm-ywb61747` |
| Authentication | Password (or Key Pair for production) |
| Role | (set per environment in credentials) |
| Warehouse | (set per environment in credentials) |
| Database | (set per environment in credentials) |
| Threads | 4 |

---

## Step 3: Create Environments

### Development Environment

| Setting | Value |
|---------|-------|
| Name | Development |
| Type | Development |
| dbt Version | Latest |
| Custom branch | (any feature branch) |

**Developer Credentials** (each developer sets their own):
| Field | Value |
|-------|-------|
| User | SATHYANATHANB (or personal user) |
| Role | DBT_DEV_ROLE |
| Warehouse | WH_DBT_DEV |
| Database | RAW_DB_DEV |
| Schema | STAGING |
| Target Name | dev |

### Production Environment

| Setting | Value |
|---------|-------|
| Name | Production |
| Type | Deployment |
| dbt Version | Latest |
| Branch | `main` |

**Deployment Credentials**:
| Field | Value |
|-------|-------|
| User | SVC_DBT_PROD |
| Auth | Key Pair (RSA) |
| Role | DBT_PROD_ROLE |
| Warehouse | WH_DBT_PROD |
| Database | RAW_DB_PROD |
| Schema | STAGING |
| Target Name | prod |

---

## Step 4: Set Environment Variables

In dbt Cloud → **Environments** → **Environment Variables**:

| Variable | DEV | TEST | PROD | Purpose |
|----------|-----|------|------|----------|
| `DBT_RAW_DATABASE` | RAW_DB_DEV | RAW_DB_TEST | RAW_DB_PROD | Source database for staging models |

---

## Step 5: Create Jobs

### Job 1: CI Build (Development Validation)

| Setting | Value |
|---------|-------|
| Name | CI Build |
| Environment | Development |
| Trigger | On Pull Request |
| Commands | `dbt build --select state:modified+` |
| Compare against | Previous production artifacts |
| Generate docs | Yes |

**Purpose**: Validates only modified models compile and pass tests (Slim CI).

### Job 2: Production Build (Hourly)

| Setting | Value |
|---------|-------|
| Name | Production Build |
| Environment | Production |
| Trigger | Schedule - Every hour at :00 |
| Commands | |
| | `dbt deps` |
| | `dbt build` |
| | `dbt docs generate` |
| Thread count | 4 |

**Purpose**: Full production refresh of all models hourly.

### Job 3: Production Full Refresh (Manual)

| Setting | Value |
|---------|-------|
| Name | Full Refresh |
| Environment | Production |
| Trigger | Manual only |
| Commands | |
| | `dbt deps` |
| | `dbt build --full-refresh` |
| | `dbt snapshot` |
| | `dbt docs generate` |

**Purpose**: Complete rebuild when schema changes or backfill needed.

### Job 4: Snapshot (Daily)

| Setting | Value |
|---------|-------|
| Name | Daily Snapshots |
| Environment | Production |
| Trigger | Schedule - Daily at 02:00 UTC |
| Commands | `dbt snapshot` |

**Purpose**: Capture SCD Type 2 changes (dealer status history).

---

## Step 6: Configure Notifications

In dbt Cloud → **Account Settings** → **Notifications**:

| Event | Channel | Recipients |
|-------|---------|------------|
| Job Failure (Production) | Email / Slack | Data Engineering team |
| Source Freshness Warning | Email | Data Engineering team |
| Test Failures | Email | Data Engineering + Analysts |

---

## Step 7: Generate RSA Key Pair (for Service Accounts)

```bash
# Generate private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out snowflake_dbt_prod.p8 -nocrypt

# Extract public key
openssl rsa -in snowflake_dbt_prod.p8 -pubout -out snowflake_dbt_prod.pub

# Set public key on Snowflake user (run in Snowsight)
# ALTER USER SVC_DBT_PROD SET RSA_PUBLIC_KEY = '<contents of .pub file without header/footer>';

# Upload private key to dbt Cloud connection settings
```

Repeat for SVC_DBT_DEV and SVC_DBT_TEST.

---

## Deployment Workflow

```
 Developer pushes code to feature branch
              │
              ▼
   Create Pull Request to `main`
              │
              ▼
   dbt Cloud CI Build triggers (Slim CI)
   - Builds only modified models
   - Runs tests on changes
   - Reports pass/fail on PR
              │
              ▼ (if pass + PR approved)
   Merge to `main`
              │
              ▼
   Production Build triggers (hourly schedule)
   - Full `dbt build` in PROD
   - Generates documentation
   - Results visible in dbt Cloud UI
              │
              ▼
   Data available in Snowsight dashboards
```

---

## Monitoring & Troubleshooting

### Check Job Status
- dbt Cloud UI → **Jobs** → View run history
- Each run shows: status, duration, models run, tests passed/failed

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| `Database does not exist` | Wrong target/profile | Check env vars match environment |
| `Insufficient privileges` | Missing grants | Run `05_grants.sql` for the target env |
| `Warehouse suspended` | Auto-suspend working | Warehouse auto-resumes on next query |
| `Source freshness ERROR` | No new data in 6+ hours | Check Snowpipe status, S3 landing |
| `Test failure` | Data quality issue | Check test output, investigate source data |

### Useful dbt Commands (local debugging)

```bash
# Check connection
dbt debug

# Compile without executing
dbt compile

# Run specific model
dbt run --select mart_dealer_adoption

# Run tests only
dbt test

# Check source freshness
dbt source freshness

# Generate docs locally
dbt docs generate && dbt docs serve
```

---

## Repository Structure

```
intraedge-services/fluidra-pro-poc/
├── dbt/                          ← dbt Cloud project root (sub-directory)
│   ├── dbt_project.yml
│   ├── packages.yml
│   ├── models/
│   │   ├── staging/fluidrapro/    ← Parse raw JSON, DQ checks
│   │   ├── intermediate/          ← Business logic
│   │   ├── dimensions/            ← Conformed dims (SCD2)
│   │   ├── marts/                 ← KPI calculations
│   │   └── reporting/             ← Dashboard views
│   ├── macros/                    ← Reusable SQL (RAG, variance)
│   ├── tests/                     ← Custom data tests
│   ├── snapshots/                 ← SCD Type 2
│   └── seeds/                     ← Reference data (targets)
├── snowflake/                     ← Infrastructure DDL (01-13)
└── docs/                          ← Architecture, analysis, issues
```

---

## Cost Optimization

| Control | Setting | Impact |
|---------|---------|--------|
| Auto-suspend | 60s all warehouses | No idle compute charges |
| Right-sizing | X-SMALL to MEDIUM per workload | Match cost to demand |
| Resource monitors | 100 credits/month cap | Prevent bill shock |
| Slim CI | Only build modified models on PRs | Reduce CI compute |
| Hourly (not real-time) | Batch processing | Lower Snowpipe/compute cost |
| Statement timeout | 15 min on WH_ADHOC | Prevent runaway queries |
