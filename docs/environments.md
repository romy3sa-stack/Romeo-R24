# Environments

Receipt24 supports three environments with separate Supabase projects.

## Environment Files

| File | Purpose |
|------|---------|
| `.env.example` | Template with all variables documented |
| `.env.development` | Local development overrides |
| `.env.testing` | Staging/test environment |
| `.env.production` | Production environment |

Each Flutter app also has its own `.env` file with Supabase credentials.

## Development

**Purpose:** Local development with Supabase CLI.

```bash
# Start local Supabase stack
supabase start

# Apply migrations and seed data
supabase db reset

# Local URLs
SUPABASE_URL=http://127.0.0.1:54321
APP_URL=http://localhost:3000
```

**Services available locally:**
- API: http://127.0.0.1:54321
- Studio: http://127.0.0.1:54323
- Inbucket (email): http://127.0.0.1:54324

## Testing

**Purpose:** Integration testing, QA, and pre-release validation.

- Separate Supabase project
- Test payment provider keys (Stripe test mode)
- Test OCR provider credentials
- Subdomain URLs: `test-*.receipt24.com`

## Production

**Purpose:** Live user-facing deployment.

- Dedicated Supabase production project
- Production payment, OCR, and email credentials
- Domain URLs: `*.receipt24.com`
- `APP_DEBUG=false`, `LOG_LEVEL=warn`

## Configuration Checklist

Before each environment is operational:

- [ ] Supabase project created
- [ ] Migrations applied (`supabase db push`)
- [ ] Seed data loaded (dev/test only)
- [ ] Auth providers configured (Google, Apple)
- [ ] Storage buckets created (via migration)
- [ ] Email service configured (Resend/SendGrid)
- [ ] OCR provider API key set
- [ ] Stripe keys configured
- [ ] Firebase project for push notifications
- [ ] PostHog analytics key set
- [ ] Custom domain DNS configured
- [ ] SSL certificates provisioned
- [ ] Privacy Policy and Terms content loaded
- [ ] Backup schedule configured

## Secrets Management

| Secret | Where Stored |
|--------|-------------|
| `SUPABASE_ANON_KEY` | App `.env` (safe for frontend) |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Functions env only |
| `STRIPE_SECRET_KEY` | Edge Functions env only |
| `OCR_API_KEY` | Edge Functions env only |
| `EMAIL_API_KEY` | Edge Functions env only |
| `FIREBASE_SERVICE_ACCOUNT` | Edge Functions secrets file |

Never commit real secrets. Use `.env.example` as documentation only.
