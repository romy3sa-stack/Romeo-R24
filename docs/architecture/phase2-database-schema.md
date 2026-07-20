# Phase 2: Database Schema

## Entity relationship overview

```
auth.users 1──1 public.users
public.users 1──0..1 consumer_profiles
public.users 1──0..1 accountants
accountants 1──* accounting_firm_members ──* users
accountants 1──* accountant_client_access ──* users (consumers)
users (consumers) 1──* receipts ──0..1 merchants
receipts 1──* receipt_items
receipts 1──0..1 receipt_expense_classification ──0..1 expense_categories
receipts 0..1──* receipt_uploads
receipts 1──* warranties
receipts 1──* returns_and_refunds
receipts 1──* duplicate_receipt_alerts
users 1──* notifications
users 1──* subscriptions
accountants 1──* subscriptions
users 1──* support_tickets
users 1──* audit_logs
users 1──* user_devices
accountants 1──* document_requests / accountant_notes
```

Merchants are **not** linked to `auth.users`. They are receipt metadata only.

## Tables

### Identity & access

| Table | Purpose |
|-------|---------|
| `users` | Platform profile + role |
| `consumer_profiles` | Consumer preferences, sharing, forwarding email |
| `accountants` | Firm + verification |
| `accounting_firm_members` | Staff under a firm |
| `accountant_client_access` | Invitation + approved scope |
| `user_devices` | Device / push token management |

### Receipt domain

| Table | Purpose |
|-------|---------|
| `merchants` | Extracted merchant data only |
| `receipts` | Core receipt wallet records |
| `receipt_items` | Line items |
| `receipt_uploads` | Upload + OCR processing jobs |
| `receipt_categories` | Admin-managed receipt categories |
| `expense_categories` | Admin-managed expense categories |
| `receipt_expense_classification` | Personal / business / mixed + category |
| `warranties` | Warranty tracking + claim notes |
| `returns_and_refunds` | Return / refund tracking |
| `duplicate_receipt_alerts` | Suspected duplicates for review |

### Operations

| Table | Purpose |
|-------|---------|
| `notifications` | In-app notifications |
| `subscriptions` | Consumer / accountant billing |
| `subscription_plans` | Plan catalogue (no merchant plans) |
| `support_tickets` | Support workflow |
| `audit_logs` | Action history |
| `document_requests` | Accountant → consumer requests |
| `accountant_notes` | Accountant notes on client receipts |

### Platform CMS / reference

| Table | Purpose |
|-------|---------|
| `countries` | Country catalogue |
| `currencies` | Currency catalogue |
| `languages` | Language catalogue |
| `legal_documents` | Terms / privacy content |
| `notification_templates` | Multichannel templates |

## Important constraints

- `subscription_plans.audience` limited to `consumer` | `accountant`
- Mixed-use expense classification requires `business_percentage`
- Duplicate alerts never auto-delete receipts
- Receipts prefer soft delete via `deleted_at` / `soft_delete_receipt()`
- Auth trigger rejects any role resembling `merchant%`

## Enums

See migration `20260720000001_phase1_enums_and_helpers.sql` and `packages/shared/src/enums.ts` / `roles.ts`.
