-- Receipt24 · Phase 2 · Migration 03
-- Lookup / reference tables.
--
-- `receipt_categories` and `expense_categories` are defined verbatim from the
-- master spec. `countries`, `currencies` and `languages` are NOT explicitly
-- listed as tables in the spec, but are required so that
-- users.country / users.currency / users.preferred_language, accountants.country
-- and receipts.currency can be proper foreign keys instead of free-text, and
-- so that Phase 12 "manage countries and currencies" / "manage languages" has
-- something to manage. This is called out explicitly in docs/DATABASE_SCHEMA.md
-- as an inferred addition — no field on any spec-defined table was renamed or
-- removed to make room for it.

create table public.languages (
  code text primary key,               -- ISO 639-1, e.g. 'en'
  name text not null,
  native_name text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.countries (
  code text primary key,               -- ISO 3166-1 alpha-2, e.g. 'ZA'
  name text not null,
  default_currency_code text,
  phone_dial_code text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.currencies (
  code text primary key,               -- ISO 4217, e.g. 'ZAR'
  name text not null,
  symbol text not null,
  decimal_digits smallint not null default 2,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.countries
  add constraint countries_default_currency_fkey
  foreign key (default_currency_code) references public.currencies (code);

-- Receipt Categories (Phase 2 spec table)
create table public.receipt_categories (
  id uuid primary key default gen_random_uuid(),
  category_name text not null unique,
  category_icon text,
  category_colour text,
  tax_relevance boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Expense Categories (Phase 2 spec table)
create table public.expense_categories (
  id uuid primary key default gen_random_uuid(),
  category_name text not null unique,
  category_code text unique,
  tax_deductible boolean not null default false,
  vat_eligible boolean not null default false,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.languages is 'Admin-managed language list (Phase 12 / Phase 14 multilingual support). Not a spec-literal table; supports FKs from users.preferred_language.';
comment on table public.countries is 'Admin-managed country list (Phase 12). Not a spec-literal table; supports FKs from users.country and accountants.country.';
comment on table public.currencies is 'Admin-managed currency list (Phase 12). Not a spec-literal table; supports FKs from users.currency and receipts.currency.';
