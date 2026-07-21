# Database Schema and Relationships

The executable schema is in:

- `202607200001_foundation_schema.sql`: types, tables, constraints, indexes, Auth synchronization
- `202607200002_rls_and_storage.sql`: authorization helpers, RLS, grants, private buckets
- `202607200003_audit_triggers.sql`: immutable audit capture

## Tables

| Table | Purpose | Principal fields |
| --- | --- | --- |
| `users` | Auth-linked platform identity | profile, role, locale, account/verification state |
| `consumer_profiles` | Consumer preferences | tax, sharing, expense, notification, consent settings |
| `accountants` | Professional profile | firm, registration, tax, verification, plan |
| `accounting_firm_members` | Firm membership | accountant, user, firm role, permissions, status |
| `accountant_client_access` | Consumer consent | accountant, consumer, status, JSON scope, dates, invitation |
| `merchants` | Receipt-derived merchant facts only | name, tax/contact/address/location, source, creator |
| `receipts` | Receipt header and processing state | owner, merchant/category, transaction, totals, files, OCR, warranty/return |
| `receipt_items` | Receipt line items | item, quantity, prices, tax, discount, serial/warranty |
| `receipt_uploads` | Original ingestion records | user, file, source, OCR text/status, linked receipt |
| `receipt_categories` | Administrator-managed receipt taxonomy | name, icon, colour, tax relevance |
| `expense_categories` | Administrator-managed expense taxonomy | name/code, tax/VAT flags, description |
| `receipt_expense_classification` | One classification per receipt | category, source/confidence, expense type, business percentage |
| `warranties` | Item/receipt warranty tracking | dates, status, reminders, claim/contact data |
| `returns_and_refunds` | User-side return tracking | type/reason, evidence, status, refund, response |
| `notifications` | In-app notifications | type, message, related record, read state |
| `subscriptions` | Consumer or accountant billing state | exclusive owner, plan, billing, provider |
| `support_tickets` | Support workflow | user, number, description, priority/status, assignee |
| `audit_logs` | Append-only important change history | actor, action, record, old/new JSON, IP/device |
| `duplicate_receipt_alerts` | Non-destructive duplicate review | owner, receipt pair, reasons, confidence, status |

All requested fields are represented using snake_case. Additive fields are `receipt_category_id`, `archived_at`, and the duplicate alert record needed by the stated administrator and duplicate-detection requirements.

## Relationship map

- `auth.users` 1—1 `users`
- `users` 1—1 `consumer_profiles`
- `users` 1—0..1 `accountants`
- `accountants` 1—many `accounting_firm_members`; each member references `users`
- `accountants` many—many consumer `users` through `accountant_client_access`
- consumer `users` 1—many `receipts`, uploads, warranties, returns, notifications, tickets, and duplicate alerts
- `merchants` 1—many `receipts`; a merchant creator is always a platform user, never a merchant login
- `receipt_categories` 1—many `receipts`
- `receipts` 1—many `receipt_items`
- `receipts` 1—0..1 `receipt_expense_classification`
- `expense_categories` 1—many receipt classifications
- `receipts` 1—many warranties and returns; optional item references must belong to that same receipt
- uploads can link to one receipt and are constrained to the same consumer
- subscriptions belong to exactly one consumer user or one accountant profile
- duplicate alert receipt pairs must both belong to the alert's consumer

Composite foreign keys prevent a caller from attaching a child record to a receipt owned by another consumer.

## Access scope JSON

`accountant_client_access.access_scope` uses one of:

- `{"type":"all_receipts"}`
- `{"type":"business_only"}`
- `{"type":"tax_related_only"}`
- `{"type":"selected_categories","expense_category_ids":["<uuid>"],"receipt_category_ids":["<uuid>"]}`
- `{"type":"date_range","start_date":"2026-01-01","end_date":"2026-12-31"}`

Unknown scope types deny access.
