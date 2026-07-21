# Phase 18 Testing Checklist

## Supabase Production Setup
- [ ] Production Supabase project created
- [ ] `supabase link` succeeds with project ref
- [ ] `scripts/deploy-supabase.sh` pushes all migrations
- [ ] All 7 edge functions deployed successfully
- [ ] Edge function secrets set (Stripe, Resend, OCR)
- [ ] No seed data loaded in production

## Auth & Domains
- [ ] Site URL set to `https://app.receipt24.com`
- [ ] Redirect URLs include all three app domains
- [ ] Deep link `receipt24://login-callback` configured
- [ ] Google OAuth works on production domain
- [ ] Apple OAuth works on production domain
- [ ] Email confirmation emails send via Resend

## Flutter Web Builds
- [ ] `scripts/inject-env.sh all` writes app `.env` files
- [ ] `scripts/build-web.sh all` completes without errors
- [ ] Consumer build output in `build/web/consumer`
- [ ] Accountant build output in `build/web/accountant`
- [ ] Admin build output in `build/web/admin`
- [ ] `.env` values embedded via flutter_dotenv assets

## Docker / nginx
- [ ] `docker compose -f deploy/docker/docker-compose.yml up` serves apps
- [ ] SPA routing works (refresh on `/home` does not 404)
- [ ] Static assets cached with long expiry
- [ ] Security headers present (X-Frame-Options, etc.)

## DNS & SSL
- [ ] `app.receipt24.com` resolves correctly
- [ ] `accountant.receipt24.com` resolves correctly
- [ ] `admin.receipt24.com` resolves correctly
- [ ] Valid TLS certificates on all domains

## CI/CD
- [ ] `ci.yml` passes on PR (shared tests + analyze)
- [ ] `deploy-backend.yml` deploys on manual dispatch
- [ ] `deploy-web.yml` uploads build artifacts
- [ ] GitHub secrets configured for production environment

## Analytics (PostHog)
- [ ] `POSTHOG_API_KEY` set in production app `.env`
- [ ] `app_open` event tracked on load
- [ ] User `identify` called after login
- [ ] Analytics no-ops gracefully when key is empty

## End-to-End Smoke Tests
- [ ] Consumer: register → verify email → onboarding → home
- [ ] Consumer: scan/upload receipt → appears in wallet
- [ ] Accountant: login → clients list → view client receipts
- [ ] Admin: login → verify pending accountant → dashboard stats
- [ ] Stripe checkout creates subscription (test mode first)
- [ ] Stripe webhook updates subscription status

## Security
- [ ] `APP_DEBUG=false` in production
- [ ] Service role key not in frontend builds
- [ ] RLS policies enforced on production data
- [ ] Signed URL function requires authentication
