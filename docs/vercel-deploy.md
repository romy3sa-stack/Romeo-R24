# Deploy to Vercel (Option B)

Production build verified. Follow these steps exactly.

## Fix 404 NOT_FOUND

If you see `404: NOT_FOUND` with an ID like `cpt1::...`, Vercel is serving an **empty or misconfigured build**. This repo ships a root `vercel.json` that points at `apps/web` — you should **not** override Output Directory in the dashboard.

### Fix (pick one approach)

**Option A — recommended (simplest)**

1. Vercel → **Settings** → **General** → **Root Directory** → set to `apps/web` → **Save**
2. **Settings** → **Build & Development**:
   - Framework Preset: **Next.js**
   - Build Command: `npm run build` (default)
   - Output Directory: **leave blank** (never set `.next` manually)
3. **Deployments** → latest → **⋯** → **Redeploy**

**Option B — build from repo root**

Leave Root Directory empty (`.`). The root `vercel.json` uses `@vercel/next` on `apps/web/package.json`. Still clear any custom **Output Directory** in dashboard settings, then redeploy.

### Verify settings

| Setting | Correct value |
|---------|---------------|
| Root Directory | `apps/web` (Option A) or `.` (Option B) |
| Framework | Next.js |
| Build Command | `npm run build` (Option A) or default (Option B) |
| Output Directory | **blank** — do not set `.next` or `apps/web/.next` |

### Environment variables (required)

| Name | Value |
|------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://ivflhhxjqxcskwixaggd.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | your `sb_publishable_...` key |

---

## 1. Open Vercel import

**https://vercel.com/new/import?s=https://github.com/romy3sa-stack/Romeo-R24**

(Sign in with GitHub if prompted.)

## 2. Configure the project

| Setting | Value |
|---------|-------|
| **Repository** | `romy3sa-stack/Romeo-R24` |
| **Framework Preset** | Next.js |
| **Root Directory** | `apps/web` ← click Edit, set this |
| **Build Command** | `npm run build` (default) |
| **Output Directory** | `.next` (default) |

## 3. Environment variables

Click **Environment Variables** and add:

| Name | Value |
|------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://ivflhhxjqxcskwixaggd.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_nO_uw8hpp5ZiTj3MbNPWJw_muf6hHVs` |

Apply to: **Production**, **Preview**, and **Development**.

## 4. Deploy

Click **Deploy**. Wait ~2 minutes.

You'll get a URL like: `https://romeo-r24-xxxxx.vercel.app`

## 5. Connect Supabase auth

Copy your Vercel URL, then open:

**https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd/auth/url-configuration**

| Field | Value |
|-------|-------|
| Site URL | `https://YOUR-VERCEL-URL.vercel.app` |
| Redirect URLs | `https://YOUR-VERCEL-URL.vercel.app/**` |

Also add for local dev (optional):
- `http://localhost:3000/**`

## 6. Create a test user

**https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd/auth/users**

- Add user → email + password
- Check **Auto Confirm User**

## 7. Test

1. Visit `https://YOUR-VERCEL-URL.vercel.app`
2. Click **Sign in**
3. Log in with your test user
4. You should reach `/dashboard`

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `404: NOT_FOUND` on every page | Clear Output Directory in Vercel settings; redeploy (see above) |
| `500: MIDDLEWARE_INVOCATION_FAILED` | Add both env vars below, then **Redeploy** (vars are baked in at build time) |
| Build fails on Vercel | Ensure Root Directory is `apps/web` or use root `vercel.json` |
| Login redirects back to login | Add Vercel URL to Supabase redirect URLs |
| "Email not confirmed" | Auto-confirm user or disable email confirmation |
| 404 on `/dashboard` only | Redeploy after env vars are set |

### Fix 500 MIDDLEWARE_INVOCATION_FAILED

This means the Next.js middleware crashed — almost always **missing environment variables**.

1. Vercel → **Settings** → **Environment Variables**
2. Add **both** (names must match exactly):

| Name | Value |
|------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://ivflhhxjqxcskwixaggd.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `sb_publishable_nO_uw8hpp5ZiTj3MbNPWJw_muf6hHVs` |

3. Apply to **Production**, **Preview**, and **Development**
4. **Deployments** → **Redeploy** (required after adding env vars)
