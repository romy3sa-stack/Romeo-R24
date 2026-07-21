-- Receipt24 · Phase 2 · Migration 01
-- Extensions required by the schema.

create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "pg_trgm";    -- fuzzy text search (merchant / item search)
create extension if not exists "citext";     -- case-insensitive email storage
