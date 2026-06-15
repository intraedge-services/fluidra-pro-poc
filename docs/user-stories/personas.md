# User Personas

## P1: Product Manager (Sarah)

| Attribute | Value |
|-----------|-------|
| **Role** | Product Manager — Fluidra Pro Platform |
| **Goal** | Monitor platform adoption, identify growth opportunities, track KPI targets |
| **Pain Points** | Scattered data across systems, no unified view of program health |
| **Interaction** | Daily Snowsight dashboard review, weekly stakeholder reports |
| **Key Metrics** | Active Dealers, Active Users, Stickiness Ratios, First Login Rate |
| **Access Level** | Read access to all marts and reporting views |

## P2: Sales Operations Manager (Mike)

| Attribute | Value |
|-----------|-------|
| **Role** | Sales Operations Manager |
| **Goal** | Track lead conversion funnel, identify bottlenecks, optimize approval process |
| **Pain Points** | High lead rejection rate (~70%), no visibility into approval timelines |
| **Interaction** | Daily lead funnel review, regional performance drill-downs |
| **Key Metrics** | Lead Rejection Rate, Time to Approve, Rewards Activation Time, Revenue per Dealer |
| **Access Level** | Read access to lead and revenue marts |

## P3: Marketing Manager (Lisa)

| Attribute | Value |
|-----------|-------|
| **Role** | Marketing Manager — Dealer Acquisition |
| **Goal** | Measure dealer acquisition campaigns, track new enrollments, assess onboarding |
| **Pain Points** | Cannot measure campaign effectiveness, no visibility into onboarding funnel |
| **Interaction** | Weekly campaign review, monthly enrollment reports |
| **Key Metrics** | New Dealer Accounts, Guest-to-Lead Conversion, Enrollment Rate |
| **Access Level** | Read access to dealer adoption and lead marts |

## P4: Executive Leader (David)

| Attribute | Value |
|-----------|-------|
| **Role** | VP of Dealer Programs |
| **Goal** | High-level program health assessment, revenue impact, target vs actual |
| **Pain Points** | No single dashboard for program ROI, manual report assembly |
| **Interaction** | Weekly executive summary, monthly board-level metrics |
| **Key Metrics** | Revenue Growth, Active Dealers, YoY comparisons, target variance |
| **Access Level** | Read access to summary reporting views |

## P5: Data Analyst (Priya)

| Attribute | Value |
|-----------|-------|
| **Role** | Business Intelligence Analyst |
| **Goal** | Ad-hoc analysis, custom reports, segment deep-dives |
| **Pain Points** | Raw data is JSON, no clean dimensional model to query |
| **Interaction** | Daily querying, building custom Snowsight dashboards |
| **Key Metrics** | All KPIs — needs drill-down to raw data level |
| **Access Level** | Read access to all layers (staging through reporting), ANALYST_ROLE |

## P6: Data Engineer (Raj)

| Attribute | Value |
|-----------|-------|
| **Role** | Data Platform Engineer |
| **Goal** | Build and maintain ingestion pipelines, dbt models, data quality |
| **Pain Points** | Manual pipeline management, no CI/CD, no data quality monitoring |
| **Interaction** | Daily pipeline monitoring, weekly model updates |
| **Key Metrics** | Pipeline freshness, data quality scores, model run times |
| **Access Level** | Full access to RAW/STAGING/ANALYTICS/GOVERNANCE databases, DATA_ENGINEER_ROLE |
