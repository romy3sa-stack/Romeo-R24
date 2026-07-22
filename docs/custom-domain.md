# Custom Domain: app.receipt24.com

Connect `app.receipt24.com` to the Next.js web app on Vercel.

**Current Vercel URL:** https://romeo-r24.vercel.app  
**Target custom domain:** https://app.receipt24.com

Supabase auth is already configured for `app.receipt24.com` (Site URL + redirect URLs).

---

## Step 1 — Add domain in Vercel

1. Open your Vercel project: **https://vercel.com/romy3sa-stacks-projects/romeo-r24** (or find **romeo-r24** in your dashboard)
2. Go to **Settings** → **Domains**
3. Click **Add** and enter: `app.receipt24.com`
4. Vercel shows the DNS records you need — keep this page open

Vercel typically asks for **one** of these:

| Type | Name | Value |
|------|------|-------|
| **CNAME** (recommended) | `app` | `cname.vercel-dns.com` |
| **A** (alternative) | `app` | `76.76.21.21` |

Use the exact values Vercel shows in your project — they may differ slightly.

---

## Step 2 — Add DNS record at your registrar

Your domain `receipt24.com` uses nameservers `shades14.rzone.de` / `docks02.rzone.de` (Strato / German hosting).

1. Log in to your domain registrar (where you manage `receipt24.com` DNS)
2. Open **DNS settings** for `receipt24.com`
3. Add a new record:

| Field | Value |
|-------|-------|
| Type | **CNAME** |
| Host / Name | `app` |
| Points to / Target | `cname.vercel-dns.com` |
| TTL | 3600 (or default) |

4. **Save** the record

> Do **not** delete existing records for the root domain (`@`) unless you know what they do — only add the `app` subdomain.

---

## Step 3 — Wait for DNS propagation

- Usually **5–30 minutes**, sometimes up to 48 hours
- Check status in Vercel → **Settings** → **Domains** (shows “Valid Configuration” when ready)
- Or test from terminal: `dig app.receipt24.com CNAME`

---

## Step 4 — Verify

When Vercel shows the domain as active:

1. Visit **https://app.receipt24.com** — Receipt24 homepage should load
2. Click **Sign in** → log in with your test user
3. Confirm you reach **/dashboard**

Test credentials (dev):

| Email | Password |
|-------|----------|
| `test@receipt24.dev` | `Receipt24Test!` |

---

## Step 5 — Redirect old Vercel URL (optional)

In Vercel → **Settings** → **Domains**, you can set `app.receipt24.com` as the **primary** domain. Vercel will redirect `romeo-r24.vercel.app` to the custom domain automatically.

---

## Supabase auth (already done)

| Setting | Value |
|---------|-------|
| Site URL | `https://app.receipt24.com` |
| Redirect URLs | `https://app.receipt24.com/**` |
| | `https://romeo-r24.vercel.app/**` |
| | `http://localhost:3000/**` |

Dashboard: https://supabase.com/dashboard/project/ivflhhxjqxcskwixaggd/auth/url-configuration

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| “Invalid Configuration” in Vercel | Double-check CNAME: `app` → `cname.vercel-dns.com` |
| DNS not propagating | Wait longer; use https://dnschecker.org for `app.receipt24.com` |
| SSL certificate pending | Vercel provisions TLS automatically once DNS is valid |
| Login redirects to wrong URL | Confirm Supabase Site URL is `https://app.receipt24.com` |
| 404 after domain works | Redeploy in Vercel; ensure Root Directory is `apps/web` |

---

## Future subdomains

| Subdomain | App | Hosting |
|-----------|-----|---------|
| `app.receipt24.com` | Next.js web portal | Vercel (this guide) |
| `accountant.receipt24.com` | Accountant Flutter web | Separate Vercel project or CDN |
| `admin.receipt24.com` | Admin Flutter web | Separate Vercel project or CDN |

See [deployment.md](deployment.md) for full multi-app hosting.
