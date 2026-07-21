# Supabase Setup Guide

Quick reference for linking Receipt24 to Supabase after merging to `main`.

## Option A: Local development (recommended first)

**Requirements:** Docker Desktop, Supabase CLI

```bash
# Install Supabase CLI (if needed)
# Linux: download from https://github.com/supabase/cli/releases

./scripts/setup-supabase.sh local
```

This starts the local stack, applies all migrations, and loads seed data.

Copy the **API URL** and **anon key** from `supabase status`, then:

```bash
export SUPABASE_URL=http://127.0.0.1:54321
export SUPABASE_ANON_KEY=<anon-key-from-status>
bash scripts/inject-env.sh all
```

## Option B: Production cloud project

### 1. Get a Supabase access token

1. Go to [supabase.com/dashboard/account/tokens](https://supabase.com/dashboard/account/tokens)
2. Create a new token and copy it

### 2. Create or link a project

**Create new project:**

```bash
export SUPABASE_ACCESS_TOKEN=sbp_...
export SUPABASE_ORG_ID=<your-org-id>      # Dashboard → Organization Settings
export SUPABASE_DB_PASSWORD=<secure-password>
export SUPABASE_PROJECT_NAME=receipt24-production

./scripts/setup-supabase.sh create
```

**Link existing project:**

```bash
export SUPABASE_ACCESS_TOKEN=sbp_...
export SUPABASE_PROJECT_REF=<project-ref>  # Dashboard → Project Settings → General

./scripts/setup-supabase.sh cloud
```

### 3. Configure GitHub Actions secrets

In **GitHub → Settings → Secrets and variables → Actions**, add:

| Secret | Value |
|--------|-------|
| `SUPABASE_ACCESS_TOKEN` | Your personal access token |
| `SUPABASE_PROJECT_REF` | Project reference ID |
| `SUPABASE_URL` | `https://<ref>.supabase.co` |
| `SUPABASE_ANON_KEY` | Anon/public key from dashboard |
| `STRIPE_SECRET_KEY` | Stripe secret key |
| `STRIPE_WEBHOOK_SECRET` | Stripe webhook signing secret |
| `RESEND_API_KEY` | Resend API key |
| `GOOGLE_VISION_API_KEY` | OCR API key |

### 4. Post-setup dashboard configuration

In **Supabase Dashboard**:

1. **Authentication → URL Configuration**
   - Site URL: `https://app.receipt24.com`
   - Redirect URLs: all three app domains + `receipt24://login-callback`

2. **Authentication → Providers**
   - Enable Google and Apple with production OAuth credentials

3. **Edge Functions → Secrets**
   - Verify Stripe, Resend, and OCR keys are set

4. **Database → Backups**
   - Enable point-in-time recovery (production)

### 5. Inject app credentials

```bash
export SUPABASE_URL=https://<ref>.supabase.co
export SUPABASE_ANON_KEY=<anon-key>
bash scripts/inject-env.sh all
```

## Verify setup

```bash
# List migrations applied
cd supabase && supabase migration list

# Check edge functions
supabase functions list

# Test API
curl "https://<ref>.supabase.co/rest/v1/" \
  -H "apikey: <anon-key>"
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Access token not provided` | Run `export SUPABASE_ACCESS_TOKEN=sbp_...` |
| `Cannot find project ref` | Run `supabase link --project-ref <ref>` in `supabase/` |
| `Docker not found` | Install Docker for local mode, or use `cloud` mode |
| OAuth config error | Google/Apple are disabled in `config.toml` for local CLI; enable in Dashboard for cloud |

See also: [Deployment Guide](deployment.md) | [Environments](environments.md)
