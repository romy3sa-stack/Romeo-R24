#!/usr/bin/env bash
# Receipt24 Supabase setup — link a cloud project or start local stack.
#
# Cloud setup (production / staging):
#   export SUPABASE_ACCESS_TOKEN=sbp_...
#   export SUPABASE_PROJECT_REF=your-project-ref
#   ./scripts/setup-supabase.sh cloud
#
# Local development (requires Docker):
#   ./scripts/setup-supabase.sh local
#
# Create a new cloud project:
#   export SUPABASE_ACCESS_TOKEN=sbp_...
#   export SUPABASE_ORG_ID=your-org-id
#   export SUPABASE_PROJECT_NAME=receipt24-production
#   export SUPABASE_DB_PASSWORD=your-secure-password
#   ./scripts/setup-supabase.sh create

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODE="${1:-}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

require_var() {
  if [[ -z "${!1:-}" ]]; then
    echo "Missing required environment variable: $1" >&2
    exit 1
  fi
}

setup_local() {
  require_cmd supabase
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required for local Supabase. Install Docker Desktop:" >&2
    echo "  https://docs.docker.com/get-docker/" >&2
    exit 1
  fi

  echo "==> Starting local Supabase stack..."
  cd supabase
  supabase start

  echo ""
  echo "==> Applying migrations and seed data..."
  supabase db reset

  echo ""
  echo "==> Local Supabase is ready."
  supabase status

  echo ""
  echo "Next steps:"
  echo "  1. Copy the API URL and anon key from above into app .env files"
  echo "  2. Run: export SUPABASE_URL=<url> SUPABASE_ANON_KEY=<key>"
  echo "  3. Run: bash scripts/inject-env.sh all"
  echo "  4. Start apps: cd apps/consumer && flutter run -d chrome"
}

setup_cloud() {
  require_cmd supabase
  require_var SUPABASE_ACCESS_TOKEN
  require_var SUPABASE_PROJECT_REF

  echo "==> Linking to project $SUPABASE_PROJECT_REF..."
  cd supabase
  supabase link --project-ref "$SUPABASE_PROJECT_REF"

  cd "$ROOT"
  echo "==> Deploying migrations and edge functions..."
  bash scripts/deploy-supabase.sh

  echo ""
  echo "==> Fetching project API keys..."
  supabase projects api-keys --project-ref "$SUPABASE_PROJECT_REF" -o table || true

  echo ""
  echo "Cloud setup complete. Configure app .env files:"
  echo "  export SUPABASE_URL=https://${SUPABASE_PROJECT_REF}.supabase.co"
  echo "  export SUPABASE_ANON_KEY=<anon-key-from-dashboard>"
  echo "  bash scripts/inject-env.sh all"
  echo ""
  echo "Then configure in Supabase Dashboard:"
  echo "  - Authentication → URL Configuration (redirect URLs)"
  echo "  - Authentication → Providers (Google, Apple)"
  echo "  - Edge Functions → Secrets (Stripe, Resend, OCR)"
}

create_project() {
  require_cmd supabase
  require_var SUPABASE_ACCESS_TOKEN
  require_var SUPABASE_ORG_ID
  require_var SUPABASE_DB_PASSWORD

  local name="${SUPABASE_PROJECT_NAME:-receipt24-production}"
  local region="${SUPABASE_REGION:-us-east-1}"

  echo "==> Creating Supabase project: $name (region: $region)..."
  local output
  output=$(supabase projects create "$name" \
    --org-id "$SUPABASE_ORG_ID" \
    --db-password "$SUPABASE_DB_PASSWORD" \
    --region "$region" \
    -o json)

  local ref
  ref=$(echo "$output" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)

  if [[ -z "$ref" ]]; then
    echo "$output"
    echo "Could not parse project ref. Create manually at https://supabase.com/dashboard" >&2
    exit 1
  fi

  echo "==> Created project ref: $ref"
  export SUPABASE_PROJECT_REF="$ref"
  setup_cloud
}

case "$MODE" in
  local) setup_local ;;
  cloud) setup_cloud ;;
  create) create_project ;;
  *)
    cat <<EOF
Receipt24 Supabase Setup

Usage:
  ./scripts/setup-supabase.sh local    Start local Supabase (Docker required)
  ./scripts/setup-supabase.sh cloud    Link + deploy to existing cloud project
  ./scripts/setup-supabase.sh create   Create new cloud project + deploy

Environment variables:
  SUPABASE_ACCESS_TOKEN   Personal access token (https://supabase.com/dashboard/account/tokens)
  SUPABASE_PROJECT_REF    Project reference ID (cloud mode)
  SUPABASE_ORG_ID         Organization ID (create mode)
  SUPABASE_DB_PASSWORD    Database password (create mode)
  SUPABASE_PROJECT_NAME   Project name (create mode, default: receipt24-production)
  SUPABASE_REGION         AWS region (create mode, default: us-east-1)

EOF
    exit 1
    ;;
esac
