# Deploy Receipt24 Now

Step-by-step deployment for project **`ivflhhxjqxcskwixaggd`**.

**Live production URL:** https://romeo-r24.vercel.app

---

## Part 0 — One-time Supabase settings (before testing login)

### Disable email confirmation (recommended for dev/testing)

Open: **https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd/auth/providers**

Under **Email**, turn **off** “Confirm email” (or create users with **Auto Confirm User** in the Users tab).

Without this, new sign-ups cannot log in until they confirm their email.

---

## Part 1 — Database & backend (10 min)

### 1. Get a Supabase access token

Open: **https://supabase.com/dashboard/account/tokens**

Create a token and copy it.

### 2. Run the deploy script

In your terminal:

```bash
git clone https://github.com/romy3sa-stack/Romeo-R24.git
cd Romeo-R24

export SUPABASE_ACCESS_TOKEN=sbp_paste_your_token_here
export SUPABASE_PROJECT_REF=ivflhhxjqxcskwixaggd

./scripts/setup-supabase.sh cloud
```

This applies all database tables, security rules, and 7 edge functions.

---

## Part 2 — Web app on Vercel (5 min)

### 1. Import the project

Open: **https://vercel.com/new/import?s=https://github.com/romy3sa-stack/Romeo-R24**

- **Import Git Repository:** `romy3sa-stack/Romeo-R24`
- **Root Directory:** `apps/web` ← important
- **Framework:** Next.js (auto-detected)

### 2. Add environment variables

In Vercel project settings → Environment Variables:

| Name | Value |
|------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://ivflhhxjqxcskwixaggd.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_...` (your key) |

### 3. Deploy

Click **Deploy**. Vercel gives you a URL like `https://romeo-r24.vercel.app` (current production).

---

## Part 3 — Connect auth (2 min)

### 1. Add Vercel URL to Supabase

Open: **https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd/auth/url-configuration**

| Field | Value |
|-------|-------|
| Site URL | `https://romeo-r24.vercel.app` |
| Redirect URLs | `https://romeo-r24.vercel.app/**` |

### 2. Create a test user

Open: **https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd/auth/users**

- Add user → email + password → **Auto Confirm User**

### 3. Test

1. Visit your Vercel URL
2. Click **Sign in**
3. Log in with the test user
4. You should land on `/dashboard`

---

## Quick links

| Resource | URL |
|----------|-----|
| Supabase project | https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd |
| Auth URL config | https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd/auth/url-configuration |
| Users | https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd/auth/users |
| Vercel new project | https://vercel.com/new |
| GitHub repo | https://github.com/romy3sa-stack/Romeo-R24 |

---

## Optional — GitHub Actions auto-deploy

After first Vercel deploy, add these GitHub secrets (**Settings → Secrets → Actions**):

| Secret | Where to find it |
|--------|------------------|
| `VERCEL_TOKEN` | Vercel → Settings → Tokens |
| `VERCEL_ORG_ID` | Vercel project → Settings → General |
| `VERCEL_PROJECT_ID` | Vercel project → Settings → General |
| `NEXT_PUBLIC_SUPABASE_URL` | `https://ivflhhxjqxcskwixaggd.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Your publishable key |
| `SUPABASE_ACCESS_TOKEN` | Supabase account tokens |
| `SUPABASE_PROJECT_REF` | `ivflhhxjqxcskwixaggd` |

Pushes to `main` that touch `apps/web/` will auto-deploy via `.github/workflows/deploy-nextjs-vercel.yml`.

---

## Flutter apps (later)

The consumer, accountant, and admin Flutter apps deploy separately:

```bash
bash scripts/inject-env.sh all
bash scripts/build-web.sh all
```

See [deployment.md](deployment.md) for Docker/nginx hosting on custom domains.
