# Pro Business Master — Deep Study

## 1. Entity Overview

| Attribute | Value |
|-----------|-------|
| **Business Name** | Pro Business Master |
| **Technical Name** | `ProBusinessMaster` |
| **Aliases** | Pro Company Master, Dealer Company Master |
| **Description** | Represents the Fluidra Pro master business entity |
| **Parent Domain** | Logical Data Domains → Fluidra Pro |
| **System** | Pro Platform Core (AWS) |

---

## 2. Entity Relationships

### 2.1 Pro Business Location Master
- Every business will have **at least 2 locations**: Primary Billing and Primary Shipping.
- Every Pro Location is tied to **exactly one** business.

### 2.2 Self-Relation (Key Accounts)
- If a business is a **Primary Key Account**, it can be associated with 0 or more associate businesses.
- If a business is an **Associate Key Account**, it must be associated with a primary key account business.

### 2.3 Pro Rewards Account Master
- Every Pro business can have **at most one** Rewards Account.
- A business in Fluidra PRO might **not** be on the rewards program.

### 2.4 Pro Program Opt-In
- Every business can have **0 or more** program opt-ins.
- Every program opt-in must be associated with a Pro business.

### 2.5 Pro Associated Distributor
- Every business can have **one or more** associated distributors.
- Every distributor mapping must be associated with exactly one Pro Business.

### 2.6 Pro Contact Master
- Every business can have **one or more** contacts.
- At least one **Primary/Owner** contact must be present.

### 2.7 Pro Key Account Type
- Some businesses that are Key Accounts are associated to one Key Account Type.

---

## 3. Fields Definition

### 3.1 Core Identity Fields

| Field Name | Technical Name | Definition | Source of Truth | Required | Reconciliation |
|-----------|---------------|-----------|----------------|----------|----------------|
| Fluidra Pro Business Identifier | `proBusinessId` | Unique business identifier (UUID) for mastered Fluidra Pro business. Created when business is set up on Platform. | Pro Platform (AWS) | Either this or Account Number required | Platform |
| Fluidra Account Number | `fluidraAccountNumber` | Unique identifier assigned by ERP system and linked by admin back to the FPro account. Legacy field maintained for backward compatibility. | Oracle | Either this or Business ID required | Oracle |
| Business Name | `businessName` | Official name of the business | Current: Oracle, Future: Pro Platform (AWS) | Yes | Oracle (until M4), Platform (after M4) |
| Doing Business As (DBA) | `doingBusinessAs` | Legal designation allowing a business to operate under a trade name different from its registered legal name. Also used in store locator. | Future: Pro Platform (AWS) | No | Oracle (until M3), then Platform |

### 3.2 Status & Access Fields

| Field Name | Technical Name | Definition | Source of Truth | Required | Reconciliation |
|-----------|---------------|-----------|----------------|----------|----------------|
| Lead Source | `source` | Source responsible for dealer creation: ORACLE, SALESFORCE, PROWEB, OTHER. Default: PROWEB | Pro Platform (AWS) | No | Platform |
| Account Status | `status` | Status of the Fluidra Pro Business. Values: LEAD, GUEST, REJECTED, ACTIVE, CLOSED. Automatically set by Platform — cannot be changed directly in other systems. | Pro Platform (AWS) | Yes | Platform |
| Pro Login Allowed | `isProLoginAllowed` | Whether this Pro business is allowed to have login to fluidrapro.com. True (Default) / False (for some key accounts). Only changeable by sales rep or account admin. | Future: Pro Platform (AWS) | No | Platform |
| Pro Login Status | `loginStatus` | Login account status: ACTIVE, PENDING. (NOT ALLOWED status dropped 12/24/2025). | Future: Pro Platform (AWS) | Yes | Platform |
| Identity Organization Identifier | `identityOrgId` | Reference for Auth0 Org ID from Pro Identity Org. Added in M2. | Pro Platform (AWS) | Yes | Platform |

### 3.3 Account Status State Machine

```
Pending → LEAD
Active AND rewardsActivationStatus="Pending" → LEAD
Active AND rewardsActivationStatus="Activated" → ACTIVE
Pending Customer → ACTIVE
```

