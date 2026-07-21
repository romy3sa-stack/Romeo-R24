# Receipt24 — Platform Architecture (Phase 1)

## 1. Product areas (Step 1.1)

One shared platform, three areas, no merchant area:

| Area | Who | Where it lives in this repo |
|---|---|---|
| Consumer App | `consumer` | `app/lib/areas/consumer/` |
| Accountant Portal | `accountant`, `accounting_firm_manager` | `app/lib/areas/accountant/` |
| Super Admin Dashboard | `super_administrator`, `support_administrator` | `app/lib/areas/admin/` |

All three areas share one Flutter codebase (`app/`) and one Supabase backend
(`supabase/`). `AppArea.forRole()` (`app/lib/core/routing/app_area.dart`)
is the single place that decides which area a signed-in user lands in.
Merchants are never a fourth area — they have no login, no role, and no
folder here (Rules 2-6). All merchant data lives only in `public.merchants`,
populated as a side effect of receipt capture.

## 2. Roles (Step 1.2)

```
public.user_role (Postgres enum)          UserRole (Dart enum)
─────────────────────────────             ─────────────────────────
consumer                          <──>    UserRole.consumer
accountant                        <──>    UserRole.accountant
accounting_firm_manager           <──>    UserRole.accountingFirmManager
super_administrator                <──>    UserRole.superAdministrator
support_administrator              <──>    UserRole.supportAdministrator
```

- Defined in `supabase/migrations/20260101000002_enums.sql` and
  `app/lib/core/rbac/user_role.dart`.
- No merchant role exists anywhere (`merchant_owner`, `merchant_manager`,
  `merchant_cashier`, `merchant_staff`, `merchant_administrator` are all
  absent by design).
- Enforcement is layered:
  1. **Grants** — `GRANT`s in `20260101000011_row_level_security.sql` decide
     which Postgres role (`anon` / `authenticated`) may touch a table at all.
  2. **Row Level Security** — policies decide which *rows* a given
     `auth.uid()` may see/change (see `docs/RLS_POLICIES.md` /
     `docs/PHASE_1_2_SUMMARY.md` §4).
  3. **Triggers** — `prevent_self_privilege_escalation`,
     `prevent_self_verification_change`, `prevent_accountant_self_approval`
     stop a user from writing specific *columns* (role, account_status,
     verification_status, access_status) even on a row RLS otherwise lets
     them update.
  4. **Client RBAC** — `UserRole`/`AppArea` in Dart mirror the same rules so
     the UI never even offers an action the backend would reject; the
     backend is always the actual source of truth.

## 3. Authentication architecture (Step 1.3 / Phase 3 backbone)

- **Supabase Auth** issues/refreshes sessions, hashes passwords, verifies
  email, and will drive OAuth (Google/Apple) and MFA in later phases.
- On every `auth.users` insert, the `handle_new_auth_user()` trigger
  (`20260101000010_functions_and_triggers.sql`) creates the matching
  `public.users` row:
  - Role comes from `raw_user_meta_data.role`, defaulting to `consumer`.
  - **Administrator roles can never be self-granted** — the trigger silently
    downgrades any signup requesting `super_administrator` /
    `support_administrator` back to `consumer`.
  - `consumer` → also creates a `public.consumer_profiles` row.
  - `accountant` → also creates a `public.accountants` row with
    `verification_status='pending'` and `account_status='pending'`
    (Step 3.4 — accountants stay pending until an admin approves them).
- `handle_auth_user_confirmed()` mirrors `auth.users.email_confirmed_at`
  into `public.users.email_verified`.
- The Flutter side (`app/lib/core/auth/auth_service.dart`) only ever calls
  public Supabase Auth APIs (`signUp`, `signInWithPassword`,
  `signInWithOAuth`, `resetPasswordForEmail`, `signOut`) — it never talks to
  `public.users` with elevated privilege; it just reads its own row, which
  RLS always allows.
- No registration/login **screens** are built in this phase — that is
  Phase 3. This phase only proves the plumbing works
  (`app/lib/features/platform_status/platform_status_screen.dart`).

## 4. Recommended technical stack (Step 1.3)

| Concern | Choice | Where configured |
|---|---|---|
| Frontend | Flutter (mobile-first, responsive) | `app/` |
| Backend | Supabase | `supabase/` |
| Database | PostgreSQL | `supabase/migrations/` |
| Auth | Supabase Auth | trigger + `AuthService` |
| File storage | Supabase Storage | `20260101000012_storage_buckets.sql` |
| Server functions | Supabase Edge Functions | not yet created (Phase 5+: OCR, email import, exports) |
| Push notifications | Firebase Cloud Messaging | not yet configured (Phase 10) |
| Email | Resend / SendGrid | not yet configured (Phase 3/10) |
| OCR | Google Vision / AWS Textract / Mindee | not yet configured (Phase 5) |
| Payments | Stripe / Paystack / Peach Payments | not yet configured (Phase 11) |
| Analytics | PostHog / Firebase Analytics | `Env.analyticsKey` wired, provider not chosen |

Every secret-holding integration above is intentionally **not** wired to a
real provider yet — see "Configuration still required" in
`docs/PHASE_1_2_SUMMARY.md`. Only the Supabase anon key and other
public/publishable keys are allowed to exist in `app/`.
