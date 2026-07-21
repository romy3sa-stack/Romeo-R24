# Phase 13–16 Testing Checklist

## Phase 13 — Security

### Login audit & devices
- [ ] Successful login inserts `login` row in `audit_logs`
- [ ] Login upserts row in `user_devices` with platform label
- [ ] Security screen shows login history (most recent first)
- [ ] Security screen lists active devices
- [ ] Empty states when no history or devices

### Signed URLs
- [ ] `get-signed-url` edge function requires auth header
- [ ] Returns signed URL for valid bucket/path
- [ ] Rejects unauthenticated requests (401)
- [ ] `SecurityService.getSignedUrl` parses response correctly

### MFA placeholder
- [ ] Security screen shows MFA card with “coming soon” label
- [ ] Profile → Security navigation works

## Phase 14 — Internationalization

### Locale persistence
- [ ] Language selection persists across app restarts (SharedPreferences)
- [ ] Changing language in profile updates `users.preferred_language`
- [ ] All three apps use shared `localeProvider`

### Translations
- [ ] English strings resolve for all keys
- [ ] French includes phases 8–15 keys (warranties, subscriptions, admin, security)
- [ ] pt/es/af/zu override core UI labels; English fallback for remaining keys

## Phase 15 — UI polish

### Theme mode
- [ ] Theme selector in consumer, accountant, and admin profile screens
- [ ] System / Light / Dark options persist across restarts
- [ ] Dark theme renders correctly in all three apps

### Shared state views
- [ ] Receipt wallet empty state uses `EmptyStateView`
- [ ] Notifications empty/error states use shared widgets
- [ ] Accountant clients empty/error states use shared widgets
- [ ] Admin audit logs empty/error states use shared widgets

## Phase 16 — Testing & documentation

### Unit tests (`packages/receipt24_shared/test/`)
- [ ] `l10n_test.dart` — EN/FR/PT/ZU translations
- [ ] `models_test.dart` — `AuditLogModel.fromJson`
- [ ] `app_preferences_test.dart` — locale and theme persistence

### Regression
- [ ] Auth, onboarding, and navigation still work after provider migration
- [ ] No hard-coded user-facing strings in new security/appearance UI

## Security (RLS)
- [ ] `user_devices` SELECT limited to own rows (or admin)
- [ ] `user_devices` INSERT/UPDATE limited to `auth.uid()`
- [ ] Signed URL function validates caller before issuing URL
