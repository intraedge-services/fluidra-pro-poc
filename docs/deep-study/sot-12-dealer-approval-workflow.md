# SOT-12: Dealer Approval Workflow — Deep Analysis

## Overview

This document analyzes the **SOT-12: Dealer Approval Workflow (Dealer)** — a BPMN process diagram that orchestrates the end-to-end flow of a new dealer signing up on the Fluidra Pro platform, from initial registration through approval to account activation.

---

## Swim Lanes (Participants)

The workflow spans **5 swim lanes** representing different system actors:

| Lane | Actor | Role |
|------|-------|------|
| 1 | **Pro Web Application** | Dealer-facing frontend for signup and login |
| 2 | **Pro Platform (AWS)** | Backend orchestration, master data management, event processing |
| 3 | **Salesforce (CRM)** | Lead management, sales rep approval workflow |
| 4 | **Oracle ERP** | Account setup, ERP record creation |
| 5 | **Rewards / Loyalty** | Rewards account setup and loyalty program configuration |

---

## Workflow Phases

### Phase 1: Dealer Registration (Pro Web Application)

1. **Dealer visits Pro Sign-up** — Entry point
2. **Existing Account Check** — System checks if dealer already has login credentials
   - If **Yes**: Redirect to existing login (Existing Account Found)
   - If **No**: Continue to new registration
3. **Online entry / Company setup** — Dealer enters basic company information
4. **Existing Pool Company?** — Gateway to check if this is a known business
   - Validates against existing records
5. **Generate OTP** — One-Time Password sent for email verification
6. **System OTP** — OTP validation step
7. **Verify OTP** — Dealer enters and verifies the OTP code
8. **Wait Gate** — Holds until OTP verification completes
9. **Capture Business and Contact Information** — Full business details collected
10. **Complete Signup Process** — Finalize registration data

### Phase 2: Platform Processing (Pro Platform AWS)

1. **Pro Business Master Updated / Created** — Master record created in platform
2. **Pro Contact Master Updated / Created** — Contact record established
3. **Pro Contact Login Created Event** — Login credentials provisioned
4. **Verification Code (OTP)** — Platform generates verification code
5. **Generate Pro Signup Token** — Security token for signup session
6. **Register Pro Business** — Business formally registered in system
7. **Pro Business Master / Pro Contact Master Created Event** — Domain events emitted

### Phase 3: M2 Enhancement — Sales Rep Approval

> Marked with "M2" label indicating this was added in Milestone 2

1. **Pro Business Lead Created Event** — Event triggers approval flow
2. **Wait already approved?** — Check if auto-approval applies
   - If **Yes**: Skip to approved flow
   - If **No**: Route to manual approval
3. **Determine Pro Business Status** — Evaluate lead status
4. **Is Dealer Approved?** — Decision gateway
   - If **Yes**: Continue to account creation
   - If **No**: Route to rejection
5. **Pro Business Master Approved Event** — Approval event emitted
6. **Pro Business Master Created Event** — Final creation event
7. **Notify Opus Ops (Email Service Center)** — Notification to operations team
8. **Pro Business Master Created Event / Pro Contact Master Created Event** — Events for downstream processing

### Phase 4: CRM Processing (Salesforce)

1. **Send Lead to CRM** — Lead record pushed to Salesforce
   - Includes: *all inputs for rewards*
2. **Complete Signup Process** — CRM-side signup completion
3. **Pro Lead Added to Salesforce** — Confirmation of lead creation
4. **Approve / Reject Lead** — Sales rep decision point
5. **Queue Step** — Queued for rep review

### Phase 5: Post-Approval — Account Setup

1. **OTP Verification Process** — Additional verification after approval
2. **Setup Login for Business** — Create login credentials
3. **Enable CMS Login** — Enable content management access
4. **Update Gift Permissions** — Set gift/reward permissions
5. **24 Hours Timer** — Wait period before login activation
6. **Email Login Credentials** — Send credentials to dealer
7. **Login Process (Welcome)** — Dealer can now login
8. **Pro Business Master Active Event (Finally)** — Business fully activated

