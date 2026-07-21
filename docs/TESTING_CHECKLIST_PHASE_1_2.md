# Testing Checklist — Phase 1 & Phase 2

Rule 21 requires a testing checklist after every phase. This one covers the
platform foundation + database phase only (no consumer/accountant/admin
screens exist yet to test).

## Database schema & migrations

- [x] Every migration in `supabase/migrations/` applies in order with 0
      errors against a clean database (`scripts/db_apply_local.sh`).
- [x] Re-running `scripts/db_apply_local.sh` against a dropped/recreated
      database is idempotent (drops + recreates cleanly every time).
- [x] `seed.sql` inserts reference data (languages, countries, currencies,
      receipt categories, expense categories) without conflicts, and is
      safe to re-run (`ON CONFLICT ... DO NOTHING`).
- [x] All 21 tables exist with the expected columns (spot-checked via
      `\dt public.*` and `information_schema`).
- [x] All 35 foreign keys resolve to the expected parent table/column (see
      `docs/PHASE_1_2_SUMMARY.md` §3).
- [ ] Re-validate against a real hosted Supabase project once available
      (this sandbox has no Docker for `supabase start`) — see
      `docs/ENVIRONMENTS.md`.

## Auth architecture

- [x] Inserting into `auth.users` with `role: consumer` metadata creates a
      matching `public.users` row (role `consumer`, `account_status='active'`)
      **and** a `public.consumer_profiles` row.
- [x] Inserting into `auth.users` with `role: accountant` metadata creates a
      `public.users` row (role `accountant`, `account_status='pending'`)
      **and** a `public.accountants` row (`verification_status='pending'`).
- [x] Requesting `role: super_administrator` / `support_administrator` via
      signup metadata is silently downgraded to `consumer` — administrators
      cannot self-provision.
- [x] `email_confirmed_at` transitioning from null → non-null on
      `auth.users` flips `public.users.email_verified` to `true`.

## Row Level Security — consumer isolation

- [x] Consumer A cannot see Consumer B's receipts (0 rows returned).
- [x] Consumer B cannot insert a receipt with `consumer_user_id` set to
      Consumer A.

## Row Level Security — accountant access lifecycle

- [x] An accountant with no `accountant_client_access` grant sees 0 receipts
      for a consumer.
- [x] A **pending** grant still blocks receipt visibility.
- [x] An accountant cannot set their own grant's `access_status` to
      `approved` (self-approval is blocked by trigger).
- [x] Once the consumer approves the grant, the accountant can read (and,
      per spec, update/classify) that consumer's receipts.
- [x] Approved access to Consumer A does not leak into Consumer B's data.
- [x] An uninvolved accountant (no grant at all) still sees 0 rows for
      Consumer A even while another accountant has approved access.
- [x] Revoking the grant immediately removes the accountant's visibility
      again.

## Row Level Security — privilege escalation

- [x] A consumer cannot change their own `role` to `super_administrator`.
- [x] A consumer cannot change another consumer's `account_status`.
- [x] A non-creator, non-admin accountant cannot flip a merchant's
      `verification_status` to `verified`.

## Row Level Security — administrators & audit logs

- [x] `super_administrator` can read all receipts across all consumers.
- [x] `support_administrator` has the same read access as
      `super_administrator` (support/fraud investigation use case).
- [x] Both administrator roles can read `audit_logs`.
- [x] A consumer cannot read `audit_logs` at all (0 rows).
- [x] A consumer cannot insert directly into `audit_logs` (writes only
      happen via the `SECURITY DEFINER` trigger function).

## Row Level Security — public reference data & anonymous access

- [x] An anonymous (unauthenticated) request cannot read `receipts` (either
      denied at the GRANT layer or returns 0 rows via RLS — both pass).
- [x] An anonymous request **can** read `receipt_categories` (public
      reference data, by design, e.g. for pre-login browsing).

## Merchants (data-only)

- [x] Any authenticated user can create a merchant record (e.g. from an OCR
      scan).
- [x] Any authenticated user can read merchant directory data.
- [x] A user who did not create a merchant record (and is not an admin)
      cannot verify it.

## Storage

- [x] All 6 buckets are created with the correct `public` flag, size limit,
      and MIME allow-list.
- [x] Every private bucket has an owner-folder-scoped policy on
      `storage.objects`.
- [ ] End-to-end signed-URL issuance/expiry — not testable yet, no upload
      flow exists until Phase 5.

## Flutter app scaffold

- [x] `flutter analyze` reports 0 issues.
- [x] `flutter test` — all unit tests (`UserRole`/`AppArea` mapping) and the
      platform-status widget test pass.
- [x] `flutter build web` completes successfully.
- [x] Manually verified in a browser: logo, tagline, and the Phase 1/2
      status card (environment, Supabase client state, auth state) render
      correctly.
- [ ] iOS/Android native builds — not exercised in this sandbox (no
      Xcode/Android SDK toolchains configured); revisit once a device/
      emulator target is available, per Phase 18.

## How to re-run everything

```bash
# Database + RLS
bash scripts/db_apply_local.sh receipt24_test
sudo -u postgres psql -d receipt24_test -f supabase/tests/01_rls_scenarios.sql

# Flutter
cd app
flutter analyze
flutter test
flutter build web --dart-define-from-file=env/development.example.json
```
