# Fluidra Pro Business — Complete Business Overview

## 1. What is Fluidra Pro?

Fluidra Pro is a B2B platform operated by **Fluidra** (a global leader in pool & wellness equipment) that serves **pool professionals** — builders, service technicians, retailers, and commercial contractors. The platform manages dealer relationships, rewards programs, product ordering, and business operations across multiple systems.

---

## 2. Business Model

### 2.1 How Fluidra Operates

Fluidra manufactures and distributes pool/wellness equipment (pumps, filters, heaters, automation, chemicals) and sells through a **dealer network** rather than direct-to-consumer.

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐     ┌────────────┐
│  Fluidra    │────>│  Distributors    │────>│  Dealers (Pro)  │────>│  Homeowner │
│ (Mfg/Brand) │     │ (Wholesale)      │     │ (Install/Sell)  │     │ (End User) │
└─────────────┘     └──────────────────┘     └─────────────────┘     └────────────┘
      │                                              │
      │         Direct (some key accounts)           │
      └──────────────────────────────────────────────┘
```

### 2.2 Revenue Flow

1. **Fluidra** manufactures products (Jandy, Polaris, Zodiac, iAquaLink brands)
2. **Distributors** buy wholesale and stock inventory regionally
3. **Dealers** (pool pros) purchase from distributors and install/service for homeowners
4. **Fluidra Pro Platform** incentivizes dealers via rewards programs to prefer Fluidra products

### 2.3 Why the Platform Exists

- **Loyalty & Retention**: Keep dealers purchasing Fluidra products over competitors
- **Rewards Programs**: Points, rebates, tier-based benefits (ProEdge, Retail Select, etc.)
- **Digital Services**: Equipment configurators, warranty registration, store locator
- **Sales Intelligence**: Track dealer performance, regional trends, market share

---

## 3. Dealer Types & Classification

### 3.1 Primary Business Types

Every dealer has exactly ONE primary type:

| Type | Description | Example |
|------|-------------|----------|
| **BUILDER** | New construction pool builders | Custom pool companies |
| **SERVICE** | Pool maintenance & repair technicians | Weekly service companies |
| **RETAILER** | Pool supply retail stores | Leslie's Pool Supplies |
| **INTERNET** | Online-only pool equipment sellers | e-commerce pool stores |
| **COMMERCIAL SERVICE** | Commercial pool/spa facility maintenance | Hotel/resort pool service |
| **COMMERCIAL BUILDER** | Commercial pool construction | Water parks, municipal pools |

### 3.2 Secondary Business Types

A dealer can have MULTIPLE secondary types. Example: A builder who also does service work would have:
- Primary: BUILDER
- Secondary: SERVICE

### 3.3 Customer Classification (How Fluidra Incentivizes)

| Class | Description | Program |
|-------|-------------|----------|
| **PIP MEMBER** | Premium incentive program dealers | ProEdge rewards tier |
| **AFTERMARKET** | Service/replacement market dealers | ServicePro program |
| **INDIRECT DEALER** | Buys through distributors (standard) | Base rewards |
| **EMPLOYEE** | Fluidra internal accounts | Internal pricing |
| **DOMESTIC DISTRIBUTOR** | Wholesale distribution partners | Distributor pricing |

### 3.4 Sales Channels

How dealers purchase from Fluidra:

| Channel | Description |
|---------|-------------|
| **PIP MEMBER** | ProEdge program (premium) |
| **Retail Select** | Selected retail partners |
| **Retail Select Star** | Top retail performers |
| **Base Rewards** | Standard rewards program |
| **INDIRECT** | ServicePro dealers |
| **DIRECT** | Direct purchase from Fluidra |
| **DD/AQT** | Direct dealer / AquaTech |
| **DD/CAR** | Direct dealer / Caretaker |
| **DD/MPG** | Direct dealer / MPG |
| **PIP/PAP** | PIP / Pro Advantage Program |
| **CARETAKER DIRECT** | Caretaker brand direct |

### 3.5 Business Segments (Channel Derivation)

| Primary Business Type | Derived Channel |
|----------------------|----------------|
| BUILDER | NEW CONSTRUCTION |
| RETAILER, SERVICE, INTERNET | AFTERMARKET |

---

## 4. Key Accounts

### 4.1 What Are Key Accounts?

Key accounts are large dealer organizations (franchise chains, private equity groups) that get special treatment:

- **Leslie's Pool Supplies** — Largest pool retail chain
- **Pinch a Penny** — Franchise pool supply stores
- **Other PE groups** — Private equity-owned dealer networks

### 4.2 Key Account Structure

```
┌─────────────────────────────────┐
│  Key Account Type               │
│  (e.g., "Pinch a Penny")        │
├─────────────────────────────────┤
│  Role: Standard | Restricted |  │
│        Limited | Ltd+Marketing  │
└───────────────┬─────────────────┘
                │
     ┌──────────┼──────────────┐
     │          │              │
     ▼          ▼              ▼
