#!/usr/bin/env bash
# Applies the Receipt24 schema to a LOCAL, throwaway Postgres database for
# testing purposes (creates auth/storage stubs first, then every migration in
# order, then seed data). Not used against real Supabase projects — Supabase
# applies supabase/migrations/*.sql itself via `supabase db push` / CI.
set -euo pipefail

DB_NAME="${1:-receipt24_test}"
PSQL="sudo -u postgres psql -v ON_ERROR_STOP=1"

echo "==> Recreating database ${DB_NAME}"
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "DROP DATABASE IF EXISTS ${DB_NAME};"
sudo -u postgres psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE ${DB_NAME};"

echo "==> Loading local Supabase stubs (auth/storage/roles)"
${PSQL} -d "${DB_NAME}" -f supabase/tests/00_local_supabase_stubs.sql

echo "==> Applying migrations"
for f in supabase/migrations/*.sql; do
  echo "    - ${f}"
  ${PSQL} -d "${DB_NAME}" -f "${f}"
done

echo "==> Loading seed data"
${PSQL} -d "${DB_NAME}" -f supabase/seed.sql

echo "==> Done. Connect with: sudo -u postgres psql -d ${DB_NAME}"
