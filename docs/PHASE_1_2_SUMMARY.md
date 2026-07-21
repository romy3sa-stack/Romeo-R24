# Receipt24 — Phase 1 & Phase 2 Deliverable

Scope actually built in this pass, per the master prompt's final instruction
("Start with Phase 1 and Phase 2 only... Stop after Phase 2 and wait for the
next instruction"):

- Phase 1: project structure, roles, authentication **architecture**,
  recommended technical architecture, dev/test/prod environment structure.
- Phase 2: full database schema, relationships, Row Level Security,
  storage buckets, environment variable structure.
- **Not** built: any Phase 3+ screen (Welcome screen, registration forms,
  Consumer/Accountant/Admin dashboards, receipt capture, etc.) and no
  merchant authentication, roles, subscriptions, dashboards, QR issuing, or
  receipt-issuing of any kind (Rules 2-6).

---

## 1. Summary of what was created

**Repository layout**

```
supabase/
  config.toml                        Local Supabase stack config
  migrations/
    20260101000001_extensions.sql
    20260101000002_enums.sql
    20260101000003_lookup_tables.sql
    20260101000004_users_and_profiles.sql
    20260101000005_accountants.sql
    20260101000006_merchants_and_receipts.sql
    20260101000007_receipt_details.sql
    20260101000008_warranties_and_returns.sql
    20260101000009_platform_tables.sql
    20260101000010_functions_and_triggers.sql
    20260101000011_row_level_security.sql
    20260101000012_storage_buckets.sql
  seed.sql                           Reference data (categories, countries, currencies, languages)
  tests/
    00_local_supabase_stubs.sql      LOCAL TEST HARNESS ONLY (see docs/ENVIRONMENTS.md)
    01_rls_scenarios.sql             27 automated RLS assertions
scripts/
  db_apply_local.sh                  Applies stubs + migrations + seed to a throwaway local DB
app/                                  Flutter project ("receipt24")
  lib/
    core/
      env/env.dart                   Compile-time env config (no secrets)
      rbac/user_role.dart            UserRole enum mirroring public.user_role
      routing/app_area.dart          AppArea enum + forRole() mapping
      auth/app_user.dart             Client mirror of a public.users row
      auth/auth_service.dart         Supabase Auth wrapper (sign up/in/out, OAuth, reset)
      supabase/supabase_bootstrap.dart
      theme/app_colors.dart, app_theme.dart, app_theme_mode_controller.dart
    areas/consumer/ , areas/accountant/ , areas/admin/   Empty area folders (Rule: no dashboards yet)
    features/platform_status/platform_status_screen.dart  Phase 1/2 verification screen only
    shared/widgets/receipt24_logo.dart
  env/*.example.json                 Public config templates per environment
  assets/branding/receipt24_logo.png
  test/rbac_test.dart, test/widget_test.dart
docs/
  ARCHITECTURE.md, ENVIRONMENTS.md, PHASE_1_2_SUMMARY.md (this file), TESTING_CHECKLIST_PHASE_1_2.md
```

**User roles created:** `consumer`, `accountant`, `accounting_firm_manager`,
`super_administrator`, `support_administrator` (Postgres enum `public.user_role`
+ Dart enum `UserRole`). No merchant role of any kind exists.

**Database:** 21 tables — the 16 tables named explicitly in the master spec
(`users`, `consumer_profiles`, `accountants`, `accounting_firm_members`,
`accountant_client_access`, `merchants`, `receipts`, `receipt_items`,
`receipt_uploads`, `receipt_categories`, `expense_categories`,
`receipt_expense_classification`, `warranties`, `returns_and_refunds`,
`notifications`, `subscriptions`, `support_tickets`, `audit_logs` — that's
actually 18; see note below) plus 3 supporting lookup tables
(`languages`, `countries`, `currencies`) added to give `country`/`currency`/
`preferred_language` proper foreign keys instead of free text. See §2 for the
exact list and §8 for why these were added.

**Row Level Security:** enabled on every one of the 21 tables, with 60
policies total plus 5 defense-in-depth triggers that block privilege
escalation even within a row a user is otherwise allowed to update. See §4.

**Storage:** 6 buckets with owner-scoped (or admin/public, where
appropriate) `storage.objects` policies. See §5.

**Testing:** a local-Postgres test harness (§7) that stood in for the parts
of a real Supabase project this sandbox couldn't run (no Docker), plus 27
automated RLS assertions, all passing.

---

## 2. Complete database schema

> SQL identifiers are case-insensitive, so spec fields like `OCR_status`,
> `IP_address`, `VAT_eligible` are implemented as `ocr_status`, `ip_address`,
> `vat_eligible`. No meaning changed — see inline comments in the migrations.

### 2.1 Lookup tables *(added; not spec-literal — see §8)*

| Table | Key columns |
|---|---|
| `languages` | `code` (PK), `name`, `native_name`, `is_active` |
| `countries` | `code` (PK), `name`, `default_currency_code` → `currencies.code`, `phone_dial_code`, `is_active` |
| `currencies` | `code` (PK), `name`, `symbol`, `decimal_digits`, `is_active` |

### 2.2 `users`
`id` (PK, = `auth.users.id`), `full_name`, `email` (citext, unique),
`phone_number`, `profile_photo_url`, `role` (`user_role`), `preferred_language`
→ `languages`, `country` → `countries`, `currency` → `currencies`, `timezone`,
`account_status` (`account_status`), `email_verified`, `phone_verified`,
`deleted_at` *(added: soft-delete marker, Rule 17)*, `created_at`, `updated_at`.

### 2.3 `consumer_profiles`
`id` (PK), `user_id` (FK → `users`, unique), `tax_profile_enabled`,
`accountant_sharing_enabled`, `default_expense_type` (`expense_type`),
`notification_preferences` (jsonb), `marketing_consent`, `created_at`,
`updated_at`.

### 2.4 `accountants`
`id` (PK), `user_id` (FK → `users`, unique), `firm_name`,
`professional_registration_number`, `tax_number`, `country` → `countries`,
`address`, `phone_number`, `verification_status`
(`accountant_verification_status`), `verification_document_url`,
`subscription_plan`, `created_at`, `updated_at`.

### 2.5 `accounting_firm_members`
`id` (PK), `accountant_id` (FK → `accountants`), `user_id` (FK → `users`),
`firm_role` (`firm_member_role`: manager/staff), `permissions` (jsonb),
`account_status` (`account_status`), `created_at`, `updated_at`. Unique on
`(accountant_id, user_id)`.

### 2.6 `accountant_client_access`
`id` (PK), `accountant_id` (FK → `accountants`), `consumer_user_id` (FK →
`users`), `access_status` (`accountant_access_status`), `access_scope`
(jsonb — `{"type": "all_receipts"|"business_only"|"tax_related_only"|
"selected_categories"|"selected_date_range", ...}`), `start_date`,
`end_date`, `invitation_token` (unique), `approved_at`, `revoked_at`,
`created_at`, `updated_at`. Unique on `(accountant_id, consumer_user_id)`.

### 2.7 `merchants` *(data-only — Rules 2-6)*
`id` (PK), `merchant_name`, `trading_name`, `business_category`,
`tax_number`, `email`, `phone_number`, `website`, `address`, `city`,
`province_or_state`, `postal_code`, `country` → `countries`, `latitude`,
`longitude`, `logo_url`, `merchant_source` (`merchant_source`),
`verification_status` (`merchant_verification_status`),
`created_by_user_id` (FK → `users`, nullable), `created_at`, `updated_at`.

### 2.8 `receipts`
`id` (PK), `consumer_user_id` (FK → `users`), `merchant_id` (FK →
`merchants`, nullable), `merchant_name_raw`, `receipt_number`,
`transaction_reference`, `transaction_date`, `subtotal`, `tax_amount`,
`discount_amount`, `total_amount`, `currency` → `currencies`,
`payment_method`, `receipt_source` (`receipt_source`), `receipt_status`
(`receipt_status`), `receipt_file_url`, `receipt_image_url`, `ocr_status`
(`ocr_status`), `ocr_confidence_score`, `verification_status`
(`receipt_verification_status`), `warranty_available`, `return_deadline`,
`notes`, `deleted_at` *(added: soft-delete, Rule 16/17)*, `created_at`,
`updated_at`.

### 2.9 `receipt_items`
`id` (PK), `receipt_id` (FK → `receipts`), `item_name`, `item_description`,
`item_category`, `quantity`, `unit_price`, `tax_rate`, `tax_amount`,
`discount_amount`, `total_price`, `serial_number`, `warranty_period`,
`created_at`, `updated_at`.

### 2.10 `receipt_uploads`
`id` (PK), `user_id` (FK → `users`), `file_url`, `file_type`,
`upload_source` (`receipt_source`), `ocr_status` (`ocr_status`),
`ocr_raw_text`, `processing_status` (`upload_processing_status`),
`linked_receipt_id` (FK → `receipts`, nullable), `created_at`, `updated_at`.

### 2.11 `receipt_categories`
`id` (PK), `category_name` (unique), `category_icon`, `category_colour`,
`tax_relevance`, `created_at`, `updated_at`.

### 2.12 `expense_categories`
`id` (PK), `category_name` (unique), `category_code` (unique),
`tax_deductible`, `vat_eligible`, `description`, `created_at`, `updated_at`.

### 2.13 `receipt_expense_classification`
`id` (PK), `receipt_id` (FK → `receipts`, unique — one active classification
per receipt), `consumer_user_id` (FK → `users`), `expense_category_id` (FK →
`expense_categories`), `classification_source`
(`classification_source`), `confidence_score`, `user_confirmed`,
`expense_type` (`expense_type`: personal/business/mixed_use),
`business_percentage` (0-100 check), `notes`, `created_at`, `updated_at`.

### 2.14 `warranties`
`id` (PK), `receipt_id` (FK → `receipts`), `receipt_item_id` (FK →
`receipt_items`, nullable), `consumer_user_id` (FK → `users`),
`warranty_start_date`, `warranty_end_date`, `warranty_status`
(`warranty_status`), `reminder_status` (`warranty_reminder_status`),
`claim_reference`, `merchant_contact_details`, `notes`, `created_at`,
`updated_at`.

### 2.15 `returns_and_refunds`
`id` (PK), `receipt_id` (FK → `receipts`), `receipt_item_id` (FK →
`receipt_items`, nullable), `consumer_user_id` (FK → `users`),
`request_type` (`return_request_type`), `request_reason`,
`request_description`, `supporting_file_url`, `request_status`
(`return_request_status`), `refund_amount`, `merchant_response_notes`,
`created_at`, `updated_at`.

### 2.16 `notifications`
`id` (PK), `user_id` (FK → `users`), `notification_type`
(`notification_type`), `title`, `message`, `related_record_type`,
`related_record_id`, `read_status`, `created_at`.

### 2.17 `subscriptions`
`id` (PK), `user_id` (FK → `users`, nullable), `accountant_id` (FK →
`accountants`, nullable — exactly one of the two is set, enforced by a check
constraint; no merchant plans exist, Rule 5), `plan_name`, `billing_cycle`
(`billing_cycle`), `amount`, `currency` → `currencies`,
`subscription_status` (`subscription_status`), `start_date`,
`renewal_date`, `payment_provider`, `external_subscription_id`,
`created_at`, `updated_at`.

### 2.18 `support_tickets`
`id` (PK), `user_id` (FK → `users`), `ticket_number` (unique, auto-generated),
`subject`, `description`, `category`, `priority`
(`support_ticket_priority`), `ticket_status` (`support_ticket_status`),
`assigned_admin_id` (FK → `users`, nullable), `created_at`, `updated_at`.

### 2.19 `audit_logs`
`id` (PK), `user_id` (FK → `users`, nullable), `action_type`, `record_type`,
`record_id`, `previous_value` (jsonb), `new_value` (jsonb), `ip_address`
(inet), `device_information` (jsonb), `created_at`. Append-only — see §4.

---

## 3. Relationships between tables

```
auth.users (Supabase-managed)
  └─1:1─ public.users
           ├─1:1─ consumer_profiles
           ├─1:1─ accountants
           │        ├─1:N─ accounting_firm_members ─N:1─ users
           │        ├─1:N─ accountant_client_access ─N:1─ users (consumer_user_id)
           │        └─1:N─ subscriptions
           ├─1:N─ receipts (consumer_user_id)
           │        ├─1:N─ receipt_items
           │        ├─1:1─ receipt_expense_classification ─N:1─ expense_categories
           │        ├─1:N─ warranties
           │        ├─1:N─ returns_and_refunds
           │        └─N:1─ merchants
           ├─1:N─ receipt_uploads ─0:1─ receipts (linked_receipt_id)
           ├─1:N─ notifications
           ├─1:N─ subscriptions (user-owned plans)
           ├─1:N─ support_tickets
           └─1:N─ audit_logs

countries ─1:N─ users, accountants, merchants   (country FK)
currencies ─1:N─ users, receipts, subscriptions (currency FK)
languages ─1:N─ users                            (preferred_language FK)
```

Full FK list (verified by querying `information_schema` against the applied
schema — see §7):

| Child table | FK column | Parent table |
|---|---|---|
| accountant_client_access | accountant_id | accountants |
| accountant_client_access | consumer_user_id | users |
| accountants | country | countries |
| accountants | user_id | users |
| accounting_firm_members | accountant_id | accountants |
| accounting_firm_members | user_id | users |
| audit_logs | user_id | users |
| consumer_profiles | user_id | users |
| countries | default_currency_code | currencies |
| merchants | country | countries |
| merchants | created_by_user_id | users |
| notifications | user_id | users |
| receipt_expense_classification | consumer_user_id | users |
| receipt_expense_classification | expense_category_id | expense_categories |
| receipt_expense_classification | receipt_id | receipts |
| receipt_items | receipt_id | receipts |
| receipt_uploads | linked_receipt_id | receipts |
| receipt_uploads | user_id | users |
| receipts | consumer_user_id | users |
| receipts | currency | currencies |
| receipts | merchant_id | merchants |
| returns_and_refunds | consumer_user_id | users |
| returns_and_refunds | receipt_id | receipts |
| returns_and_refunds | receipt_item_id | receipt_items |
| subscriptions | accountant_id | accountants |
| subscriptions | currency | currencies |
| subscriptions | user_id | users |
| support_tickets | assigned_admin_id | users |
| support_tickets | user_id | users |
| users | country | countries |
| users | currency | currencies |
| users | preferred_language | languages |
| warranties | consumer_user_id | users |
| warranties | receipt_id | receipts |
| warranties | receipt_item_id | receipt_items |

Notably absent, by design: **no table has a foreign key to any merchant
"account"**, because merchants have no account — only `merchants.id` as a
plain data row referenced from `receipts.merchant_id`.

---

## 4. Row Level Security policies

Enabled on all 21 tables (`20260101000011_row_level_security.sql`). Pattern
per table:

| Table | Select | Insert / Update / Delete |
|---|---|---|
| `users` | self, admins, accountants with approved access | self can edit own profile fields; **role/account_status changes require an administrator** (trigger-enforced even on your own row) |
| `consumer_profiles` | owner, admin | owner, admin |
| `accountants` | owner, admin, any consumer who has an access record with them | owner can edit firm info; **verification_status requires an administrator** (trigger-enforced) |
| `accounting_firm_members` | member, owning accountant, admin | owning accountant, admin |
| `accountant_client_access` | consumer, accountant, admin | consumer or accountant can create/update (invite, revoke, change scope); **only the consumer (or an admin) may set `access_status='approved'`** (trigger-enforced — an accountant can never approve their own invitation) |
| `merchants` | any authenticated user (non-sensitive directory data) | any authenticated user may create; only the creator or an admin may update; only an admin may delete |
| `receipts` | owner, admin, accountant with an **approved, non-expired** grant for that consumer | owner can create; owner/admin/approved-accountant can update; only owner or a super_administrator can delete |
| `receipt_items` | inherits from parent `receipts` row | owner or admin only (accountants read via the parent receipt, but do not edit line items directly in this phase) |
| `receipt_uploads` | owner, admin | owner, admin (accountants never see the raw inbox) |
| `receipt_categories` / `expense_categories` | anyone (`anon` + `authenticated`) — public reference data | admin only |
| `receipt_expense_classification` | owner, admin, approved accountant | owner, admin, approved accountant (matches Step 9.3 "accountants classify receipts") |
| `warranties` | owner, admin | owner, admin (accountants are out of scope per spec — not listed among accountant portal features) |
| `returns_and_refunds` | owner, admin | owner, admin |
| `notifications` | owner, admin | admin/system inserts; owner can mark read / delete own |
| `subscriptions` | owning user, owning accountant, admin | owning user/accountant, admin |
| `support_tickets` | owner, assigned admin, any admin | owner (create/edit own), any admin |
| `audit_logs` | admin only | **no insert/update/delete policy for `anon`/`authenticated` at all** — rows are written only by the `SECURITY DEFINER` `write_audit_log()` trigger function, which (being owned by the table owner) bypasses RLS |
| `languages` / `countries` / `currencies` | anyone | admin only |

**Helper functions** (all `SECURITY DEFINER`, so they can safely read
`public.users`/`public.accountants` without themselves being blocked by
RLS, avoiding recursive-policy issues):
`current_user_role()`, `is_super_administrator()`, `is_support_administrator()`,
`is_administrator()`, `is_accountant_role()`, `current_accountant_id()`,
`accountant_has_client_access(consumer_id)`.

**Defense-in-depth triggers** (block a write even when the row-level policy
would otherwise allow it):
`prevent_self_privilege_escalation` (users.role/account_status),
`prevent_self_verification_change` (accountants.verification_status),
`prevent_accountant_self_approval` (accountant_client_access.access_status).

**Storage-layer RLS** (`storage.objects`) is documented separately in §5.

This directly satisfies the master spec's Phase 2 RLS requirements:
*"Consumers must only see their own receipts unless they explicitly share
access with an accountant. Accountants must only access records from
clients who approved access. Administrators must only access sensitive
receipt data when required for support, security, fraud investigation, or
legal compliance"* — the last clause (limiting *why* an admin looks, not
just *whether* they can) is enforced procedurally today (every admin
read/write is audit-logged for the sensitive tables in §2) rather than by a
technical RLS predicate, since RLS cannot express "for a legitimate
business reason." Actually restricting *when* admins may look further
requires an application-level support-ticket/justification workflow —
tracked as an open item in §8.