┌─────────┐ ┌─────────┐  ┌─────────┐
│Primary  │ │Affiliate│  │Affiliate│
│Account  │ │Account  │  │Account  │
│(Parent) │ │(Store 1)│  │(Store 2)│
└─────────┘ └─────────┘  └─────────┘
```

### 4.3 Key Account Roles & Permissions

| Role | Permissions | Example Use |
|------|------------|-------------|
| **Standard** | Full access to all features | Independent large dealers |
| **Restricted** | Limited access, no pricing changes | Franchise locations |
| **Limited** | View-only for most features | Associate stores |
| **Limited & Marketing Services** | Limited + marketing tools | Stores running local campaigns |

### 4.4 Key Account Behaviors

- Primary account manages settings for all affiliates
- Pro Login may be disabled for affiliates (`isProLoginAllowed = false`)
- E-statement emails default to `rewards@fluidra.com` (not individual emails)
- Some key accounts tracked as sites within parent (no separate Oracle/ERP account)
- Others: every affiliate gets their own ERP Account (ZP#)

---

## 5. Dealer Lifecycle Workflows

### 5.1 New Dealer Registration (SOT-12)

```
Dealer Sign-up → Email Verification (OTP) → Business Info Capture
     │
     ▼
Platform Creates Pro Business Master (status: LEAD)
     │
     ▼
Lead Sent to Salesforce CRM
     │
     ▼
Sales Rep Reviews (Approve / Reject)  ← M2 Enhancement
     │
     ├── APPROVED → Account Setup → Oracle ERP → Loyalty Setup → ACTIVE
     │
     └── REJECTED → Notification → status: REJECTED
```

**Timeline**: Sign-up to Active ≈ 1-3 business days (includes 24hr timer + rep review)

### 5.2 Account Status Lifecycle

```
         ┌──────────┐
         │  SIGNUP  │ (Not yet in system)
         └────┬─────┘
              │ Registration complete
              ▼
         ┌──────────┐
         │   LEAD   │ Pending approval
         └────┬─────┘
              │
    ┌─────────┼─────────┐
    │         │         │
    ▼         ▼         ▼
┌────────┐ ┌────────┐ ┌──────────┐
│ ACTIVE │ │REJECTED│ │  GUEST   │
│        │ │        │ │(no rewards)│
└───┬────┘ └────────┘ └──────────┘
    │
    ▼
┌────────┐
│ CLOSED │ No longer with Fluidra
└────────┘
```

### 5.3 Lead Sources

| Source | Description | Default? |
|--------|-------------|----------|
| **PROWEB** | Dealer signs up on fluidrapro.com (web or via sales rep link) | Yes (default) |
| **ORACLE** | Existing dealer imported from Oracle ERP | No |
| **SALESFORCE** | Lead created/updated directly in Salesforce CRM | No |
| **OTHER** | Any other channel | No |

### 5.4 Login Provisioning

```
Approval → Auth0 Org Created (identityOrgId) → Credentials Generated
     │
     ▼
24hr Timer → Email Credentials to Dealer
     │
     ▼
