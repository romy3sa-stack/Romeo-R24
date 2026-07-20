# Testing Checklist — Phase 1 & Phase 2

Complete before starting Phase 3 (Authentication UI / Onboarding).

## Project structure

- [ ] Repository contains `apps/`, `packages/shared/`, `supabase/`, `config/environments/`, `docs/`, `assets/branding/`
- [ ] No merchant app, merchant role, or merchant subscription plan exists
- [ ] Brand logo and tokens are present under `assets/branding/`

## Roles & auth architecture

- [ ] Allowed roles are only: consumer, accountant, accounting_firm_manager, super_administrator, support_administrator
- [ ] Shared package exports match SQL enum `user_role`
- [ ] Auth bootstrap trigger creates `public.users` on signup
- [ ] Consumer signup also creates `consumer_profiles`
- [ ] Accountant signup leaves `account_status = pending`
- [ ] Injecting a `merchant_*` role in auth metadata is rejected

## Schema

- [ ] All Phase 2 tables exist after migrations
- [ ] Foreign keys match documented relationships
- [ ] Soft-delete columns exist on receipts / warranties / returns / merchants / users
- [ ] `subscription_plans.audience` cannot be merchant
- [ ] Mixed-use classification requires `business_percentage`
- [ ] Seed loads languages, currencies, countries, expense categories, plans, legal drafts

## Row-level security

- [ ] RLS enabled on every public table listed in migration `20260720000006`
- [ ] Consumer can select only own receipts
- [ ] Second consumer cannot select first consumer’s receipts
- [ ] Accountant without approved access cannot select client receipts
- [ ] Approved accountant can select in-scope receipts
- [ ] Revoked access blocks further receipt reads
- [ ] Admin helpers (`is_admin`) work for support/super admin users
- [ ] `audit_logs` has no update/delete policies for normal users

## Storage

- [ ] Buckets created: receipt-images, receipt-pdfs, verification-documents, profile-photos, support-attachments, warranty-documents
- [ ] Buckets are private
- [ ] User can upload only under own folder prefix
- [ ] User cannot read another user’s folder

## Environments

- [ ] `.env.example` documents frontend-safe vs server-only keys
- [ ] Development / testing / production templates exist
- [ ] No production secrets are committed

## Local Supabase (when CLI + Docker available)

- [ ] `supabase start` succeeds
- [ ] `supabase db reset` applies all migrations + seed
- [ ] Studio opens and tables are visible
- [ ] Auth signup creates related profile rows

## Known deferred (not Phase 1–2 failures)

- [ ] Dashboards / screens not built yet (Phase 3+)
- [ ] OCR / email import / payments / FCM not configured yet
- [ ] Legal documents are drafts pending professional review
