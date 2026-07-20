# Receipt24

Receipt24 is a receipt-management platform for consumers, accountants, and authorised administrators. Merchant information is receipt data only; merchants never have platform accounts.

## Current scope

Phase 1–2 establishes the Supabase architecture, complete relational schema, row-level security, and private storage layout. No dashboards or frontend workflows are included yet.

Start with the detailed foundation document: [`docs/phase-01-02-foundation.md`](docs/phase-01-02-foundation.md).

## Local database

1. Install the Supabase CLI and run `supabase start`.
2. Copy `.env.example` to `.env.local` and set local values.
3. Run `supabase db reset` to apply the migrations.

Never place `SUPABASE_SERVICE_ROLE_KEY` or other secret provider keys in client code.