Dealer First Login → Login Status: ACTIVE
```

**Login Status Values:**
- **PENDING** — Account approved but dealer hasn't logged in yet
- **ACTIVE** — Dealer has active login and uses the platform

---

## 6. Rewards & Loyalty Programs

### 6.1 Program Structure

```
┌─────────────────────────────────────────┐
│          Fluidra Pro Rewards            │
├─────────────────────────────────────────┤
│  ProEdge (Top Tier)                     │
│    → PIP MEMBER classification          │
│    → Highest rebates & benefits         │
├─────────────────────────────────────────┤
│  Retail Select / Retail Select Star     │
│    → Retail-focused program             │
│    → Store locator visibility           │
├─────────────────────────────────────────┤
│  Base Rewards                           │
│    → Entry-level program                │
│    → Standard benefits                  │
├─────────────────────────────────────────┤
│  ServicePro (INDIRECT)                  │
│    → AFTERMARKET classification         │
│    → Service-focused benefits           │
└─────────────────────────────────────────┘
```

### 6.2 Rewards Account Fields

| Field | Description |
|-------|-------------|
| Program Level | ProEdge, Retail Select, Base Rewards, etc. |
| Region | WEST, EAST, CENTRAL |
| Program Signup Date | When dealer joined the program |
| Program Level Start Date | When current tier started |
| Program Level End Date | When current tier expires |
| Program Status | ACTIVE, PENDING, CANCELLED |
| Achiever Level | Gold, Silver, Bronze (performance tier) |
| Enable Auto Zodiac Premium | Auto-enrollment in Zodiac premium |

### 6.3 Program Opt-Ins

Dealers can opt into multiple programs simultaneously:

| Program | Description |
|---------|-------------|
| **Rewards** | Core loyalty/rebate program |
| **TryMe** | Product trial program |
| **Polaris Days** | Polaris brand promotional events |
| **Club-P** | Premium club membership |
| **Others** | Seasonal/promotional programs |

### 6.4 E-Statements

- Monthly rewards statements sent to `primaryBusinessEmail`
- Key accounts receive statements at `rewards@fluidra.com` (centralized)
- Can be enabled/disabled per business (`eStatementEnabled`)

---

## 7. Distributor Relationships

### 7.1 How Distribution Works

- Each dealer purchases from **1-5 distributors** (regional wholesale partners)
- Distributors stock Fluidra products and fulfill dealer orders
- Fluidra tracks which distributors serve which dealers for:
  - Sales attribution
  - Regional coverage analysis
  - Rebate calculations

### 7.2 Data Model

```
Pro Business Master
  └── distributors[] (1 to 5)
        ├── Distributor Name 1
        ├── Distributor Name 2
        ├── Distributor Name 3
        ├── Distributor Name 4
        └── Distributor Name 5
