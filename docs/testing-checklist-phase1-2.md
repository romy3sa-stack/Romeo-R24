# Phase 1-2 Testing Checklist

## Phase 1: Platform Foundation

### Project Structure
- [ ] Monorepo structure exists with `apps/`, `packages/`, `supabase/`, `docs/`
- [ ] Three app directories: consumer, accountant_portal, admin_dashboard
- [ ] Shared package `receipt24_shared` with roles and constants
- [ ] `.gitignore` excludes secrets and build artifacts
- [ ] README documents project structure and getting started

### User Roles
- [ ] Five roles defined: consumer, accountant, accounting_firm_manager, super_administrator, support_administrator
- [ ] No merchant roles exist anywhere in codebase
- [ ] `UserRole` enum in shared package matches database enum
- [ ] `RolePermissions` matrix covers all role capabilities
- [ ] `appAreaForRole()` correctly maps roles to app areas

### Authentication Architecture
- [ ] Supabase Auth configured in `config.toml`
- [ ] Email signup with confirmation enabled
- [ ] Google and Apple OAuth configured (placeholders)
- [ ] `AuthService` supports consumer and accountant registration
- [ ] `handle_new_user` trigger creates profiles on signup
- [ ] Consumer gets `consumer_profiles` + email forwarding address
- [ ] Accountant gets `accountants` row with pending status
- [ ] Route protection redirects unauthenticated users
- [ ] Environment variables documented in `.env.example`

### Application Areas (Structure Only)
- [ ] Consumer app compiles with welcome screen placeholder
- [ ] Accountant portal compiles with placeholder screen
- [ ] Admin dashboard compiles with placeholder screen
- [ ] No dashboard UI implemented (deferred to Phase 3+)

---

## Phase 2: Database Structure

### Schema
- [ ] All 22 tables created via migrations
- [ ] All enumerated types created (20+ enums)
- [ ] Foreign key relationships correct
- [ ] Indexes on frequently queried columns
- [ ] `updated_at` triggers on all applicable tables
- [ ] `handle_new_user` trigger on auth.users
- [ ] `generate_ticket_number` trigger on support_tickets
- [ ] Soft delete column on receipts (`soft_deleted_at`)
- [ ] Duplicate detection column on receipts (`is_duplicate_flagged`)

### Table Verification
- [ ] `users` — all specified fields present
- [ ] `consumer_profiles` — includes email_forwarding_address
- [ ] `accountants` — verification_status defaults to pending
- [ ] `accounting_firm_members` — permissions JSONB
- [ ] `accountant_client_access` — scope and invitation fields
- [ ] `merchants` — no auth fields, merchant_source enum
- [ ] `receipts` — all financial and OCR fields
- [ ] `receipt_items` — line item fields with warranty_period
- [ ] `receipt_uploads` — processing pipeline fields
- [ ] `receipt_categories` — tax_relevance flag
- [ ] `expense_categories` — tax_deductible and vat_eligible
- [ ] `receipt_expense_classification` — expense_type and business_percentage
- [ ] `warranties` — status and reminder fields
- [ ] `returns_and_refunds` — all request status values
- [ ] `notifications` — type and read_status
- [ ] `subscriptions` — consumer OR accountant owner constraint
- [ ] `support_tickets` — auto-generated ticket_number
- [ ] `audit_logs` — JSONB previous/new values

### Row-Level Security
- [ ] RLS enabled on all 22 tables
- [ ] Consumers can only SELECT own receipts
- [ ] Consumers cannot SELECT other users' receipts
- [ ] Accountants can SELECT approved client receipts
- [ ] Accountants cannot SELECT non-client receipts
- [ ] Accountant access respects scope (business_only, tax_related_only)
- [ ] Revoked accountant access blocks receipt SELECT
- [ ] Super administrators can access all tables
- [ ] Support administrators can access tickets and view users
- [ ] Merchants table has no auth — only data access policies
- [ ] Soft-deleted receipts hidden from consumer SELECT
- [ ] Storage bucket policies enforce user-scoped paths

### Storage
- [ ] 7 storage buckets created
- [ ] All buckets are private (public = false)
- [ ] File size limits configured per bucket
- [ ] MIME type restrictions configured
- [ ] User-scoped path policies (folder = user_id)
- [ ] Verification documents restricted to accountants + admins

### Seed Data
- [ ] 6 languages seeded (en, fr, pt, es, af, zu)
- [ ] Sample countries seeded
- [ ] Sample currencies seeded
- [ ] 16 receipt categories seeded
- [ ] 16 expense categories seeded
- [ ] Legal content placeholders seeded

### Environment Configuration
- [ ] `.env.example` documents all required variables
- [ ] `.env.development`, `.env.testing`, `.env.production` exist
- [ ] No real secrets committed to repository
- [ ] Supabase `config.toml` configured for local development

---

## Security Tests (Manual — requires running Supabase)

- [ ] Register consumer → verify `users` and `consumer_profiles` created
- [ ] Register accountant → verify `accountants` created with pending status
- [ ] Consumer A cannot query Consumer B's receipts
- [ ] Unapproved accountant cannot query client receipts
- [ ] Approved accountant can query scoped client receipts
- [ ] Revoked access blocks subsequent queries
- [ ] Role cannot be self-escalated via API
- [ ] Service role key not present in frontend code

---

## Known Limitations (Phase 1-2)

1. Flutter SDK not verified in CI — apps are structural only
2. OAuth providers require external credentials to test
3. Edge Functions not yet implemented (OCR, email import)
4. No UI beyond welcome screen placeholder
5. Logo asset is SVG placeholder — replace with provided PNG
6. Inter font files not included — uses Google Fonts fallback
