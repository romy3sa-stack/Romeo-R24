# Receipt24 — Production Status

**Last verified:** 22 July 2026  
**Environment:** Production  
**Supabase project:** `ivflhhxjqxcskwixaggd`

---

## Live URLs

| Service | URL | Status |
|---------|-----|--------|
| Web portal (Next.js) | https://romeo-r24.vercel.app | **Live** |
| Custom domain | https://app.receipt24.com | Pending DNS |
| Supabase API | https://ivflhhxjqxcskwixaggd.supabase.co | **Live** |
| Supabase dashboard | https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd | **Live** |

---

## Test accounts

All accounts use password: `Receipt24Test!`

| Role | Email | App |
|------|-------|-----|
| Consumer | test@receipt24.dev | Web + Consumer Flutter |
| Accountant | accountant@receipt24.dev | Accountant portal |
| Super admin | admin@receipt24.dev | Admin dashboard |
| Support admin | support@receipt24.dev | Admin dashboard |

---

## Backend

| Component | Count | Status |
|-----------|-------|--------|
| Database migrations | 9 | Applied |
| Edge functions | 7 | Deployed |
| Storage buckets | 7 | Configured |
| RLS policies | All tables | Enabled |
| Reference data | Categories, countries, currencies | Seeded |

### Edge functions

| Function | Status | Notes |
|----------|--------|-------|
| get-signed-url | Live | Storage signed URLs |
| process-receipt-ocr | Live | Mock OCR (Google Vision optional) |
| send-notification | Live | In-app + optional Resend email |
| process-reminders | Live | Schedule daily cron in Supabase |
| create-checkout-session | Live | Mock mode without Stripe key |
| cancel-subscription | Live | |
| stripe-webhook | Live | No JWT (webhook endpoint) |

---

## Auth configuration

| Setting | Value |
|---------|-------|
| Site URL | `https://app.receipt24.com` |
| Redirect URLs | `app.receipt24.com/**`, `romeo-r24.vercel.app/**`, `localhost:3000/**` |
| Email confirmation | Disabled (auto-confirm for testing) |

---

## Verification

Run the automated smoke test:

```bash
export SUPABASE_ACCESS_TOKEN=sbp_...
./scripts/verify-production.sh
```

Provision or reset test users:

```bash
./scripts/provision-production.sh
```

---

## Remaining (post-MVP)

| Item | Priority | Action |
|------|----------|--------|
| Custom domain DNS | High | Add CNAME `app` → `cname.vercel-dns.com` |
| Flutter web deploy | High | `inject-env.sh all && build-web.sh all` |
| Stripe live keys | Medium | Set in Supabase secrets + webhook |
| Resend email | Medium | Set `RESEND_API_KEY` secret |
| Google Vision OCR | Medium | Set `GOOGLE_VISION_API_KEY` |
| Reminder cron | Medium | Schedule `process-reminders` daily |
| OAuth (Google/Apple) | Low | Enable in Supabase dashboard |
| Mobile native builds | Low | `flutter create` for iOS/Android |
| Legal content | Low | Replace placeholder T&C/privacy |

---

## Quick commands

```bash
# Redeploy backend
./scripts/deploy-supabase.sh

# Verify everything
./scripts/verify-production.sh

# Web app auto-deploys on push to main (apps/web/)
```
