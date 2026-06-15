# Fluidra Pro Analytics Platform - Architecture

## Components
1. Platform Foundation (Snowflake roles, DBs, warehouses, grants)
2. Ingestion Layer (Snowpipe, external stages, raw tables)
3. Transformation Layer (dbt Cloud - staging, intermediate, dims, facts, marts)
4. Reporting Layer (Snowsight views with RAG status)
5. Governance (data quality, audit, monitoring)
6. CI/CD (dbt Cloud jobs - DEV/TEST/PROD)

## Data Flow
Kafka CDC → S3 → Snowpipe → RAW_DB → dbt Staging → Intermediate → Dims/Facts → Marts → Reporting Views → Snowsight

## KPIs (20 total)
- Dealer Adoption: 5 KPIs
- User Adoption: 7 KPIs
- Engagement: 2 KPIs
- Lead Performance: 4 KPIs
- Revenue: 2 KPIs