**Status Definitions:**
- **LEAD**: New business signed up for rewards or opted-in programs, pending approval.
- **GUEST**: New business that has not opted-in any rewards, operating as a guest to configure and setup equipment. No benefits from Fluidra PRO Program.
- **REJECTED**: Account request rejected by Sales rep.
- **ACTIVE**: Has any association with Fluidra.
- **CLOSED**: No longer doing business with Fluidra including rewards, subscriptions, etc.

### 3.4 Contact Fields

| Field Name | Technical Name | Definition | Source of Truth | Required | Reconciliation |
|-----------|---------------|-----------|----------------|----------|----------------|
| Primary Contact | `primaryContact` | Primary (Owner) contact for this business. For MVP, only mastering primary contact (Owner). | Future: Pro Platform (AWS) | Yes | Manual (owner email: Platform) |
| Primary Business Email | `primaryBusinessEmail` | Used to send e-statements and as locator address if Lead Management Email not defined for a location. | Current: Oracle, Future: Pro Platform (AWS) | Yes | Platform |
| Primary Business Phone Number | `primaryBusinessPhoneNumber` | Primary phone number for the business, in E.164 format. | Current: Oracle, Future: Pro Platform (AWS) | Yes | Oracle |

### 3.5 Location Fields

| Field Name | Technical Name | Definition | Source of Truth | Required | Reconciliation |
|-----------|---------------|-----------|----------------|----------|----------------|
| Primary Shipping Location | `primaryShippingLocation` | Address where primary mailing communications are sent, including rewards statements. Cannot be a PO Box. Also created as a location within Pro Business. | Current: Oracle, Future: Pro Platform (AWS) | Yes | Oracle (until M3) |
| Primary Billing Location | `primaryBillingLocation` | Used for redemptions, product orders and ClubP related tasks. | Current: Oracle, Future: Pro Platform (AWS) | Yes | Oracle |

### 3.6 Business Classification Fields

| Field Name | Technical Name | Definition | Source of Truth | Required | Reconciliation |
|-----------|---------------|-----------|----------------|----------|----------------|
| Primary Business Type | `primaryBusinessType` | Business primary segmentation (can only be 1): BUILDER, RETAILER, SERVICE, INTERNET, COMMERCIAL SERVICE, COMMERCIAL BUILDER | Current: Pro Web (Azure), Future: Pro Platform (AWS) | Yes | Platform |
| Secondary Business Types | `secondaryBusinessTypes` | Multiple secondary types: BUILDER, SERVICE, RETAILER, INTERNET, COMMERCIAL SERVICE, COMMERCIAL BUILDER | Current: Pro Web (Azure), Future: Pro Platform (AWS) | No | Platform |
| Customer Classification | `customerClass` | How we incentivize customers: AFTERMARKET, PIP MEMBER, INDIRECT DEALER, EMPLOYEE, DOMESTIC DISTRIBUTOR. Derived field. Cannot be set by dealer. | Future: Pro Platform (AWS) | Yes | Oracle (until M2) then Platform |
| Business Segment | `businessSegment` | Segment: BUILD, RETAIL, SERVICE, INTERNET. Derived from platform. | Future: Pro Platform (AWS) | Yes | Oracle (until M2) then Platform |
| Customer Type | `customerType` | POOL PRO, DISTRIBUTION, HOMEOWNER. For SOT, always POOL PRO. | Future: Pro Platform (AWS) | Yes | N/A |
| Sales Channel | `salesChannel` | Legacy field for how dealers purchase from Fluidra. Auto-derived based on Setup Rules. | Future: Pro Platform (AWS) | Yes | Oracle (until M2) then Platform |
| Channel | `channel` | New field: NEW CONSTRUCTION, AFTERMARKET. Auto-derived by Platform. | Future: Pro Platform (AWS) | No | Platform |

### 3.7 Key Account Fields

| Field Name | Technical Name | Definition | Source of Truth | Required | Reconciliation |
|-----------|---------------|-----------|----------------|----------|----------------|
| Key Account Type ID | `keyAccountTypeId` | Internal identifier for Key Account Type within Pro Platform. | Future: Pro Platform (AWS) | Yes | Platform |
| Key Account Type Name | `keyAccountTypeName` | Groups primary and affiliate accounts together. | Salesforce | No (Default N) | Platform |
| Key Account Type Role | `keyAccountTypeRole` | Roles: Standard, Restricted, Limited, Limited & Marketing Services. | Salesforce | No (Default N) | Platform |
| Primary Key Account? | `isPrimaryKeyAccount` | True = primary, False = not primary/affiliate. | Salesforce | No (Default N) | Platform |

