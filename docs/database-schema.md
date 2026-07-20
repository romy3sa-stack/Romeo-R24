# Database Schema

## Entity Relationship Diagram

```
auth.users (Supabase Auth)
    │
    │ 1:1
    ▼
users ─────────────────────────────────────────────────────────┐
    │                                                          │
    ├── 1:1 ── consumer_profiles                               │
    │                                                          │
    ├── 1:1 ── accountants ──┬── 1:N ── accounting_firm_members │
    │                        │                                  │
    │                        └── 1:N ── accountant_client_access│
    │                                    (→ consumer users)     │
    │                                                          │
    ├── 1:N ── receipts ──┬── 1:N ── receipt_items             │
    │                     ├── 1:1 ── receipt_expense_classification
    │                     ├── 1:N ── warranties               │
    │                     └── 1:N ── returns_and_refunds        │
    │                                                          │
    ├── 1:N ── receipt_uploads                                 │
    ├── 1:N ── notifications                                   │
    ├── 1:N ── subscriptions                                   │
    ├── 1:N ── support_tickets                                 │
    └── 1:N ── audit_logs                                      │
                                                               │
merchants (no user account) ◄── N:1 ── receipts                │
    ▲                                                          │
    └── created_by_user_id (optional, SET NULL on delete)      │
                                                               │
receipt_categories ◄── N:1 ── receipts                         │
expense_categories ◄── N:1 ── receipt_expense_classification   │
```

## Tables

### users

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | FK → auth.users(id) |
| full_name | TEXT | Required |
| email | TEXT | Unique |
| phone_number | TEXT | Optional |
| profile_photo_url | TEXT | Storage path |
| role | user_role | Default: consumer |
| preferred_language | TEXT | Default: en |
| country | TEXT | |
| currency | TEXT | Default: USD |
| timezone | TEXT | Default: UTC |
| account_status | account_status | Default: active |
| email_verified | BOOLEAN | |
| phone_verified | BOOLEAN | |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | Auto-updated |

### consumer_profiles

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK | Unique → users(id) |
| tax_profile_enabled | BOOLEAN | |
| accountant_sharing_enabled | BOOLEAN | |
| default_expense_type | expense_type | |
| notification_preferences | JSONB | Push, email, SMS settings |
| marketing_consent | BOOLEAN | |
| email_forwarding_address | TEXT | Unique, e.g. user@receipts.receipt24.com |
| onboarding_completed | BOOLEAN | |
| onboarding_interests | TEXT[] | |

### accountants

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK | Unique → users(id) |
| firm_name | TEXT | Required |
| professional_registration_number | TEXT | |
| tax_number | TEXT | |
| country | TEXT | |
| address | TEXT | |
| phone_number | TEXT | |
| verification_status | verification_status | Default: pending |
| verification_document_url | TEXT | Storage path |
| subscription_plan | TEXT | |

### accounting_firm_members

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| accountant_id | UUID FK | → accountants(id) |
| user_id | UUID FK | → users(id) |
| firm_role | firm_role | manager, accountant, viewer |
| permissions | JSONB | Granular permission flags |
| account_status | account_status | |

### accountant_client_access

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| accountant_id | UUID FK | → accountants(id) |
| consumer_user_id | UUID FK | → users(id) |
| access_status | access_status | pending, approved, revoked |
| access_scope | access_scope | all, business, tax, categories, date range |
| scope_config | JSONB | Category/date range details |
| invitation_token | TEXT | Unique |
| approved_at | TIMESTAMPTZ | |
| revoked_at | TIMESTAMPTZ | |

### merchants

**No user accounts.** Receipt data only.

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| merchant_name | TEXT | Required |
| trading_name | TEXT | |
| business_category | TEXT | |
| tax_number | TEXT | |
| email, phone, website | TEXT | |
| address, city, province, postal_code, country | TEXT | |
| latitude, longitude | DECIMAL | |
| logo_url | TEXT | |
| merchant_source | merchant_source | ocr_scan, manual_entry, etc. |
| verification_status | verification_status | |
| created_by_user_id | UUID FK | → users(id), nullable |

### receipts

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| consumer_user_id | UUID FK | → users(id) |
| merchant_id | UUID FK | → merchants(id), nullable |
| merchant_name_raw | TEXT | OCR-extracted name |
| receipt_number | TEXT | |
| transaction_reference | TEXT | |
| transaction_date | DATE | |
| subtotal, tax_amount, discount_amount, total_amount | DECIMAL | |
| currency | TEXT | |
| payment_method | payment_method | |
| receipt_source | receipt_source | camera_scan, image_upload, etc. |
| receipt_status | receipt_status | draft, processing, confirmed, etc. |
| receipt_file_url | TEXT | PDF storage path |
| receipt_image_url | TEXT | Image storage path |
| receipt_category_id | UUID FK | → receipt_categories(id) |
| ocr_status | ocr_status | |
| ocr_confidence_score | DECIMAL | 0-100 |
| verification_status | verification_status | |
| warranty_available | BOOLEAN | |
| return_deadline | DATE | |
| notes | TEXT | |
| is_duplicate_flagged | BOOLEAN | |
| duplicate_of_receipt_id | UUID FK | Self-reference |
| soft_deleted_at | TIMESTAMPTZ | Soft delete |

### receipt_items

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| receipt_id | UUID FK | → receipts(id) CASCADE |
| item_name | TEXT | Required |
| quantity | DECIMAL | Default: 1 |
| unit_price, tax_rate, tax_amount, discount_amount, total_price | DECIMAL | |
| serial_number | TEXT | |
| warranty_period | INTEGER | Days |

### receipt_uploads

| Column | Type | Notes |
|--------|------|-------|
| id | UUID PK | |
| user_id | UUID FK | → users(id) |
| file_url | TEXT | |
| file_type | file_type | |
| upload_source | upload_source | |
| ocr_status | ocr_status | |
| ocr_raw_text | TEXT | |
| processing_status | processing_status | |
| linked_receipt_id | UUID FK | → receipts(id) |

### receipt_categories / expense_categories

Managed by administrators. See seed data for initial categories.

### receipt_expense_classification

| Column | Type | Notes |
|--------|------|-------|
| receipt_id | UUID FK | Unique → receipts(id) |
| expense_category_id | UUID FK | → expense_categories(id) |
| expense_type | expense_type | personal, business, mixed_use |
| business_percentage | DECIMAL | For mixed use |
| classification_source | classification_source | |
| confidence_score | DECIMAL | |
| user_confirmed | BOOLEAN | |

### warranties / returns_and_refunds / notifications / subscriptions / support_tickets / audit_logs

See migration files for full column definitions.

### Content tables

- `countries` — country codes and names
- `currencies` — currency codes and symbols
- `languages` — supported language codes
- `legal_content` — Terms, Privacy Policy per language
- `notification_templates` — email/push templates

## Enumerated Types

See `20250720000001_extensions_and_enums.sql` for all 20+ enum types.

## Indexes

Key indexes on:
- `receipts(consumer_user_id, transaction_date, receipt_status)`
- `receipts(is_duplicate_flagged)` partial
- `accountant_client_access(accountant_id, consumer_user_id)`
- `audit_logs(record_type, record_id, created_at)`
- `notifications(user_id, read_status)` partial

## Triggers

- `handle_updated_at` — auto-updates `updated_at` on all tables
- `handle_new_user` — creates profile on auth signup
- `generate_ticket_number` — auto-generates support ticket numbers
