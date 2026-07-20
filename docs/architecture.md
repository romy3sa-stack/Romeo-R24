# Receipt24 Architecture

## Overview

Receipt24 is a monorepo containing three Flutter applications sharing a common Supabase backend. The architecture follows a mobile-first, API-driven design with strict role-based access control.

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
├──────────────┬────────────────────┬─────────────────────────┤
│ Consumer App │ Accountant Portal  │ Admin Dashboard         │
│ (Flutter)    │ (Flutter Web)      │ (Flutter Web)           │
└──────┬───────┴─────────┬──────────┴──────────┬──────────────┘
       │                 │                      │
       └─────────────────┼──────────────────────┘
                         │
              ┌──────────▼──────────┐
              │   Supabase Client   │
              │  (supabase_flutter) │
              └──────────┬──────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                     Supabase Platform                        │
├──────────┬──────────┬──────────┬──────────┬────────────────┤
│   Auth   │ Database │ Storage  │ Realtime │ Edge Functions │
│          │ (PG+RLS) │ (Private)│          │ (OCR, Email)   │
└──────────┴──────────┴──────────┴──────────┴────────────────┘
```

## Application Areas

### Consumer App (`apps/consumer`)

Target users: individual consumers managing personal and business receipts.

Capabilities (planned):
- Receipt capture (camera, upload, PDF, email, manual)
- Expense categorisation and classification
- Warranty and return tracking
- Spending insights
- Accountant sharing
- Subscription management

### Accountant Portal (`apps/accountant_portal`)

Target users: professional accountants and accounting firm managers.

Capabilities (planned):
- Client invitation and access management
- Authorised receipt viewing and classification
- VAT and business expense identification
- Report generation and export
- Document requests

### Admin Dashboard (`apps/admin_dashboard`)

Target users: super administrators and support administrators.

Capabilities (planned):
- User management (consumers, accountants)
- Accountant verification
- Category and content management
- OCR monitoring
- Subscription management
- Support ticket handling
- Audit log review

## Shared Package (`packages/receipt24_shared`)

Contains cross-app code:
- User roles and permissions matrix
- Brand constants (colours, typography, spacing)
- Shared data models (future phases)
- Translation keys (Phase 14)

## Data Flow

1. User authenticates via Supabase Auth
2. `handle_new_user` trigger creates `public.users` row and role-specific profile
3. Client requests data through Supabase client with JWT
4. PostgreSQL RLS policies enforce access based on role and relationships
5. File uploads go to private storage buckets with user-scoped paths
6. Edge Functions handle OCR, email import, and notifications (future phases)

## Merchant Data Model

Merchants are **not users**. The `merchants` table stores extracted receipt data only:

- Created via OCR scan, manual entry, email import, or admin action
- No passwords, subscriptions, dashboards, or permissions
- Linked to receipts via `receipts.merchant_id`
- Raw merchant name preserved in `receipts.merchant_name_raw`

## Deployment Targets

| Environment | Consumer | Accountant | Admin | API |
|-------------|----------|------------|-------|-----|
| Development | localhost:3000 | localhost:3001 | localhost:3002 | localhost:54321 |
| Testing | test-app.receipt24.com | test-accountant.receipt24.com | test-admin.receipt24.com | test-api |
| Production | app.receipt24.com | accountant.receipt24.com | admin.receipt24.com | api.receipt24.com |