### 3.8 Rewards & Programs Fields

| Field Name | Technical Name | Definition | Source of Truth | Required | Reconciliation |
|-----------|---------------|-----------|----------------|----------|----------------|
| Rewards Account | `rewardsAccount` | Master info for loyalty & rewards (Program Level, Region, Signup Date, Level Start/End Dates, Program Status, Enable Auto Zodiac Premium, Achiever Level/Dates). | Current: Loyalty 2.0, Future: Pro Platform (AWS) | Only if interested in Rewards | Oracle (except program start date) |
| Program Opt-Ins | `programOptIns` | All programs opted in: Rewards, TryMe, Polaris Days, Club-P, others. | Current: Pro Web (Azure), Future: Pro Platform (AWS) | Y only if opted in | Platform |
| E-Statement Enabled | `eStatementEnabled` | True (Default) / False. For key accounts, e-statement email set to rewards@fluidra.com. | Future: Pro Platform (AWS) | Yes | Platform |

### 3.9 Integration & External ID Fields

| Field Name | Technical Name | Definition | Source of Truth | Required | Reconciliation |
|-----------|---------------|-----------|----------------|----------|----------------|
| CRM Lead Identifier | `crmLeadId` | Lead ID within SalesForce. | SalesForce | No | Platform |
| CRM Account Identifier | `crmAccountId` | Account ID within Salesforce. | SalesForce | N initial, Y once lead created | Platform |
| Web Account Identifier | `webAccountId` | Account ID within Sitecore (Web). | Sitecore | N initial, Y once user created | Platform |
| Distributors | `distributors` | List of associated distributors. | Future: Pro Platform (AWS) | No | Platform |

### 3.10 Other Fields

| Field Name | Technical Name | Definition | Source of Truth | Required | Reconciliation |
|-----------|---------------|-----------|----------------|----------|----------------|
| Website | `website` | One website per business regardless of locations. | Pro AWS | No | Platform |
| Contract Service Center | `isCSC` | Whether any site offers warranty. | Future: Pro Platform (AWS) | No | Oracle (until M2) then Platform |
| Subscriptions | `subscriptions` | Dealer subscriptions. | Future: Pro Platform (AWS) | No | Platform |
| Marketing Consent | `isMarComConsent` | Required True to sign up. | Future: Pro Platform (AWS) | Yes | N/A |
| TSE Violator | `isTseViolator` | Trade agreement violator flag. | Future: Pro Platform (AWS) | No | Web |
| UTM Parameters | `utm` | Marketing tracking (5 params). Added M2. | Future: Pro Platform (AWS) | No | — |
| Sales Representative | `salesRep` | Person who created/approved lead. Added M2. | Salesforce/Pro Platform (AWS) | No | — |
| Audit Information | `auditInfo` | Audit trail for business. | Future: Pro Platform (AWS) | Yes | — |

---

## 4. Reconciliation Rules

### 4.1 Dual-Key Reconciliation
If a system (e.g., Oracle) provides **both** FPro Business ID and Customer Account Number:
1. Find the matching account from FPro Business ID.
2. Verify that Customer Account Number matches.
3. If mismatch → **park records for manual reconciliation**.

### 4.2 Source of Truth Transitions

| Field Category | Current SOT | Future SOT | Transition Milestone |
|---------------|-------------|-----------|---------------------|
| Business Name | Oracle | Pro Platform (AWS) | M4 |
| Doing Business As | Oracle | Pro Platform (AWS) | M3 |
| Account Status | Pro Platform (AWS) | Pro Platform (AWS) | Already |
| Primary Business Email | Oracle/Azure | Pro Platform (AWS) | M4/M2 |
| Shipping Location | Oracle | Pro Platform (AWS) | M3 |
| Billing Location | Oracle | Pro Platform (AWS) | M3 |
| Business Type/Segment | Pro Web (Azure) | Pro Platform (AWS) | M2 |
| Customer Class | Oracle | Pro Platform (AWS) | M2 |
| Sales Channel | Oracle | Pro Platform (AWS) | M2 |

---