---

## 5. Storage structure

6 buckets (`20260101000012_storage_buckets.sql`), all owner-folder-scoped
(`<bucket>/<auth.uid()>/...`) except the public one:

| Bucket | Public? | Size limit | MIME types | Maps to spec field(s) |
|---|---|---|---|---|
| `receipts` | No | 50 MB | jpeg, png, heic, pdf | `receipts.receipt_file_url`, `receipts.receipt_image_url`, `receipt_uploads.file_url` |
| `avatars` | No | 5 MB | jpeg, png, webp | `users.profile_photo_url` |
| `accountant-verification-docs` | No | 20 MB | jpeg, png, pdf | `accountants.verification_document_url` |
| `warranty-documents` | No | 20 MB | jpeg, png, pdf | Warranty claim photos/documents (Step 8.2) |
| `return-evidence` | No | 20 MB | jpeg, png, pdf | `returns_and_refunds.supporting_file_url` |
| `merchant-logos` | **Yes** | 2 MB | jpeg, png, svg, webp | `merchants.logo_url` |

Every private bucket is protected by an owner-folder policy on
`storage.objects` (`(storage.foldername(name))[1] = auth.uid()::text`) plus
an administrator override. `merchant-logos` is public-read (merchants have
no owner to scope to) but write/verify is still gated (any authenticated
user may upload one; only an admin may overwrite/delete). URLs stored in
Postgres are **paths**, not permanent public URLs — Phase 5+ backend code
must resolve them to short-lived **signed URLs** at read time (Rule 11 /
Phase 13 "Signed storage URLs"); this phase does not yet implement that
resolution helper since no upload/read flow exists yet.

