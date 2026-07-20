# Row-Level Security Policies

All 22 public tables have RLS enabled. Access is enforced at the database level — clients cannot bypass these policies.

## Helper Functions

| Function | Returns | Purpose |
|----------|---------|---------|
| `get_user_role()` | user_role | Current user's role |
| `is_super_admin()` | boolean | Super administrator check |
| `is_support_admin()` | boolean | Super or support admin |
| `is_admin()` | boolean | Alias for support admin check |
| `is_accountant()` | boolean | Accountant or firm manager |
| `is_consumer()` | boolean | Consumer role check |
| `get_accountant_id()` | UUID | Current user's accountant record |
| `accountant_has_client_access(consumer_id, receipt_id?)` | boolean | Approved client access with scope |

## Access Matrix

### Consumers

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| users | Own | — | Own | — |
| consumer_profiles | Own | Own | Own | — |
| receipts | Own (not soft-deleted) | Own | Own | — |
| receipt_items | Own receipts | Own receipts | Own receipts | Own receipts |
| receipt_uploads | Own | Own | Own | — |
| merchants | Created by self or linked receipts | Any authenticated | Own created | — |
| warranties | Own | Own | Own | — |
| returns_and_refunds | Own | Own | Own | — |
| notifications | Own | — | Own (read status) | — |
| subscriptions | Own | — | — | — |
| support_tickets | Own | Own | Own | — |
| audit_logs | Own actions | Any authenticated | — | — |
| categories | All active | — | — | — |

### Accountants

| Table | SELECT | INSERT | UPDATE | DELETE |
|-------|--------|--------|--------|--------|
| users | Approved clients | — | — | — |
| consumer_profiles | Approved clients | — | — | — |
| receipts | Approved clients (scope-filtered) | — | Approved clients | — |
| receipt_items | Via receipt access | — | Via receipt access | — |
| receipt_expense_classification | Approved clients | Approved clients | Approved clients | — |
| accountant_client_access | Own + client view | Own invitations | Client approval / revoke | — |
| accountants | Own | Own | Own | — |
| accounting_firm_members | Own firm | Firm manager | Firm manager | — |

### Administrators

| Role | Access |
|------|--------|
| `super_administrator` | Full CRUD on all tables |
| `support_administrator` | Users (read), support tickets (full), audit logs (read) |

### Scope-Based Accountant Access

When `access_scope` is set on `accountant_client_access`:

| Scope | Receipt Access |
|-------|---------------|
| `all_receipts` | All client receipts |
| `business_only` | Receipts classified as business or mixed use |
| `tax_related_only` | Receipts with tax-deductible or VAT-eligible categories |
| `selected_categories` | Filtered by `scope_config` category list |
| `selected_date_range` | Filtered by `scope_config` date range |

Access is denied when:
- `access_status` ≠ `approved`
- `end_date` has passed
- `start_date` is in the future
- Client has revoked access

## Merchant Table Policy

Merchants have no authentication. Access rules:

- **SELECT:** User created the merchant, user has a receipt linked to the merchant, accountant has client access to linked receipts, or admin
- **INSERT:** Any authenticated user (consumer, accountant, admin)
- **UPDATE:** Creator or admin only

## Soft Deletion

Receipts use `soft_deleted_at` instead of hard deletion. RLS policies exclude soft-deleted receipts from consumer and accountant SELECT queries. Super administrators can still access them for compliance.

## Audit Logging

All authenticated users can INSERT audit logs. Only the acting user and super administrators can SELECT audit log entries.

## Storage RLS

Storage policies mirror database access:
- Files stored at `{bucket}/{user_id}/{filename}`
- Users can only access files in their own folder
- Admins can access verification documents and support attachments
- Accountants cannot directly access storage — they access receipt files through signed URLs generated server-side (Phase 5)
