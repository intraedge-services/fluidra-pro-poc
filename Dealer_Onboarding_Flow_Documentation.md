# Dealer Onboarding Flow — Complete System Documentation

> **Source References:**
> - [SOT-12: Create Dealer Automation (Part 1)](https://zodiacpoolsystems.atlassian.net/wiki/spaces/FPAS/pages/3205988353)
> - [SOT-63/SOT-62: Sales Rep Lead / Key Account Creation Workflow (Part-2)](https://zodiacpoolsystems.atlassian.net/wiki/spaces/FPAS/pages/3505651921)

---

## 1. Executive Summary

The Dealer Onboarding system automates the end-to-end process of creating dealer accounts across multiple connected systems. It is divided into two major parts:

| Part | Scope | Jira |
|------|-------|------|
| **Part 1** | Web Lead Signup → Salesforce Approval → Oracle Account Creation Automation | SOT-12 |
| **Part 2** | Sales Rep Lead Creation (in Salesforce) + Key Account Type Sync | SOT-63, SOT-62 |

---

## 2. Connected Systems Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                            DEALER ONBOARDING ECOSYSTEM                               │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                     │
│  ┌──────────────┐    ┌──────────────┐    ┌────────────────┐    ┌───────────────┐   │
│  │  Fluidra Pro │    │  Salesforce  │    │  AWS Platform  │    │    Oracle     │   │
│  │    Web App   │    │     CRM      │    │   (EventBus)   │    │     ERP      │   │
│  └──────┬───────┘    └──────┬───────┘    └───────┬────────┘    └───────┬───────┘   │
│         │                   │                    │                     │            │
│  ┌──────┴───────┐    ┌──────┴───────┐    ┌───────┴────────┐    ┌───────┴───────┐   │
│  │  Fluidra Pro │    │  Snowflake/  │    │   Notification │    │  Loyalty 2.0  │   │
│  │   Mobile     │    │  Informatica │    │    Service     │    │   (Rewards)   │   │
│  └──────────────┘    └──────────────┘    └────────────────┘    └───────────────┘   │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### System Responsibilities

| System | Role in Onboarding |
|--------|-------------------|
| **Fluidra Pro Web** | Dealer self-service signup form; Guest Business dashboard; Rewards activation |
| **Fluidra Pro Mobile** | Mobile access for dealers |
| **Salesforce CRM** | Lead management; Sales rep lead entry; Lead approval/denial; Key Account type assignment |
| **AWS Platform (EventBus)** | Event routing (EventBridge); Automation orchestration (Step Functions); File exchange (S3/SFTP) |
| **Oracle ERP** | Dealer account creation; Account number assignment (ZP number); Feed-based integration |
| **Loyalty 2.0 (Rewards)** | Rewards program enrollment; Customer number activation |
| **Snowflake / Informatica** | Oracle sync; Salesforce-to-Oracle account linking |
| **Notification Service** | Email notifications to dealers and internal teams |
| **ION Pool Care** | Kept in sync during account creation |

---

## 3. Part 1 — Web Lead Signup & Automated Oracle Account Creation (SOT-12)

### 3.1 Flow Overview

```
┌────────┐     ┌────────────┐     ┌────────────┐     ┌─────────────┐     ┌────────┐
│ Dealer │────▶│ FPro Web   │────▶│ Salesforce │────▶│ AWS Platform│────▶│ Oracle │
│ Signup │     │ Lead Form  │     │ Approval   │     │ Automation  │     │  ERP   │
└────────┘     └────────────┘     └────────────┘     └─────────────┘     └────────┘
                                                            │
                                                            ▼
                                                     ┌─────────────┐
                                                     │ Loyalty 2.0 │
                                                     │  + Rewards  │
                                                     └─────────────┘
```

### 3.2 Detailed Step-by-Step Flow

#### Phase A: Dealer Signup (Web → Salesforce)

```
Step 1: Dealer fills out signup form on Fluidra Pro Web
        ├── Email verification integrated
        ├── Business information collected
        └── Pro Business Master record created (status: PENDING)

Step 2: Lead submitted to Salesforce
        ├── Lead includes FPro ID (Pro Business ID)
        ├── Lead available for Sales Rep review/editing
        └── Salesforce emits "Lead Created" event to EventBridge
```

#### Phase B: Lead Approval (Salesforce → EventBridge)

```
Step 3: Sales Rep reviews lead in Salesforce
        ├── Can edit business fields (name, address, contacts)
        └── Salesforce emits update events for field changes → EventBridge → FPro Platform

Step 4: Sales Rep approves or denies the lead
        ├── IF APPROVED → Salesforce emits "Lead Approved" event
        │   └── EventBridge routes event as "Pro Business Master Approved Event"
        └── IF DENIED → Lead status updated in FPro Platform; notification sent to dealer
```

#### Phase C: Oracle Account Creation Automation (EventBus → Oracle)

```
Step 5: Pro Business Master Approved Event captured
        ├── EventBridge rule → Firehose → S3 (batched, 200 events/file)
        └── Data includes: Business Master, Primary Contact, Bill-To, Ship-To,
            Rewards Master, Associated Distributor Master

Step 6: Automation Step Function executes (every 2 hours)
        ├── Step 6.1: Event Aggregation
        │   ├── List S3 files using bookmark (metadata timestamp)
        │   ├── Identify new files since last successful run
        │   └── Output: S3 locations of new event files
        │
        ├── Step 6.2: Apply Automation Rules (Lambda)
        │   ├── Read raw event files from S3
        │   ├── Validate against contract rules
        │   ├── Deduplicate by proBusinessId (keep latest)
        │   ├── Transform to flat JSONL structure
        │   └── Write staging file: erp/automation/staging/{runId}.jsonl
        │
        └── Step 6.3: Feed Generation & SFTP Put (Lambda)
            ├── Read JSONL staging file
            ├── Convert JSONL → CSV (Oracle format)
            ├── Write CSV to SFTP Bucket: erp/automation/inbound/date={dd-mm-yyyy}/{timestamp}.csv
            └── Update bookmark on success
```

#### Phase D: Oracle Processing & Response

```
Step 7: Oracle reads inbound feeds from SFTP
        └── Creates new dealer account in Oracle ERP

Step 8: Oracle sends response feeds to SFTP outbound path
        ├── Success file: erp/automation/outbound/{timestamp}_success.csv
        └── Error file: erp/automation/outbound/{timestamp}_error.csv
```

#### Phase E: Response Processing (EventBus)

```
Step 9: S3 PutObject event triggers Default EventBridge Bus

Step 10: Response Processor handles responses
         │
         ├── SUCCESS PATH:
         │   ├── Parse success CSV → extract proBusinessId + fluidraAccountNumber pairs
         │   ├── Publish "ERP Account Created Event" to Central EventBridge
         │   ├── Archive to success/{runId}/
         │   └── Trigger downstream flows (Steps 11-14)
         │
         ├── RETRYABLE ERROR PATH:
         │   ├── Append failed records to staging area (next run)
         │   └── Archive to error/{runId}/
         │
         └── NON-RETRYABLE ERROR PATH:
             ├── Publish SNS → Email SRE + Oracle Team
             └── Archive to error/{runId}/
```

#### Phase F: Downstream Processing (Pro Platform, Notifications, Web)

```
Step 11: Pro Platform receives "ERP Account Created Event"
         ├── Notify AU/Rewards about Account Creation
         └── Updates Business Master with fluidraAccountNumber

Step 12: Rewards Activation (FEATURE FLAGGED)
         ├── Update Rewards system with Customer Number
         └── Set programStatus to "ACTIVE"

Step 13: Pro Platform publishes "Pro Business Master Updated Event"
         └── Includes fluidraAccountNumber in fieldsUpdated

Step 14: Notifications sent
         ├── "Account creation is happening" — when automation flow begins
         └── "Account creation is complete" — when Oracle confirms account

Step 15: Web activation
         └── Dealer can activate Rewards on FPro Account
```

---

## 4. Part 2 — Sales Rep Lead Creation & Key Account Workflow (SOT-63 / SOT-62)

### 4.1 Sales Rep Lead Creation (SOT-63)

This eliminates the need for dealers to go through the Fluidra Pro web signup. Sales reps can directly create leads in Salesforce.

```
┌────────────┐     ┌────────────┐     ┌─────────────┐     ┌──────────────┐
│  Sales Rep │────▶│ Salesforce │────▶│  EventBridge │────▶│ FPro Platform│
│  (in SF)   │     │ Lead Form  │     │     Bus      │     │  (Account)   │
└────────────┘     └────────────┘     └─────────────┘     └──────────────┘
                                             │                     │
                                             ▼                     ▼
                                      ┌─────────────┐      ┌─────────────┐
                                      │   Oracle    │      │  Salesforce │
                                      │   (Manual)  │      │ (FPro ID)   │
                                      └─────────────┘      └─────────────┘
```

#### Detailed Steps

```
Step 1: Sales Rep creates lead directly in Salesforce
        ├── Business information entered
        ├── Contact information entered
        └── Lead submitted for approval

Step 2: Lead approved in Salesforce
        └── Salesforce emits "Lead Approved" event to EventBridge

Step 3: EventBridge routes to FPro Platform
        ├── FPro creates Pro Business Master record
        ├── FPro generates Pro Business ID (FPro ID)
        └── FPro ID sent back to Salesforce (updates the approved lead)

Step 4: Oracle Account Creation (MANUAL in Part 2)
        ├── Email generated to Oracle Admin with business logic-derived values
        ├── Oracle Admin creates account in Oracle + Loyalty 2.0
        └── Note: This email template has same format whether lead comes from web or sales rep

Step 5: Salesforce Account Linking
        ├── Once Oracle account created → synced via Snowflake → Informatica
        ├── Salesforce account created (from Oracle sync)
        └── Existing leads (with matching FPro ID) converted and linked to Salesforce account

Step 6: Dealer Notification
        └── Welcome email sent to dealer with credentials setup CTA
```

### 4.2 Key Account Type Workflow (SOT-62)

Key accounts are dealers associated with buying groups or franchise networks. They get personalized views based on their key account type.

```
┌────────────┐     ┌────────────┐     ┌─────────────┐     ┌──────────────┐
│ Salesforce │────▶│ EventBridge│────▶│ FPro Platform│────▶│  FPro Web    │
│ Key Acct   │     │    Bus     │     │ (Business    │     │ (Personalized│
│ Type Assign│     │            │     │   Master)    │     │    Views)    │
└────────────┘     └────────────┘     └─────────────┘     └──────────────┘
```

#### Key Account Types and Roles

| Key Account Type | Role | Access Level |
|-----------------|------|--------------|
| Restricted | Minimal | Basic FPro access |
| Limited + Marketing Services | Limited | Marketing materials access |
| Limited + Marketing Services & Opt Ins | Limited+ | Marketing + opt-in features |
| Standard | Full | Full FPro platform access |

#### Key Account Sync Flow

```
Step 1: Key Account Type assigned in Salesforce
        ├── For web leads (during approval)
        └── For sales rep-added leads

Step 2: Key Account Type event published to EventBridge
        └── Event contains accountId + keyAccountType

Step 3: FPro Platform receives event
        ├── Updates Business Master with Key Account Type field
        └── Assigns role-based permissions

Step 4: Oracle Integration (Future: M2/M3)
        ├── M2: Oracle Admin manually adds Key Account Type
        └── M3: Automated Oracle account creation with Key Account Type auto-populated

Step 5: FPro Web displays personalized view
        ├── Permissions driven by Key Account Type (not Sitecore)
        └── Each Key Account Type maps to a specific role/view

Step 6: Existing Business Migration
        └── Existing FPro businesses updated with Key Account Type from Salesforce
```

---

## 5. Complete End-to-End System Integration Diagram

```
╔═══════════════════════════════════════════════════════════════════════════════════════════╗
║                          COMPLETE DEALER ONBOARDING ARCHITECTURE                         ║
╠═══════════════════════════════════════════════════════════════════════════════════════════╣
║                                                                                          ║
║  ┌─────────────────────────────────────── ENTRY POINTS ──────────────────────────────┐   ║
║  │                                                                                   │   ║
║  │  ┌──────────────────┐          ┌──────────────────────────────────┐               │   ║
║  │  │  FPro Web Signup │          │  Salesforce (Sales Rep Direct)   │               │   ║
║  │  │  (Self-service)  │          │  Lead Creation                   │               │   ║
║  │  └────────┬─────────┘          └──────────────┬───────────────────┘               │   ║
║  │           │                                   │                                   │   ║
║  └───────────┼───────────────────────────────────┼───────────────────────────────────┘   ║
║              │                                   │                                       ║
║              ▼                                   ▼                                       ║
║  ┌───────────────────────────────────── SALESFORCE CRM ──────────────────────────────┐   ║
║  │                                                                                   │   ║
║  │  • Lead Management & Approval        • Key Account Type Assignment                │   ║
║  │  • Sales Rep Editing                 • Lead-to-Account Conversion                 │   ║
║  │  • Event Emission to EventBridge     • Salesforce Epic: NAMSO-1434 / NAMSO-1437   │   ║
║  │                                                                                   │   ║
║  └───────────────────────────────────────────┬───────────────────────────────────────┘   ║
║                                              │                                           ║
║                    Events: Lead Created, Lead Approved, Key Account Type Assigned         ║
║                                              │                                           ║
║                                              ▼                                           ║
║  ┌─────────────────────────── AWS PLATFORM (CENTRAL EVENTBRIDGE) ────────────────────┐   ║
║  │                                                                                   │   ║
║  │  ┌─────────────────┐  ┌──────────────────────────┐  ┌────────────────────────┐   │   ║
║  │  │   EventBridge   │  │  Firehose → S3 (Batching)│  │  EventBridge Rules     │   │   ║
║  │  │   Central Bus   │─▶│  200 events/file         │  │  (Routing & Filtering) │   │   ║
║  │  │   ("pro" bus)   │  │                          │  │                        │   │   ║
║  │  └────────┬────────┘  └──────────┬───────────────┘  └────────────────────────┘   │   ║
║  │           │                      │                                                │   ║
║  │           │                      ▼                                                │   ║
║  │  ┌────────┴────────────────────────────────────────────────────────────────────┐  │   ║
║  │  │              AUTOMATION STEP FUNCTION (Cron: every 2 hours)                  │  │   ║
║  │  │                                                                              │  │   ║
║  │  │  ┌─────────────────┐   ┌───────────────────┐   ┌─────────────────────────┐  │  │   ║
║  │  │  │ Event Aggregation│──▶│ Automation Rules  │──▶│ Feed Generation + SFTP  │  │  │   ║
║  │  │  │ (S3 Bookmark)   │   │ (Validate/Dedup/  │   │ (JSONL→CSV, Put to SFTP)│  │  │   ║
║  │  │  │                 │   │  Transform)       │   │                         │  │  │   ║
║  │  │  └─────────────────┘   └───────────────────┘   └─────────────────────────┘  │  │   ║
║  │  │                                                                              │  │   ║
║  │  └──────────────────────────────────────────────────────────────────────────────┘  │   ║
║  │                                                                                   │   ║
║  │  ┌────────────────────────────────────────────────────────────────────────────┐   │   ║
║  │  │            RESPONSE PROCESSOR (S3 Event Triggered)                          │   │   ║
║  │  │                                                                            │   │   ║
║  │  │  Success → Publish ERP Account Created Event                               │   │   ║
║  │  │  Retryable Error → Re-queue for next run                                   │   │   ║
║  │  │  Non-Retryable Error → SNS → Email SRE + Oracle Team                      │   │   ║
║  │  └────────────────────────────────────────────────────────────────────────────┘   │   ║
║  │                                                                                   │   ║
║  │  ┌─────────────────┐  ┌──────────────────────┐  ┌────────────────────────────┐   │   ║
║  │  │  Notification   │  │   Pro Platform Core   │  │    S3 Buckets              │   │   ║
║  │  │  Service        │  │   (Business Master    │  │  • Automation Bucket       │   │   ║
║  │  │  (Email)        │  │    Management)        │  │  • SFTP Bucket             │   │   ║
║  │  └─────────────────┘  └──────────────────────┘  └────────────────────────────┘   │   ║
║  │                                                                                   │   ║
║  └───────────────────────────────────────────────────────────────────────────────────┘   ║
║                                              │                                           ║
║              ┌───────────────────────────────┼───────────────────────────────┐           ║
║              ▼                               ▼                               ▼           ║
║  ┌──────────────────────┐   ┌──────────────────────────┐   ┌───────────────────────┐    ║
║  │     ORACLE ERP       │   │     LOYALTY 2.0          │   │  SNOWFLAKE /          │    ║
║  │                      │   │     (Rewards)            │   │  INFORMATICA          │    ║
║  │  • Read inbound CSV  │   │                          │   │                       │    ║
║  │  • Create account    │   │  • Customer enrollment   │   │  • Oracle → SF sync   │    ║
║  │  • Assign ZP number  │   │  • Program activation    │   │  • Account linking    │    ║
║  │  • Send response CSV │   │  • Feature-flagged       │   │  • Lead conversion    │    ║
║  │                      │   │                          │   │                       │    ║
║  └──────────────────────┘   └──────────────────────────┘   └───────────────────────┘    ║
║                                                                                          ║
║              ┌───────────────────────── OUTPUT ──────────────────────────────┐           ║
║              │                                                               │           ║
║              │  ┌──────────────────┐    ┌──────────────────────────────┐     │           ║
║              │  │   FPro Web       │    │   Dealer Email Notifications │     │           ║
║              │  │  • Rewards       │    │  • "Account creation in      │     │           ║
║              │  │    activation    │    │     progress"                 │     │           ║
║              │  │  • Personalized  │    │  • "Account creation          │     │           ║
║              │  │    views (Key    │    │     complete"                 │     │           ║
║              │  │    Account Type) │    │  • Welcome + credentials CTA │     │           ║
║              │  └──────────────────┘    └──────────────────────────────┘     │           ║
║              │                                                               │           ║
║              └───────────────────────────────────────────────────────────────┘           ║
║                                                                                          ║
╚══════════════════════════════════════════════════════════════════════════════════════════╝
```

---

## 6. Event Flow Summary

### Events Published to Central EventBridge

| Event | Source | Detail Type | Trigger |
|-------|--------|------------|---------|
| Pro Business Master Approved | pro-platform-core | fluidrapro.pro-business-master.approved.v1 | Lead approved in SF |
| ERP Account Created | platform-eventbus-automation | fluidrapro.erp-account.created.v1 | Oracle response success |
| Pro Business Master Updated | pro-platform-core | fluidrapro.pro-business-master.updated.v1 | Account number assigned |
| Key Account Type Updated | pro-platform-core | (TBD) | SF Key Account Type change |

### Event Data Payloads

**Pro Business Master Approved Event includes:**
- Business Master (businessName, primaryBusinessType, customerClass, customerType)
- Primary Contact
- Primary Bill-To address
- Primary Ship-To address
- Rewards Master
- Associated Distributor Master

**ERP Account Created Event includes:**
- Array of: { proBusinessId (UUID), fluidraAccountNumber (string) }
- Standard metadata (domain, subDomain, eventType, version, correlationId)

---

## 7. S3 Bucket Structure

### Automation S3 Bucket
```
erp/automation/
├── config/           ← Automation configuration & rules
├── staging/          ← JSONL files awaiting CSV generation
│   └── {runId}.jsonl
├── runID/            ← Run tracking metadata
├── success/{runId}/  ← Archived success response files
└── error/{runId}/    ← Archived error response files
```

### SFTP S3 Bucket
```
erp/automation/
├── inbound/                          ← Outbound TO Oracle
│   └── date={dd-mm-yyyy}/
│       └── {file-timestamp}.csv
└── outbound/                         ← Inbound FROM Oracle
    └── date={dd-mm-yyyy}/
        ├── {timestamp}_success.csv
        └── {timestamp}_error.csv
```

---

## 8. Key Technical Details

### Infrastructure (AWS CDK)
- **Step Function**: Cron-triggered (2 hours), 3-step pipeline
- **Firehose**: 128MB buffer / 1 second interval, GZIP JSON output
- **EventBridge Rules**: Pattern matching on detail-type and source
- **S3 Event Notifications**: PutObject triggers for response processing
- **SNS**: Error notification to SRE/Oracle team via email
- **Lambda Functions**: Event aggregation, rules, feed generation, response processing

### Integration Patterns
| Pattern | Usage |
|---------|-------|
| Event-Driven (EventBridge) | Real-time event routing between services |
| Batch Processing (Step Function) | Aggregation and CSV generation every 2 hours |
| File-Based Integration (SFTP/S3) | Oracle CSV feed exchange |
| Feature Flags | Rewards activation toggle |
| Bookmark Pattern | Idempotent event aggregation |

### Error Handling Strategy
| Error Type | Handling |
|------------|----------|
| Retryable (Oracle) | Re-queued to staging for next automation run |
| Non-retryable (Oracle) | SNS notification to SRE + Oracle team |
| Validation failure | Record rejected, classified as error |
| Duplicate event | Deduplicated by proBusinessId (keep latest) |

---

## 9. Milestone Roadmap

| Milestone | Scope | Oracle Account Creation |
|-----------|-------|------------------------|
| **Part 1 (SOT-12)** | Web lead signup, SF approval, automated Oracle feed | Automated via CSV feeds |
| **Part 2 M1 (SOT-63)** | Sales rep lead in SF, FPro account, SF lead linking | Manual (email to Oracle Admin) |
| **Part 2 M2 (SOT-62)** | Key Account Type in Oracle (manual add by AU) | Manual + Key Account Type field |
| **Part 2 M3 (Future)** | Full automation with Key Account Type | Fully automated, Key Account auto-populated |

---

## 10. Cross-Team Dependencies

| Team | System | Responsibility |
|------|--------|---------------|
| Platform Engineering | AWS EventBus, Step Functions, Lambdas | Automation pipeline, event routing |
| Pro Platform | FPro Core API | Business Master management, Rewards |
| Salesforce Team | Salesforce CRM | Lead management, event emission (NAMSO-1434, NAMSO-1437) |
| Web Team | FPro Web | Signup form, rewards activation, personalized views (FWT-3593) |
| Oracle/AU Team | Oracle ERP | Account creation, response feeds |
| Data Engineering | Snowflake / Informatica | Oracle-to-Salesforce sync |
| SRE | Monitoring | Alert handling for non-retryable errors |

---

*Document generated from Confluence pages and local architecture diagrams. Last updated: June 2026*
