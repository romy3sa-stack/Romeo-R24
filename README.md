# Receipt24

Every Receipt. One Place.

This repository contains the Phase 1–2 foundation for Receipt24: a Supabase/PostgreSQL backend shared by future consumer, accountant, and administrator applications.

## Included

- Five-role RBAC model with no merchant identity or merchant-facing capability
- Complete receipt-management relational schema and relationship constraints
- Supabase Auth profile synchronization
- Forced row-level security and accountant consent/scope enforcement
- Private storage buckets and object policies
- Soft archival and immutable audit capture for important records
- Isolated development, testing, and production environment templates
- pgTAP schema and cross-user authorization tests

No dashboards or client UI are included in this phase.

## Local setup

Requirements: Node.js 20+, a Docker-compatible runtime, and npm.

1. Run `npm install`.
2. Run `npm run db:start`.
3. Run `npm run db:reset`.
4. Run `npm test`.

`supabase/config.toml` enables confirmed email sign-up with a 10-character minimum password. Copy `.env.example` or an `environments/*.env.example` template to an ignored environment file and add only the values needed for that environment.

## Documentation

- [Architecture and authentication](docs/ARCHITECTURE.md)
- [Complete schema and relationships](docs/DATABASE.md)
- [RLS and private storage](docs/SECURITY.md)
- [Configuration and unresolved work](docs/CONFIGURATION.md)
- [Phase testing checklist](docs/TESTING_CHECKLIST.md)

The executable source of truth is `supabase/migrations`.