---

## 6. Configuration still required

Nothing below exists yet — all are Phase 3+ / Phase 18 work:

- A real hosted Supabase project per environment (dev/test/prod), linked via
  `supabase link` and `supabase db push` for these migrations.
- `SUPABASE_URL` / `SUPABASE_ANON_KEY` filled into `app/env/*.json` per
  environment (copy from the committed `*.example.json` templates).
- Email provider (Resend/SendGrid) — needed for signup verification (Step
  3.2) and later notifications (Phase 10).
- OCR provider (Google Vision / AWS Textract / Mindee) — needed starting
  Phase 5.
- Push notification provider (Firebase Cloud Messaging) — Phase 10.
- Payment provider (Stripe / Paystack / Peach Payments) — Phase 11.
- Analytics provider (PostHog / Firebase Analytics) — `Env.analyticsKey` is
  wired but no SDK is installed yet.
- Email-forwarding infrastructure for `username@receipts.receipt24.com`
  (Step 5.4) — DNS/MX records + inbound-email webhook, not part of this
  phase.
- Malware scanning for uploaded files (Phase 13) — not yet integrated.
- MFA enrollment UI (Supabase Auth MFA is enabled in `config.toml`, but no
  screen exists yet).
- CI/CD pipelines to run `supabase db push` and `flutter build` per
  environment (Phase 18).
