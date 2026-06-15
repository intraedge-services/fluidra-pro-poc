# Fluidra Pro POC

Production-ready Snowflake environment for analytics with dbt, processing dealer/contractor event data from the Fluidra Pro Platform.

## Project Overview

This project designs and implements a complete Snowflake data platform for Fluidra's Pro dealer management system. Data flows from the Pro Platform through Kafka into Snowflake, where dbt transforms raw events into analytics-ready datasets.

## Source Data: `DBT_AI_POC.PUBLIC.RAW_DEALERS_DATA`

### Table Structure

| Column | Type | Purpose |
|--------|------|---------|
| `RECORD_METADATA` | VARCHAR (JSON) | Kafka metadata — topic, partition, offset, key, create time |
| `RECORD_CONTENT` | VARCHAR (JSON) | Full event payload — the actual business data |
| `EVENT_TIME` | TIMESTAMP | When the event occurred |

### Data Characteristics

| Property | Value |
|----------|-------|
| **Records** | 100 |
| **Date Range** | June 9 – June 15, 2026 |
| **Kafka Topic** | `psot_poolpro_inbound` |
| **Environment** | test |
| **Region** | us-east-1 |

### Business Context

This is a **CDC (Change Data Capture) event stream** from Fluidra's Pro dealer platform. It captures real-time changes to dealers, contacts, locations, and business leads.

### Event Types

| Event Type | Count | Description |
|-----------|-------|-------------|
| `pro-business-master.updated` | 41 | Dealer/business profile updates |
| `pro-contact-master.updated` | 20 | Contact info changes |
| `pro-contact-master.created` | 17 | New contacts created |
| `pro-contact-master.login-created` | 13 | User logins provisioned |
| `pro-business-master.created` | 3 | New businesses onboarded |
| `pro-reconcile.completed` | 2 | Data reconciliation events |
| `pro-business-lead.approved` | 1 | Lead approval |
| `pro-location-master.updated` | 1 | Location update |
| `pro-business-master.approved` | 1 | Business approval |
| `pro-location-master.created` | 1 | New location created |

### Domains and Sub-Domains

| Domain | Sub-Domain | Service |
|--------|-----------|---------|
| fluidrapro | pro-business-master | pro-platform-core |
| fluidrapro | pro-contact-master | pro-platform-core |
| fluidrapro | pro-location-master | pro-platform-core |
| fluidrapro | pro-business-lead | salesforce |

### Source Systems

| Source | Records |
|--------|---------|
| pro-platform-core | 97 |
| reconciler | 2 |
| salesforce | 1 |

### Key Data Fields

**Contact Master**: `proContactId`, `firstName`, `lastName`, `email`, `phoneNumber`, `contactType` (CO-OWNER, TECHNICIAN, CSC), `loginStatus`, `status`, `cognitoSubId`, `username`

**Business Master**: Business profiles with audit info (createdBy, updatedBy, timestamps)

**Event Metadata**: `correlationId`, `domain`, `eventType`, `fieldsUpdated[]`, `payloadVersion`, `service`, `subDomain`

## Architecture Goals

- **Snowflake**: Multi-database architecture (RAW, STAGING, ANALYTICS, SANDBOX)
- **dbt**: Transform raw Kafka events into staging, intermediate, mart, and reporting models
- **RBAC**: Role hierarchy with least-privilege access
- **Reporting**: Power BI / Tableau / Snowsight consumption layer
- **Security**: Enterprise-grade with environment separation (DEV, TEST, PROD)

## Tech Stack

- **Cloud**: AWS (us-east-1)
- **Data Warehouse**: Snowflake
- **Transformation**: dbt Cloud
- **Streaming**: Kafka to Snowpipe
- **Source Systems**: Fluidra Pro Platform Core, Salesforce, Reconciler
- **Reporting**: Power BI / Tableau / Snowsight

## Status

In Progress — Designing production Snowflake environment with AIDLC methodology
