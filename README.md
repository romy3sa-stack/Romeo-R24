# Receipt24

**Every Receipt. One Place.**

Receipt24 is a mobile-first SaaS platform for scanning, uploading, organising, analysing, storing, sharing, and exporting receipts.

## User groups

1. Consumers  
2. Accountants  
3. Administrators  

Merchants do **not** register, log in, subscribe, or use the platform. Merchant details exist only as data extracted from receipts.

## Current status

**Phase 1 (Platform Foundation) and Phase 2 (Database Structure) complete.**

UI dashboards are intentionally not built yet.

## Repository layout

```
apps/consumer/       Consumer Flutter app (scaffold)
apps/accountant/     Accountant portal (scaffold)
apps/admin/          Admin dashboard (scaffold)
packages/shared/     Shared roles, enums, platform constants
supabase/            Migrations, seed data, local config
config/environments/ Dev / testing / production env templates
assets/branding/     Logo + design tokens
docs/architecture/   Phase documentation
docs/testing/        Phase checklists
```

## Quick start (backend foundation)

1. Install [Supabase CLI](https://supabase.com/docs/guides/cli) and Docker.
2. Copy environment template:

   ```bash
   cp config/environments/.env.example .env
   ```

3. Start local Supabase and apply migrations + seed:

   ```bash
   supabase start
   supabase db reset
   ```

4. Put the printed anon/service keys into your local `.env` (never commit secrets).

## Documentation

- [Phase 1 foundation](docs/architecture/phase1-platform-foundation.md)
- [Phase 2 schema](docs/architecture/phase2-database-schema.md)
- [RLS policies](docs/architecture/phase2-rls-policies.md)
- [Storage](docs/architecture/phase2-storage.md)
- [Phase 1–2 completion report](docs/architecture/phase1-phase2-completion-report.md)
- [Testing checklist](docs/testing/phase1-phase2-checklist.md)

## Brand

Logo: `assets/branding/receipt24-logo.svg`  
Tokens: `assets/branding/brand-tokens.css`

## Security notes

- Service-role keys are server-only.
- RLS is enabled on all application tables.
- Soft-delete is preferred for financial records.
- Do not claim POPIA/GDPR legal compliance until reviewed by qualified professionals.