- Legal review of the privacy/security posture before any real-compliance
  claim (POPIA/GDPR) is made, per the master spec's own instruction.

---

## 7. Testing checklist

See `docs/TESTING_CHECKLIST_PHASE_1_2.md` for the full checklist and results
(all items passing as of this phase). Headline results:

- ✅ All 12 migrations apply cleanly, in order, to a clean database with **0
  errors** (verified via `scripts/db_apply_local.sh`).
- ✅ `auth.users` → `public.users` sync trigger creates the correct
  `consumer_profiles` / `accountants` side-row per role, and blocks
  client-requested `super_administrator`/`support_administrator` signup.
- ✅ 27/27 automated RLS scenario assertions pass
  (`supabase/tests/01_rls_scenarios.sql`), covering: cross-consumer
  isolation, accountant access lifecycle (none → pending → approved →
  revoked), self-approval prevention, role/account_status escalation
  prevention, administrator visibility (both admin roles), audit log
  read/write restrictions, anonymous access to public reference data only,
  and merchant-record self-verification prevention.
- ✅ `flutter analyze` — 0 issues.
- ✅ `flutter test` — 6/6 tests pass (RBAC enum/role-mapping unit tests +
  platform status screen widget test).
- ✅ `flutter build web` succeeds; manually verified in a browser that the
  environment, Supabase-client-initialized, and auth-state indicators all
  render correctly with the Receipt24 brand mark and tagline.

