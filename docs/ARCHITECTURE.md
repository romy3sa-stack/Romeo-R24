# Receipt24 Phase 1–2 Architecture

## Scope

This foundation supports one shared platform with three application surfaces:

- `apps/consumer`: consumer mobile/web client
- `apps/accountant-portal`: accountant and accounting-firm portal
- `apps/admin-dashboard`: restricted super/support administration
- `packages/shared`: future shared translations, API contracts, and UI primitives
- `supabase`: PostgreSQL migrations, Auth integration, Storage policies, seed data, and tests

The app directories are boundaries only in this phase. No dashboard or merchant-facing interface is implemented.

## Authentication and authorization

Supabase Auth is the only identity provider. An `auth.users` insert creates a matching `public.users` record and consumer profile. New accounts default to the `consumer` role; trusted server/admin workflows must promote an approved accountant or administrator.

Supported roles:

1. `consumer`
2. `accountant`
3. `accounting_firm_manager`
4. `super_administrator`
5. `support_administrator`

Merchant identities and merchant roles do not exist. `public.merchants` stores data extracted from, or manually associated with, receipts.

Authorization is enforced in PostgreSQL, not only in clients:

- Grants remove anonymous table access and all authenticated hard deletes.
- Row-level security is enabled and forced on every public application table.
- Consumers own receipt records through `consumer_user_id`.
- Accountants need an approved, current, non-revoked access record and must satisfy its receipt scope.
- Administrators need both an administrator role and a trusted, server-issued `app_metadata.receipt_access_purpose` claim to read sensitive receipt data.
- Security-managed fields such as role and accountant verification are protected by triggers.
- Important changes generate immutable audit rows.

The accepted administrator purposes are `support`, `security`, `fraud_investigation`, and `legal_compliance`. The backend issuing such a claim must also create an access event and use a short-lived token.

## Service boundaries

Phase 1–2 configures no external provider. Later Edge Functions should own:

- OCR requests and callbacks
- email ingestion
- payment webhooks
- push/email delivery
- signed export generation
- privileged role, verification, and admin-purpose claims

Only publishable/anonymous keys belong in a client. Service-role, database, OCR, email, push, payment, and analytics secrets are server-only.

## Environments

Each environment must use an isolated Supabase project and isolated third-party provider accounts:

- Development: local Supabase from `supabase/config.toml`
- Testing: dedicated non-production Supabase project used by CI
- Production: restricted Supabase project with backups, point-in-time recovery, monitoring, and reviewed secrets

Copy the matching `environments/*.env.example` to a secret manager or local ignored file. Never commit populated environment files.

## Data retention

Financial tables do not grant client-side delete. `receipts`, uploads, warranties, and returns use `archived_at` for soft archival. A later reviewed retention job may perform legal deletion with the service role and must preserve an audit event.