```

---

## 8. Locations & Addresses

### 8.1 Location Types

Every business has at minimum 2 locations:

| Location | Purpose | Can be PO Box? |
|----------|---------|----------------|
| **Primary Shipping** | Where products are shipped, where mailing goes | No |
| **Primary Billing** | Invoicing, redemptions, ClubP orders | Yes |
| **Secondary Shipping** | Additional ship-to addresses | Yes |
| **Service Locations** | Where dealer operates (store locator) | No |

### 8.2 Store Locator

- Business appears on fluidrapro.com dealer locator
- Uses `doingBusinessAs` (DBA) name if set, otherwise `businessName`
- Location can be hidden (`hideLocation`, `hideAddress` flags)
- Each location has: address, phone, email, website, service zip codes

---

## 9. System Landscape

### 9.1 Current Systems

```
┌────────────────────────────────────────────────────────────────┐
│                    FLUIDRA PRO ECOSYSTEM                        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ fluidrapro   │  │  Admin       │  │  Store       │         │
│  │ .com (Web)   │  │  Portal      │  │  Locator     │  FRONT  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  END    │
│         │                 │                 │                  │
├─────────┼─────────────────┼─────────────────┼──────────────────┤
│         ▼                 ▼                 ▼                  │
│  ┌─────────────────────────────────────────────────┐           │
│  │         Pro Platform (AWS)                      │           │
│  │  • Business Master    • Contact Master          │  CORE     │
│  │  • Location Master    • Rewards Master          │  PLATFORM │
│  │  • EventBus (CDC)     • Auth0 (Identity)        │           │
│  └────────────────────────┬────────────────────────┘           │
│                           │                                    │
├───────────────────────────┼────────────────────────────────────┤
│                           ▼                                    │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │Salesforce│  │  Oracle ERP  │  │ Loyalty 2.0  │  BACKEND    │
│  │  (CRM)   │  │  (Finance)   │  │  (Rewards)   │  SYSTEMS   │
│  └──────────┘  └──────────────┘  └──────────────┘             │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│                           ▼                                    │
│  ┌─────────────────────────────────────────────────┐           │
│  │         Data Platform (Snowflake + dbt)         │  ANALYTICS│
│  │  • Raw (S3 → Snowpipe)  • Staging (dbt views)  │           │
│  │  • Analytics (dims/facts) • Reporting (marts)   │           │
│  └─────────────────────────────────────────────────┘           │
└────────────────────────────────────────────────────────────────┘
```

### 9.2 Data Flow

1. **Dealer actions** on fluidrapro.com trigger API calls to Pro Platform
2. **Pro Platform** persists master data and emits domain events via EventBus
3. **EventBus → Kafka → S3** delivers CDC events as JSON files
4. **Snowpipe** auto-ingests into `RAW_DEALERS_DATA` table
5. **dbt staging models** parse JSON, deduplicate, type-cast
6. **dbt analytics models** build dimensions, facts, and marts
7. **Salesforce** receives leads for sales rep workflow
8. **Oracle ERP** creates financial accounts post-approval
9. **Loyalty 2.0** manages rewards calculations

---

## 10. Business Metrics & KPIs

### 10.1 Key Metrics Tracked

| Metric | Description | Source |
|--------|-------------|--------|
| Active Dealers | Count of status=ACTIVE businesses | Platform |
| Lead Conversion Rate | LEAD → ACTIVE / Total Leads | Platform + SF |
| Time to Activation | Days from signup to first login | Platform |
| Rejection Rate | REJECTED / Total Leads | Salesforce |
| Program Enrollment | % of active dealers in rewards | Platform |
| Achiever Level Distribution | Gold/Silver/Bronze breakdown | Loyalty |
| Revenue per Dealer | Annual purchase volume | Oracle/Revenue |
| Distributor Coverage | Dealers per distributor | Platform |
| Key Account Share | % of revenue from key accounts | Oracle |
| Store Locator Visibility | Dealers visible on locator | Platform |

### 10.2 Segmentation for Analytics

| Dimension | Values | Use Case |
|-----------|--------|----------|
| Business Type | BUILDER, SERVICE, RETAILER, etc. | Market segment analysis |
| Region | WEST, EAST, CENTRAL | Geographic performance |
| Program Level | ProEdge, Retail Select, Base | Tier performance |
| Customer Class | PIP MEMBER, AFTERMARKET, etc. | Incentive effectiveness |
| Key Account vs Independent | Y/N | Revenue concentration |
| Lead Source | PROWEB, ORACLE, SALESFORCE | Channel effectiveness |

---

## 11. Compliance & Controls

### 11.1 TSE (Trade Agreement) Enforcement

- Dealers who violate trade agreements are flagged (`isTseViolator = true`)
- Flagged by admin via Admin Portal
- Affects dealer benefits and program eligibility

### 11.2 Marketing Consent

- All dealers must consent to marketing communications at signup (`isMarComConsent = true`)
- Required to join the platform — cannot opt out and remain active

### 11.3 Data Ownership

- **Status field**: Only Platform can change (immutable from other systems)
- **Derived fields**: Auto-calculated, not settable by dealers or sales reps
- **Login access**: Only changeable by sales rep or account admin (not dealer)
- **Key account flags**: Managed centrally, not by individual dealers

---

## 12. Summary

Fluidra Pro is essentially a **dealer relationship management platform** that:

1. **Onboards** pool professionals through a multi-step approval workflow
2. **Classifies** them by type, segment, and sales channel
3. **Incentivizes** through tiered rewards programs (ProEdge, Retail Select, etc.)
4. **Manages** key accounts with hierarchical parent-affiliate structures
5. **Tracks** business performance across distributors and regions
6. **Integrates** across 5+ systems (Platform, CRM, ERP, Loyalty, Web)
7. **Migrates** source-of-truth from legacy (Oracle/Azure) to modern (AWS Platform)

The data platform (Snowflake + dbt) serves as the analytics backbone — ingesting events from all systems, reconciling records across sources, and powering business intelligence for the Fluidra Pro team.
