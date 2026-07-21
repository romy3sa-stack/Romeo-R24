# Environments

Receipt24 uses three environments end-to-end (Step 1.3 / Phase 18):

| Environment | Purpose | Supabase project | Flutter config |
|---|---|---|---|
| Development | Local iteration, seeded/mock data | Local `supabase start` stack (or a dedicated "dev" hosted project) | `app/env/development.json` |
| Test | QA / staging / CI, production-like but disposable | Dedicated "test" hosted Supabase project | `app/env/test.json` |
| Production | Real users, real money | Dedicated "production" hosted Supabase project, private | `app/env/production.json` |

Each environment is a **fully separate Supabase project** (separate
database, separate Auth users, separate storage buckets, separate secrets).
Nothing is shared between them except this codebase.

## Backend (Supabase) configuration per environment

Applied via `supabase link` + `supabase db push` (or CI) per project, using
the same `supabase/migrations/*.sql` for all three:

| Variable | Where it lives | Notes |
|---|---|---|
| `SUPABASE_DB_PASSWORD` | Supabase project settings / CI secret | Never committed |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function secrets / CI secret | **Never** shipped to `app/` |
| `SUPABASE_JWT_SECRET` | Managed by Supabase | Used to verify custom JWT claims if added later |
| `OCR_PROVIDER_API_KEY` | Edge Function secret (Phase 5) | Google Vision / AWS Textract / Mindee |
| `EMAIL_PROVIDER_API_KEY` | Edge Function secret (Phase 3/10) | Resend / SendGrid |
| `EMAIL_INBOUND_WEBHOOK_SECRET` | Edge Function secret (Phase 5.4) | Verifies inbound email-import webhook |
| `FCM_SERVER_KEY` | Edge Function secret (Phase 10) | Push notifications |
| `PAYMENT_PROVIDER_SECRET_KEY` | Edge Function secret (Phase 11) | Stripe/Paystack/Peach secret key |
| `ANALYTICS_WRITE_KEY` | Can be public or secret depending on provider | PostHog/Firebase |

None of these exist as real values yet — they are provisioned when each
integration is actually built (Phase 5/10/11), per Rule 11 ("never expose
secret keys") and Rule 19 ("replace mock data with secure database queries
before production").

## Frontend (Flutter) configuration per environment

Only **public** values ever reach `app/` — see `app/env/README.md`:

```
app/env/development.example.json   (committed template)
app/env/test.example.json          (committed template)
app/env/production.example.json    (committed template)
app/env/development.json           (gitignored, filled in locally)
app/env/test.json                  (gitignored, filled in per CI)
app/env/production.json            (gitignored, filled in per CI/release)
```

```json
{
  "APP_ENVIRONMENT": "development",
  "SUPABASE_URL": "...",
  "SUPABASE_ANON_KEY": "...",
  "ANALYTICS_KEY": "...",
  "PAYMENTS_PUBLISHABLE_KEY": "..."
}
```

Consumed at build/run time via:

```bash
flutter run   --dart-define-from-file=app/env/development.json
flutter build web --dart-define-from-file=app/env/production.json
```

`app/lib/core/env/env.dart` reads these as compile-time constants
(`String.fromEnvironment`) — they are never read from a bundled `.env`
asset file, so nothing environment-specific ships inside the binary by
accident.

## Local development without hosted Supabase

This sandbox has no Docker, so `supabase start` (the official local dev
stack) could not be exercised here. Instead, Phase 2 was validated against
a plain local PostgreSQL 16 instance with hand-built stand-ins for the
`auth`/`storage` schemas and roles that a real Supabase project already
provides — see `supabase/tests/00_local_supabase_stubs.sql` and
`scripts/db_apply_local.sh`. This is a **test-only** harness; it is not a
migration and must never be pointed at a real Supabase project. Once Docker
is available, the exact same `supabase/migrations/*.sql` files apply
unchanged in the real local stack (`supabase start && supabase db reset`).
