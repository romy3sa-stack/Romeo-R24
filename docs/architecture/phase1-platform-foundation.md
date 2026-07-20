# Phase 1: Platform Foundation

## Product

**Receipt24** — *Every Receipt. One Place.*

Digital receipt management for three user groups only:

1. Consumers
2. Accountants
3. Administrators

Merchants never register, log in, subscribe, or use the platform. Merchant information exists only as receipt-extracted data.

## Platform areas

| Area | Purpose | Suggested host |
|------|---------|----------------|
| Consumer App | Scan, upload, organise, analyse, share, export receipts | `app.receipt24.com` |
| Accountant Portal | Client invitations, authorised receipt review, exports | `accountant.receipt24.com` |
| Super Admin Dashboard | Users, verification, categories, OCR, billing, support | `admin.receipt24.com` |

Shared backend API: `api.receipt24.com` (Supabase).

## User roles (RBAC)

Allowed:

- `consumer`
- `accountant`
- `accounting_firm_manager`
- `super_administrator`
- `support_administrator`

Forbidden (must never exist):

- Merchant Owner / Manager / Cashier / Staff / Administrator

Role checks are enforced in:

1. Application route guards (per platform area)
2. Supabase JWT custom claims / `public.users.role`
3. PostgreSQL RLS helper functions (`is_admin`, `is_accountant_user`, `accountant_has_client_access`)

## Recommended technical architecture

| Concern | Choice |
|---------|--------|
| Consumer mobile | Flutter (iOS / Android / responsive web) |
| Accountant + Admin portals | Flutter web or Next.js (scaffolded under `apps/`) |
| Backend | Supabase |
| Database | PostgreSQL |
| Auth | Supabase Auth (email, Google, Apple) |
| File storage | Supabase Storage (private buckets + signed URLs) |
| Server functions | Supabase Edge Functions |
| Notifications | FCM + email provider |
| OCR | Google Vision / AWS Textract / Mindee (server-side keys only) |
| Payments | Stripe / Paystack / Peach (server-side) |
| Analytics | PostHog or Firebase Analytics |

## Authentication architecture

```
Client apps
  → Supabase Auth (email/password, Google, Apple)
  → JWT with auth.uid()
  → public.users row (role, status, preferences)
  → RLS policies gate every table

Registration flows
  Consumer → account_status = active (email verification required)
  Accountant → account_status = pending until admin verification
  Admin → provisioned by super administrator only (pending until activated)
```

Bootstrap trigger: `public.handle_new_auth_user()` creates `public.users` and, for consumers, `consumer_profiles` with a unique forwarding email local-part.

## Security principles (foundation)

- Row-level security on all tables before real users
- Service-role key never shipped to clients
- Soft delete for financial records (`soft_delete_receipt`)
- Audit log inserts for registration and sensitive actions
- POPIA / GDPR-oriented privacy controls prepared (devices, consent, data export hooks in later phases)
- No merchant authentication surface

## Project structure

```
apps/consumer/          # Flutter consumer app (Phase 3+)
apps/accountant/        # Accountant portal scaffold
apps/admin/             # Admin dashboard scaffold
packages/shared/        # Shared roles, enums, platform area constants
supabase/migrations/    # Schema, RLS, storage, auth hooks
supabase/seed/          # Reference data for local/dev
config/environments/    # Dev / testing / production env templates
assets/branding/        # Logo + brand tokens
docs/                   # Architecture + testing docs
```

## Out of scope for Phase 1–2

- Dashboards and UI screens
- OCR pipelines
- Billing checkout
- Email import workers
- Push notification delivery
- Merchant-facing anything
