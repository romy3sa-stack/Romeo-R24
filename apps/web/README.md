# Receipt24 Web (Next.js)

SSR web portal for Receipt24 with Supabase authentication via `@supabase/ssr`.

## Setup

```bash
cd apps/web
cp .env.local.example .env.local
# Edit .env.local with your Supabase URL and publishable (or anon) key

npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Routes

| Route | Description |
|-------|-------------|
| `/` | Landing page |
| `/login` | Email/password sign-in |
| `/dashboard` | Protected dashboard (requires auth) |
| `/auth/callback` | OAuth / PKCE callback handler |
| `/auth/signout` | Sign-out endpoint |

## Supabase SSR

- **Browser client:** `src/lib/supabase/client.ts`
- **Server client:** `src/lib/supabase/server.ts`
- **Middleware:** `src/middleware.ts` refreshes sessions and protects `/dashboard`

## Production

```bash
npm run build
npm run start
```

Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (or `NEXT_PUBLIC_SUPABASE_ANON_KEY`) in your hosting provider (Vercel, etc.).

Add your production URL to Supabase **Authentication → URL Configuration**.