## 5. Key Accounts Deep Dive

### 5.1 Overview
Key accounts like Leslie, Pinch a Penny — private equity purchase dealers and franchisee models handled differently than independent professionals.

### 5.2 Classification Rules

| Scenario | Key Account Type | Primary Key Account Flag |
|----------|-----------------|------------------------|
| **Primary Key Account** | Name of group | Y |
| **Affiliate Key Account** | Name of group | N |
| **Not a Key Account** | Not Set | N or Not Set |

### 5.3 Key Account Roles
- **Standard** — Full permissions
- **Restricted** — Limited access
- **Limited** — More restricted
- **Limited & Marketing Services** — Limited with marketing capabilities

### 5.4 Exceptions
- Some key accounts tracked as sites within parent account (no Oracle account per site).
- Other key accounts: every associate has their own ERP Account (ZP#).

---

## 6. Cross-System Column Mappings

| Field | Event Name | Pro AWS | Oracle | Pro Azure |
|-------|-----------|---------|--------|-----------|
| Fluidra Business ID | `fluidraBusinessId` | `businessID` | NEW | — |
| DBA | `doingBusinessAs` | `doingBusinessAs` | NEW | — |
| Account Number | `fluidraAccountNumber` | `customerNumber` / `accountNumber` | `HZ_PARTIES.ACCOUNT_NUMBER` | Club P Number |
| Business Name | `businessName` | `businessName` | `HZ_PARTIES.PARTY_NAME` | — |
| Primary Email | `primaryBusinessEmail` | `ownerEmail` | — | — |
| Primary Phone | `primaryBusinessPhoneNumber` | — | — | — |

---

## 7. Integration Notes

### 7.1 SalesForce
- When a lead is added directly in SalesForce, `proBusinessId` won't be available immediately — synchronized later by Platform.
- Leads for existing accounts in SalesForce/Oracle use ORACLE as lead source.

### 7.2 Oracle Technical Mapping
- Table: `hz_cust_accounts_all`
- Key columns: `attribute8` (businessID), `account_number`, `attribute13` (status), `attribute3` (business type), `sales_channel_code`, `customer_class_code`

### 7.3 Platform Events
- Business creation triggers `Pro Business Master Created Event` via EventBus.
- Sales Rep field added in M2 for email confirmation of lead approval/business creation.

---

## 8. Data Quality Constraints

| Constraint | Rule |
|-----------|------|
| UUID Format | `proBusinessId` must be valid UUID |
| Phone Format | E.164 format required |
| Email for Key Accounts | e-statement email defaults to `rewards@fluidra.com` — not primary business email |
| Status Immutability | Set automatically by Platform — no direct changes from other systems |
| Single Primary Type | Only ONE primary business type allowed |
| Multiple Secondary Types | Multiple secondary types allowed |
| Derived Fields | `customerClass`, `salesChannel`, `channel`, `businessSegment` — auto-derived, not user-settable |

---

## 9. Milestone Roadmap

| Milestone | Fields Migrating to Platform |
|-----------|----------------------------|
| **M2** | Sales Channel, Customer Class, Business Segment, Key Account fields, Sales Rep, UTM, Identity Org ID, CSC |
| **M3** | Primary Shipping Location, DBA, Billing Location |
| **M4** | Business Name, Primary Business Email, E-Statement |
| **Post-MVP** | Account Number generation, Warranty type at Site level, Contacts as independent entities |

---

## 10. Implications for Snowflake/dbt Data Platform

### 10.1 Staging
- Ingest events from Pro Platform (AWS) EventBus as primary source
- Maintain Oracle feed for legacy fields during transition
- Handle dual-key reconciliation logic
- Track SOT transitions per field per milestone

### 10.2 Data Modeling
- **Hub**: `pro_business_master` (keyed on `proBusinessId`)
- **Satellites**: Status history, Location history, Classification history, Key Account history, Rewards history
- **Links**: Business→Location, Business→Contact, Business→Distributor, Business→KeyAccountType
- **Derived fields**: Replicate platform derivation logic for Customer Class, Sales Channel, Channel, Business Segment

### 10.3 Reconciliation Layer
- Dual-key matching (`proBusinessId` + `fluidraAccountNumber`)
- Park unmatched records for manual review
- Track reconciliation source per field
- Full audit trail with timestamps