### Phase 6: Welcome & Onboarding

1. **Pro Business Master Added Event** — Triggers welcome sequence
2. **Dealer - Welcome Email** — Welcome communication sent
3. **Dealer - Rewards Program Welcome Email** — Rewards-specific welcome
4. **Email Instructions for Account / Rewards Team** — Internal team notified
5. **Admin / Rewards Business Admin Portal** — Admin access configured
6. **Add Location / Website to Locator** — Business added to store locator

### Phase 7: Oracle ERP Setup

1. **Account Team** initiates setup
2. **Setup Account** — ERP account created
3. **Setup ERP Account** — Financial account configured
4. **Setup Loyalty (2.0 Enable)** — Loyalty system enabled
5. **Rewards Team** — Final rewards configuration

---

## Key Decision Gateways

| Gateway | Type | Condition | Yes Path | No Path |
|---------|------|-----------|----------|----------|
| Existing Account? | Exclusive | Has login credentials | Redirect to login | Continue signup |
| Existing Pool Company? | Exclusive | Known business | Link to existing | Create new |
| OTP Valid? | Exclusive | Code matches | Proceed | Retry/Fail |
| Already Approved? (M2) | Exclusive | Auto-approval rules | Skip manual | Route to rep |
| Is Dealer Approved? | Exclusive | Sales rep decision | Create account | Reject |

---

## Events & Messages

| Event | Type | Trigger | Consumer |
|-------|------|---------|----------|
| Pro Business Master Created Event | Domain Event | Business registration | Platform, CRM, Oracle |
| Pro Contact Master Created Event | Domain Event | Contact creation | Platform, Login service |
| Pro Contact Login Created Event | Domain Event | Login provisioned | Email service |
| Pro Business Lead Created Event | Domain Event | Lead submitted | Salesforce, Approval flow |
| Pro Business Master Approved Event | Domain Event | Sales rep approves | Account setup, Oracle |
| Pro Business Master Active Event | Domain Event | Full activation | Welcome emails, Locator |

---

## Timers & Waits

| Timer | Duration | Purpose |
|-------|----------|----------|
| OTP Wait | ~5 min | Wait for dealer to enter verification code |
| 24 Hours Timer | 24h | Delay between approval and login credential delivery |
| Queue Step | Variable | Sales rep review queue time |

---

## M2 Enhancements (Highlighted in Diagram)

The "M2" boxed section introduced:
- **Sales Rep approval workflow** — Previously auto-approved, now requires human review
- **Lead Created Event** — New event for CRM integration
- **Approval/Rejection branching** — Formal decision point
- **Ops notification** — Email to operations on business creation
- **Email instructions for Account/Rewards team** — Internal team coordination

---

## Integration Touchpoints

```
┌──────────┐     Event      ┌──────────────┐     Lead      ┌────────────┐
│ Pro Web  │ ──────────────> │ Pro Platform │ ───────────> │ Salesforce │
│ (Dealer) │                │    (AWS)     │              │   (CRM)    │
└──────────┘                └──────┬───────┘              └─────┬──────┘
                                   │                            │
                                   │ Events                     │ Approve/
                                   ▼                            │ Reject
                            ┌──────────────┐                    │
                            │  Oracle ERP  │ <──────────────────┘
                            │  (Account)   │
                            └──────┬───────┘
                                   │
                                   ▼
                            ┌──────────────┐
                            │  Loyalty 2.0 │
                            │  (Rewards)   │
                            └──────────────┘
```

---

## Implications for Data Platform

1. **Event sourcing opportunity** — All state transitions emit domain events that can be captured for analytics
2. **Lead-to-Account funnel** — Track conversion rates from signup → approval → activation
3. **Time-to-activation metrics** — Measure from signup to first login (includes 24h timer)
4. **Rejection analytics** — Track rejection reasons and rates by sales rep
5. **M2 impact measurement** — Compare auto-approval (pre-M2) vs manual approval performance
