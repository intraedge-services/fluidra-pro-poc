# Pro Business Master — Analysis

## Executive Summary

The Pro Business Master entity is the central master data record for all Fluidra Pro businesses (dealers, contractors, retailers). It serves as the single source of truth for business identity, classification, and relationships across multiple systems (AWS Platform, Oracle ERP, Salesforce CRM, Sitecore Web, Azure legacy).

---

## Key Findings

### 1. Multi-System Complexity

The entity spans **5+ systems** with varying ownership per field:
- **Pro Platform (AWS)** — Primary/future SOT for most fields
- **Oracle ERP** — Legacy SOT for financial and location fields
- **Salesforce CRM** — Lead management and key account data
- **Pro Web (Azure)** — Legacy business type and program data
- **Sitecore** — Web account identity
- **Loyalty 2.0** — Rewards program data

### 2. Source of Truth Migration is In-Progress

Fields are migrating from Oracle/Azure → AWS Platform across milestones:
- **M2** (earliest): Classification fields (Customer Class, Sales Channel, Business Segment)
- **M3**: Location and DBA fields
- **M4** (latest): Core identity fields (Business Name, Email)

**Risk**: During transition, reconciliation logic must handle dual-source scenarios where both old and new SOT may emit conflicting values.

### 3. Reconciliation is Critical

The dual-key reconciliation pattern (`proBusinessId` + `fluidraAccountNumber`) is the primary mechanism for matching records across systems. Failure to match results in manual intervention — this could become a bottleneck at scale.

### 4. Derived Fields Create Hidden Dependencies

Several important fields are **auto-derived** by the platform:
- `customerClass` — derived from program membership
- `salesChannel` — derived from setup rules
- `channel` — derived from business type
- `businessSegment` — derived from business type

These cannot be set by dealers or sales reps, creating a dependency on platform logic being correctly replicated in downstream analytics.

### 5. Key Accounts Add Structural Complexity

The self-referential relationship (Primary ↔ Affiliate) and role-based permissions (Standard, Restricted, Limited, Limited & Marketing Services) create a hierarchical business model that needs special handling in data modeling.

---

## Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|-----------|-----------|
| Token/field SOT mismatch during migration | Data inconsistency | High (during M2-M4) | Implement field-level SOT tracking with timestamp |
| Reconciliation queue overflow | Manual bottleneck | Medium | Automated matching rules + alerting |
| Derived field logic drift | Analytics mismatch | Medium | Replicate platform rules in dbt with tests |
| Key account hierarchy data quality | Incorrect permissions | Low | Validation rules on isPrimaryKeyAccount + keyAccountType |
| Legacy Oracle feed discontinuation | Data loss | Low (post-M4) | Gradual cutover with parallel running |

---

## Recommendations for Data Platform

### Immediate (M2)
1. **Implement dual-source ingestion** — EventBus (AWS) + Oracle feed in parallel
2. **Build reconciliation staging layer** — Match on `proBusinessId`, validate with `fluidraAccountNumber`
3. **Create SOT registry table** — Track which field comes from which source per milestone
4. **Replicate derived field logic** — dbt models for `customerClass`, `salesChannel`, `channel`, `businessSegment`

### Short-term (M3)
5. **Migrate location fields** — Switch shipping/billing SOT from Oracle to Platform
6. **DBA field handling** — Note: stored in Address Line 1 in Oracle (non-obvious mapping)
7. **Key account hierarchy model** — Build parent-child relationships with role propagation

### Medium-term (M4+)
8. **Complete Oracle cutover** — Business Name, Email become Platform-sourced
9. **Deprecate Azure feed** — Business type/program data fully from Platform
10. **Independent contact model** — Contacts exist on own, associated to multiple businesses

---

## Data Model Recommendations

### Entity Relationship Summary

```
┌─────────────────────┐
│  Pro Business Master │
│  (Hub: proBusinessId)│
├─────────────────────┤
│ businessName         │
│ fluidraAccountNumber │
│ status               │
│ primaryBusinessType  │
│ customerClass        │
│ salesChannel         │
└──────────┬──────────┘
           │
    ┌──────┼──────────────────────┐
    │      │                      │
    ▼      ▼                      ▼
┌────────┐ ┌──────────────┐  ┌─────────────┐
│Location│ │Contact Master│  │Key Account  │
│(1:N)   │ │(1:N, min 1)  │  │Type (0:1)   │
└────────┘ └──────────────┘  └─────────────┘
    │                              │
    ▼                              ▼
┌────────────┐              ┌─────────────┐
│Distributor │              │Self-Relation│
│(0:N)       │              │Primary↔Affil│
└────────────┘              └─────────────┘
```

### Satellite Tables (History Tracking)

| Satellite | Key Fields Tracked |
|-----------|-------------------|
| `sat_business_status` | status, loginStatus, isProLoginAllowed |
| `sat_business_classification` | primaryBusinessType, secondaryTypes, customerClass, salesChannel, channel, businessSegment |
| `sat_business_identity` | businessName, doingBusinessAs, primaryBusinessEmail, primaryBusinessPhoneNumber |
| `sat_business_location` | primaryShippingLocation, primaryBillingLocation |
| `sat_business_key_account` | keyAccountTypeId, keyAccountTypeName, keyAccountTypeRole, isPrimaryKeyAccount |
| `sat_business_rewards` | rewardsAccount (all sub-fields), programOptIns |

---

## Open Questions

1. How will the platform handle conflicts when Oracle and Platform disagree during transition?
2. What is the SLA for `proBusinessId` sync to SalesForce after lead creation?
3. Will derived fields (`customerClass`, etc.) be available in real-time events or only after batch processing?
4. How are key account role changes propagated to affiliate businesses?
5. What happens to historical Oracle data after full Platform cutover?