---

## 8. Errors or unresolved issues

**Bugs found and fixed during this phase** (kept here for traceability, not
because they are still open):

1. `handle_new_auth_user()` originally assigned a bare text literal to the
   `account_status` enum column without a cast, which Postgres rejected —
   fixed by casting to `public.account_status`.
2. The privilege-escalation guard triggers on `users`/`accountants`/
   `accountant_client_access` initially fired even for service-role/seed
   contexts that have no `auth.uid()` (e.g. this phase's own test fixtures,
   and in production any trusted server-side admin-provisioning job) —
   fixed by only enforcing the guard when `auth.uid()` is present (i.e.
   there is a real end-user JWT), matching how PostgREST actually
   distinguishes user requests from service-role/backend requests.

**Deliberate deviations from a literal reading of the spec** (not errors,
but flagged per Rule 22 "do not change completed database structures
without explaining the impact" and general transparency):

1. Added `languages`, `countries`, `currencies` lookup tables. The spec's
   Phase 2 table list doesn't include them, but several spec-defined
   columns (`users.country`, `users.currency`, `users.preferred_language`,
   `accountants.country`, `receipts.currency`) are meaningless as real
   relational data without something to reference, and Phase 12 explicitly
   requires admins to "manage countries and currencies" / "manage
   languages." No spec-defined table's columns were renamed, removed, or
   retyped to accommodate this.
2. Normalized mixed-case spec field names to snake_case (`OCR_status` →
   `ocr_status`, `IP_address` → `ip_address`, `VAT_eligible` →
   `vat_eligible`) — SQL identifiers are case-insensitive, this is a
   representation detail only.
3. Where the spec named a status field but did not enumerate its values
   (e.g. `receipts.receipt_status`, `merchants.verification_status`,
   `receipts.verification_status`, `notifications.notification_type`), a
   reasonable enum was authored from context elsewhere in the master
   prompt (e.g. notification types come verbatim from the Phase 10 list).
   These are easy to extend (`ALTER TYPE ... ADD VALUE`) and are called out
   in `20260101000002_enums.sql`.
4. `accountant_client_access.access_scope` is stored as `jsonb` rather than
   a flat set of columns, since its shape depends on `access_scope_type`
   (all/business-only/tax-only/selected-categories/selected-date-range) —
   flattening it now would force speculative columns for scope types that
   may never be selected.

**Known limitations carried forward, not yet solved** (explicitly out of
scope for Phase 1/2, flagged for whichever phase should address them):

1. RLS can restrict *whether* an administrator can read sensitive receipt
   data, but not enforce *why* (support ticket vs. curiosity) — the spec
   asks for the latter ("only when required for support, security, fraud
   investigation, or legal compliance"). Mitigated today only by the fact
   that `audit_logs` records every administrator read/write to the
   sensitive tables listed in migration 10; a proper justified-access
   workflow (e.g. requiring an open support ticket reference before an
   admin query is allowed) is a Phase 12/13 product decision, not a
   database-schema one.
2. `receipt_items`/warranties/returns do not currently grant accountants
   any access, even when approved — the spec's Accountant Portal feature
   list (Phase 9) never mentions warranties/returns, so this was
   intentionally left consumer+admin-only; flag if that reading turns out
   wrong.
3. This sandbox has no Docker, so the real `supabase start` local stack and
   `supabase db push` to an actual hosted project were never exercised —
   only the SQL migrations themselves were validated, against a
   hand-built stand-in for `auth`/`storage` (see §"Local development
   without hosted Supabase" in `docs/ENVIRONMENTS.md`). Re-run
   `scripts/db_apply_local.sh`'s migrations through the real Supabase CLI
   as soon as Docker is available, before trusting this in a shared dev
   environment.
4. No Edge Functions, OCR, email, push, or payment integration exists yet —
   all Phase 5/10/11 work as planned, not an oversight in this phase.
