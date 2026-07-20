# Authentication Architecture

## Provider

Supabase Auth handles all authentication with the following methods:

| Method | Status | Notes |
|--------|--------|-------|
| Email + Password | ✅ Configured | Email verification required |
| Google OAuth | ✅ Configured | Requires provider credentials |
| Apple OAuth | ✅ Configured | Requires provider credentials |
| Phone OTP | 🔜 Phase 3 | Optional mobile verification |

## Auth Flow

```
User signs up
    │
    ▼
Supabase Auth creates auth.users record
    │
    ▼
Trigger: handle_new_user()
    ├── Creates public.users row with role
    ├── Consumer → creates consumer_profiles + email forwarding address
    └── Accountant → creates accountants row, sets account_status = pending
    │
    ▼
Email verification sent (consumers)
    │
    ▼
Client loads role from public.users via authStateProvider
    │
    ▼
Router redirects to correct app area based on role
```

## Role Assignment

Roles are set during registration via `raw_user_meta_data.role`:

```dart
await supabase.auth.signUp(
  email: email,
  password: password,
  data: {'role': 'consumer', 'full_name': fullName, ...},
);
```

The database trigger reads this metadata and creates the appropriate profile. Roles cannot be self-escalated — only super administrators can change roles via the admin dashboard.

## Session Management

- JWT expiry: 3600 seconds (1 hour)
- Refresh token rotation: enabled
- PKCE auth flow for mobile apps
- Session state managed via `authStateProvider` (Riverpod StreamProvider)

## Route Protection

`GoRouter` redirect logic in `app_router.dart`:

1. Unauthenticated users → `/welcome`
2. Authenticated users on auth routes → role-based home route
3. Role-to-area mapping via `appAreaForRole()`

## Accountant Verification Gate

Accountants register with `account_status = pending` and `verification_status = pending`. They cannot access client data until a super administrator approves their verification documents.

## Security Measures (Phase 13 prep)

- Password hashing: handled by Supabase Auth (bcrypt)
- MFA: Supabase Auth TOTP (Phase 13)
- Rate limiting: Supabase built-in + Edge Function middleware
- Login alerts: audit_logs + notifications (Phase 10)
- Device management: auth.sessions table (Phase 13)

## Environment Variables

| Variable | Scope | Purpose |
|----------|-------|---------|
| `SUPABASE_URL` | Frontend | API endpoint |
| `SUPABASE_ANON_KEY` | Frontend | Public API key (RLS-protected) |
| `SUPABASE_SERVICE_ROLE_KEY` | Server only | Bypasses RLS for admin operations |
| `SUPABASE_JWT_SECRET` | Server only | JWT verification in Edge Functions |

**Never expose `SUPABASE_SERVICE_ROLE_KEY` in frontend code.**
