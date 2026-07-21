# Deploy to Vercel (Option B)

Production build verified. Follow these steps exactly.

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
| Build fails on Vercel | Ensure Root Directory is `apps/web` |
| Login redirects back to login | Add Vercel URL to Supabase redirect URLs |
| "Email not confirmed" | Auto-confirm user or disable email confirmation |
| 404 on `/dashboard` | Redeploy after env vars are set |
