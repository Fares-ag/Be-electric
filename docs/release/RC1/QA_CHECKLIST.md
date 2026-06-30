# RC1 — Cross-Platform Manual QA Checklist

Run on **staging** before production. Mark Pass / Fail / N/A.

---

## Authentication

| # | Workflow | React | Flutter R | Flutter T | Pass |
|---|----------|-------|-----------|-----------|------|
| A1 | Login valid user | ☐ | ☐ | ☐ | |
| A2 | Deactivated user rejected | ☐ | ☐ | ☐ | |
| A3 | Profile id = auth.uid | ☐ | ☐ | ☐ | |
| A4 | Logout | ☐ | ☐ | ☐ | |
| A5 | Technician blocked on web | ☐ | N/A | N/A | |

## Users

| # | Workflow | React | Flutter | Pass |
|---|----------|-------|---------|------|
| U1 | Admin creates user | ☐ | N/A | |
| U2 | New user logs into Flutter | ☐ | ☐ | |
| U3 | Admin deactivate user | ☐ | ☐ | |

## Work orders

| # | Workflow | React | Flutter R | Flutter T | Pass |
|---|----------|-------|-----------|-----------|------|
| W1 | Create WO + photos | ☐ | ☐ | N/A | |
| W2 | Admin sees new WO | ☐ | N/A | N/A | |
| W3 | Assign + push | ☐ | N/A | ☐ | |
| W4 | Technician start | N/A | N/A | ☐ | |
| W5 | Technician complete | N/A | N/A | ☐ | |
| W6 | **Requestor sign-off** | N/A | ☐ | N/A | |
| W7 | **Requestor reopen** | ☐ | ☐ | N/A | |
| W8 | Escalation blocked | ☐ | ☐ | N/A | |
| W9 | Admin status/reopen | ☐ | N/A | N/A | |
| W10 | Photo URLs render | ☐ | ☐ | ☐ | |

## PM / Inventory / Parts / PO / Support / Notifications / Storage

See staging spreadsheet template — cover P1–P4, I1–I4, S1–S3, N1–N4, ST1–ST3 from release audit.

## Cannot verify from repo alone

- Flutter offline sync
- OneSignal delivery rates
- Realtime publication config in Supabase dashboard
- Production Vercel secrets

## RC1 gate

**W6, W7, W8 must pass** after `20260703120000` + git/deploy alignment (P0-2).
