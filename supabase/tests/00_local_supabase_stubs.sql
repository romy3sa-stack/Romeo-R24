-- =============================================================================
-- LOCAL TEST HARNESS ONLY — NOT DEPLOYED, NOT A MIGRATION.
--
-- A real Supabase project already provides the `auth` and `storage` schemas,
-- the anon/authenticated/service_role/supabase_auth_admin roles, and
-- auth.uid(). This sandbox has plain PostgreSQL only, so this script builds
-- minimal stand-ins of exactly those primitives, purely so the migrations in
-- supabase/migrations/ can be exercised end-to-end (including RLS) against a
-- local Postgres instance. Never run this against a real Supabase project.
-- =============================================================================

create schema if not exists auth;
create schema if not exists storage;

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin noinherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin noinherit bypassrls;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
    create role supabase_auth_admin login createrole;
  end if;
end;
$$;

grant all on schema auth, storage, public to supabase_auth_admin;

-- --- auth.users (columns limited to what our migrations reference) --------
create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  encrypted_password text,
  email_confirmed_at timestamptz,
  raw_user_meta_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table auth.users owner to supabase_auth_admin;

-- auth.uid(): reads the id set for the current session via set_config().
create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;

-- Convenience test helper: `select test.login('<uuid>');` switches the
-- session into that user's seat, mirroring PostgREST's per-request JWT.
create schema if not exists test;
create or replace function test.login(p_user_id uuid) returns void
language sql as $$
  select set_config('request.jwt.claim.sub', p_user_id::text, false);
$$;
create or replace function test.logout() returns void
language sql as $$
  select set_config('request.jwt.claim.sub', '', false);
$$;

-- --- storage.buckets / storage.objects (columns our migrations touch) -----
create table if not exists storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false,
  file_size_limit bigint,
  allowed_mime_types text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets (id),
  name text not null,
  owner uuid,
  metadata jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function storage.foldername(name text) returns text[]
language sql immutable as $$
  select case
    when array_length(string_to_array(name, '/'), 1) > 1
    then (string_to_array(name, '/'))[1 : array_length(string_to_array(name, '/'), 1) - 1]
    else array[]::text[]
  end;
$$;

alter table storage.buckets enable row level security;
alter table storage.objects enable row level security;
create policy stub_buckets_all on storage.buckets for all to anon, authenticated, service_role using (true) with check (true);
