# Phase 2: Row-Level Security Policies

RLS is enabled on every application table and on private storage objects.

## Helper functions

| Function | Meaning |
|----------|---------|
| `current_user_id()` | `auth.uid()` |
| `current_user_role()` | Role from `public.users` |
| `is_admin()` | Active support or super administrator |
| `is_super_admin()` | Active super administrator |
| `is_accountant_user()` | Active accountant or firm manager |
| `current_accountant_id()` | Firm id for the signed-in accountant/member |
| `accountant_has_client_access(consumer_id, receipt_id?)` | Approved, in-date, scoped access |

## Access model

### Consumers

- Read/write own profile, receipts, uploads, warranties, returns, devices, notifications
- Approve / revoke accountant access
- Soft-delete own receipts (function), not hard-delete

### Accountants

- Read own accountant profile and firm membership
- Invite clients and manage invitations they own
- Read/update only receipts for clients with `access_status = approved`
- Scope filters:
  - all receipts
  - business only
  - tax-related only
  - selected categories
  - selected date range
- Changes should be audited by application code (Phase 9+)

### Administrators

- Manage users, verification, categories, plans, templates, legal docs
- May read sensitive receipt data when required for support, security, fraud, or legal compliance
- Support admins are included in `is_admin()`; destructive hard-delete of receipts is super-admin only

### Merchants

- No policies for merchant login — merchants have no user accounts

## Storage policies

Buckets are private. Object paths must start with `{auth.uid()}/...`.

Signed URLs are required for client downloads (configured in later phases / Edge Functions).

## Testing focus

1. Consumer A cannot read Consumer B receipts
2. Accountant without approval cannot read client receipts
3. Accountant access stops after revoke
4. Scope `business_only` hides personal-only receipts
5. Admin can assist; anonymous users see nothing sensitive
