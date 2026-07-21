# Receipt24

**Every Receipt. One Place.**

Receipt24 is a mobile-first SaaS platform for digital receipt management. Users can scan, upload, organise, analyse, store, share, and export receipts.

## Platform Areas

| Area | App | URL (production) | Users |
|------|-----|------------------|-------|
| Consumer App | `apps/consumer` | app.receipt24.com | Consumers |
| Accountant Portal | `apps/accountant_portal` | accountant.receipt24.com | Accountants |
| Admin Dashboard | `apps/admin_dashboard` | admin.receipt24.com | Administrators |

**Merchants do not register or use the platform.** Merchant information exists only as data extracted from receipts.

## User Roles

| Role | Access |
|------|--------|
| `consumer` | Consumer app — own receipts and data |
| `accountant` | Accountant portal — approved client receipts |
| `accounting_firm_manager` | Accountant portal + firm staff management |
| `super_administrator` | Full admin dashboard access |
| `support_administrator` | Support tickets and limited user access |

## Tech Stack

- **Frontend:** Flutter (mobile-first, responsive web)
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Auth:** Supabase Auth (email, Google, Apple)
- **Storage:** Supabase Storage (private buckets)
- **OCR:** Google Vision / AWS Textract (Phase 5)
- **Payments:** Stripe (Phase 11)
- **Notifications:** Firebase Cloud Messaging (Phase 10)
- **Email:** Resend / SendGrid (Phase 10)
- **Analytics:** PostHog (Phase 18)

## Project Structure

```
receipt24/
├── apps/
│   ├── consumer/              # Consumer mobile/web app
│   ├── accountant_portal/     # Accountant web portal
│   └── admin_dashboard/       # Super admin dashboard
├── packages/
│   └── receipt24_shared/      # Shared roles, constants, models
├── supabase/
│   ├── migrations/            # Database schema + RLS
│   ├── seed/                  # Development seed data
│   └── config.toml            # Local Supabase config
├── docs/                      # Architecture documentation
├── assets/logo/               # Brand assets
├── .env.example               # Environment variable template
├── .env.development
├── .env.testing
└── .env.production
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.16+
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- [Docker](https://www.docker.com/) (for local Supabase)

### 1. Clone and configure

```bash
cp .env.example .env
# Fill in Supabase credentials
```

### 2. Start local Supabase

```bash
cd supabase
supabase start
supabase db reset   # Applies migrations + seed data
```

### 3. Run the consumer app

```bash
cd apps/consumer
flutter pub get
flutter run
```

## Development Status

| Phase | Status | Description |
|-------|--------|-------------|
| Phase 1 | ✅ Complete | Platform foundation, roles, auth architecture |
| Phase 2 | ✅ Complete | Database schema, RLS, storage buckets |
| Phase 3 | ✅ Complete | Auth screens, onboarding, home shell |
| Phase 4 | ✅ Complete | Consumer dashboard, receipt wallet, details |
| Phase 5 | ✅ Complete | Camera, upload, PDF, manual, OCR review (mock OCR) |
| Phase 6 | ✅ Complete | Expense categories, classification, duplicate review |
| Phase 7 | ✅ Complete | Spending insights, charts, alerts, recurring detection |
| Phase 8 | ✅ Complete | Warranties, returns, reminders, deadline tracking |
| Phase 9 | ✅ Complete | Accountant portal — clients, receipts, classification |
| Phase 10+ | ⏳ Pending | Notifications, subscriptions, admin dashboard, etc. |

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Authentication Architecture](docs/auth-architecture.md)
- [Database Schema](docs/database-schema.md)
- [RLS Policies](docs/rls-policies.md)
- [Storage Structure](docs/storage-structure.md)
- [Environments](docs/environments.md)
- [Phase 1-2 Testing Checklist](docs/testing-checklist-phase1-2.md)
- [Phase 8 Testing Checklist](docs/testing-checklist-phase8.md)
- [Phase 9 Testing Checklist](docs/testing-checklist-phase9.md)

## Security

- Row-level security on all tables
- Role-based access control
- Private storage buckets with user-scoped paths
- Secrets via environment variables only
- No merchant authentication or accounts

## License

Proprietary — All rights reserved.
