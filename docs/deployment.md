# Receipt24 Production Deployment Guide

This guide covers deploying Receipt24 to production: Supabase backend, Flutter web builds, domain configuration, and CI/CD.

## Architecture Overview

```
                    ┌─────────────────────────────────────┐
                    │           DNS / CDN / SSL           │
                    └─────────────────────────────────────┘
                      │              │              │
           app.receipt24.com   accountant.*      admin.*
                      │              │              │
                    ┌─────────────────────────────────────┐
                    │   nginx (deploy/docker/Dockerfile)  │
                    │   /var/www/consumer|accountant|admin│
                    └─────────────────────────────────────┘
                                      │
                    ┌─────────────────────────────────────┐
                    │     Supabase (production project)    │
                    │  PostgreSQL · Auth · Storage · Edge  │
                    └─────────────────────────────────────┘
```

| Component | URL | Build output |
|-----------|-----|--------------|
| Consumer app | `https://app.receipt24.com` | `build/web/consumer` |
| Accountant portal | `https://accountant.receipt24.com` | `build/web/accountant` |
| Admin dashboard | `https://admin.receipt24.com` | `build/web/admin` |
| Supabase API | `https://<project-ref>.supabase.co` | — |

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) logged in
- [Flutter SDK](https://flutter.dev) 3.16+ with web enabled
- Docker (optional, for local nginx smoke test)
- DNS access for `*.receipt24.com`
- GitHub repository secrets configured (for CI/CD)

## 1. Create Production Supabase Project

1. Create a new project at [supabase.com/dashboard](https://supabase.com/dashboard)
2. Note the **project ref**, **URL**, and **anon key**
3. Link locally:

```bash
cd supabase
supabase link --project-ref <your-project-ref>
```

4. Deploy schema and functions:

```bash
# From repo root — set secrets first (see section 3)
export SUPABASE_ACCESS_TOKEN=...
export STRIPE_SECRET_KEY=...
export RESEND_API_KEY=...
bash scripts/deploy-supabase.sh
```

## 2. Configure Auth Redirect URLs

In **Supabase Dashboard → Authentication → URL Configuration**, set:

| Setting | Value |
|---------|-------|
| Site URL | `https://app.receipt24.com` |
| Redirect URLs | `https://app.receipt24.com/**` |
| | `https://accountant.receipt24.com/**` |
| | `https://admin.receipt24.com/**` |
| | `receipt24://login-callback` |

Enable Google and Apple OAuth providers with production client IDs.

## 3. Edge Function Secrets

Set via CLI or Dashboard → Edge Functions → Secrets:

| Secret | Required for |
|--------|--------------|
| `STRIPE_SECRET_KEY` | Subscriptions |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhooks |
| `STRIPE_PUBLISHABLE_KEY` | Checkout sessions |
| `RESEND_API_KEY` | Email notifications |
| `EMAIL_FROM` | Sender address |
| `GOOGLE_VISION_API_KEY` | OCR processing |

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically by Supabase.

### Stripe webhook

Point Stripe webhook to:

```
https://<project-ref>.supabase.co/functions/v1/stripe-webhook
```

Events: `checkout.session.completed`, `customer.subscription.updated`, `customer.subscription.deleted`

## 4. Build Flutter Web Apps

### Inject environment

```bash
export SUPABASE_URL=https://<project-ref>.supabase.co
export SUPABASE_ANON_KEY=<anon-key>
export APP_ENV=production
export POSTHOG_API_KEY=<optional>
export POSTHOG_HOST=https://app.posthog.com

bash scripts/inject-env.sh all
```

### Build

```bash
flutter config --enable-web
bash scripts/build-web.sh all
```

Outputs land in `build/web/{consumer,accountant,admin}`.

Build a single app:

```bash
bash scripts/build-web.sh --app consumer
```

## 5. Deploy Static Web (nginx + Docker)

### Local smoke test

```bash
bash scripts/build-web.sh all
docker compose -f deploy/docker/docker-compose.yml up --build
# Visit http://localhost:8080 (add hosts entries for subdomains)
```

### Production

1. Build the Docker image in CI or locally:

```bash
docker build -f deploy/docker/Dockerfile -t receipt24-web:latest .
```

2. Push to your container registry
3. Deploy behind a load balancer with TLS termination
4. Map DNS A/CNAME records:

| Host | Points to |
|------|-----------|
| `app.receipt24.com` | Load balancer / CDN |
| `accountant.receipt24.com` | Same |
| `admin.receipt24.com` | Same |

### Alternative: CDN static hosting

Upload each `build/web/*` folder to separate buckets or paths on Cloudflare Pages, Vercel, or S3+CloudFront. Configure SPA fallback (`index.html` for all routes).

## 6. GitHub Actions CI/CD

### Required secrets

| Secret | Used by |
|--------|---------|
| `SUPABASE_ACCESS_TOKEN` | Backend deploy |
| `SUPABASE_PROJECT_REF` | Backend deploy |
| `SUPABASE_URL` | Web build |
| `SUPABASE_ANON_KEY` | Web build |
| `STRIPE_SECRET_KEY` | Backend deploy |
| `STRIPE_WEBHOOK_SECRET` | Backend deploy |
| `RESEND_API_KEY` | Backend deploy |
| `GOOGLE_VISION_API_KEY` | Backend deploy |
| `POSTHOG_API_KEY` | Web build (optional) |
| `POSTHOG_HOST` | Web build (optional) |

### Workflows

| Workflow | Trigger | Action |
|----------|---------|--------|
| `ci.yml` | PR / push to main | Tests + analyze |
| `deploy-backend.yml` | Push to `supabase/**` or manual | Migrations + edge functions |
| `deploy-web.yml` | Push to `apps/**` or manual | Flutter web build artifacts |

Manual deploy:

```
GitHub → Actions → Deploy Backend → Run workflow → production
GitHub → Actions → Deploy Web → Run workflow → production
```

## 7. Post-Deployment Checklist

- [ ] Migrations applied (`supabase db push` succeeds)
- [ ] All 7 edge functions deployed
- [ ] Auth redirect URLs configured
- [ ] OAuth providers (Google, Apple) use production credentials
- [ ] Stripe webhook receiving events
- [ ] Three web apps load at production URLs
- [ ] SSL certificates valid
- [ ] Consumer login → home flow works
- [ ] Accountant portal restricted to accountant role
- [ ] Admin dashboard restricted to admin roles
- [ ] PostHog receiving `app_open` events (if key configured)
- [ ] Privacy Policy and Terms accessible at `/legal/*`
- [ ] Database backups enabled in Supabase dashboard

## 8. Mobile Builds (Future)

Consumer app mobile releases:

```bash
cd apps/consumer
flutter build apk --release      # Android
flutter build ipa --release      # iOS (macOS + Xcode required)
```

Configure deep link `receipt24://login-callback` in Android `AndroidManifest.xml` and iOS `Info.plist` when mobile platform folders are generated via `flutter create .`.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Auth redirect loop | Verify redirect URLs in Supabase match deployed domain |
| CORS on edge functions | Functions include CORS headers; check auth header |
| Blank Flutter web page | Ensure `base-href` is `/` and nginx `try_files` includes `/index.html` |
| Stripe webhook 401 | Deploy with `--no-verify-jwt` (script handles this) |
| Missing .env in build | Run `inject-env.sh` before `build-web.sh` |

## Related Docs

- [Environments](environments.md)
- [Phase 18 Testing Checklist](testing-checklist-phase18.md)
- [Auth Architecture](auth-architecture.md)
