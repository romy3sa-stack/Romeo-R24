# Receipt24

**Every Receipt. One Place.**

Receipt24 is a digital receipt-management platform for three user groups
only — **Consumers**, **Accountants**, and **Administrators**. Merchants
never register, log in, or hold a dashboard; merchant data exists only as
information extracted from receipts.

This repository currently implements **Phase 1 (platform foundation)** and
**Phase 2 (database schema)** only, per the build plan. No dashboards,
registration/login screens, or merchant-facing anything exist yet — see
`docs/PHASE_1_2_SUMMARY.md` for the full deliverable writeup.

## Repository layout

```
app/         Flutter app (shared codebase for Consumer App, Accountant
             Portal, Super Admin Dashboard — see app/lib/areas/)
supabase/    Postgres schema, RLS policies, storage buckets, seed data
scripts/     Local database testing helpers
docs/        Architecture, environments, schema, and testing docs
```

## Start here

- [`docs/PHASE_1_2_SUMMARY.md`](docs/PHASE_1_2_SUMMARY.md) — the full Phase
  1/2 deliverable: summary, schema, relationships, RLS policies, storage
  structure, remaining configuration, testing checklist, known issues.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — product areas, roles,
  auth architecture, technical stack.
- [`docs/ENVIRONMENTS.md`](docs/ENVIRONMENTS.md) — development/test/
  production environment structure and configuration.
- [`docs/TESTING_CHECKLIST_PHASE_1_2.md`](docs/TESTING_CHECKLIST_PHASE_1_2.md)
  — what was tested and how to re-run it.

## Quick start

**Database:**

```bash
bash scripts/db_apply_local.sh receipt24_test
sudo -u postgres psql -d receipt24_test -f supabase/tests/01_rls_scenarios.sql
```

**Flutter app:**

```bash
cd app
cp env/development.example.json env/development.json   # fill in your Supabase project
flutter pub get
flutter run --dart-define-from-file=env/development.json
```
