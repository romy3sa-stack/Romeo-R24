#!/usr/bin/env bash
# Generate app .env files from environment variables (CI or local).
# Usage: ./scripts/inject-env.sh [consumer|accountant|admin|all]

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_var() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

write_consumer_env() {
  require_var SUPABASE_URL
  require_var SUPABASE_ANON_KEY
  cat >"$ROOT/apps/consumer/.env" <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
APP_ENV=${APP_ENV:-production}
POSTHOG_API_KEY=${POSTHOG_API_KEY:-}
POSTHOG_HOST=${POSTHOG_HOST:-https://app.posthog.com}
EOF
  echo "Wrote apps/consumer/.env"
}

write_accountant_env() {
  require_var SUPABASE_URL
  require_var SUPABASE_ANON_KEY
  cat >"$ROOT/apps/accountant_portal/.env" <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
APP_ENV=${APP_ENV:-production}
POSTHOG_API_KEY=${POSTHOG_API_KEY:-}
POSTHOG_HOST=${POSTHOG_HOST:-https://app.posthog.com}
EOF
  echo "Wrote apps/accountant_portal/.env"
}

write_admin_env() {
  require_var SUPABASE_URL
  require_var SUPABASE_ANON_KEY
  cat >"$ROOT/apps/admin_dashboard/.env" <<EOF
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
APP_ENV=${APP_ENV:-production}
POSTHOG_API_KEY=${POSTHOG_API_KEY:-}
POSTHOG_HOST=${POSTHOG_HOST:-https://app.posthog.com}
EOF
  echo "Wrote apps/admin_dashboard/.env"
}

target="${1:-all}"

case "$target" in
  consumer) write_consumer_env ;;
  accountant) write_accountant_env ;;
  admin) write_admin_env ;;
  all)
    write_consumer_env
    write_accountant_env
    write_admin_env
    ;;
  *)
    echo "Usage: $0 [consumer|accountant|admin|all]" >&2
    exit 1
    ;;
esac
