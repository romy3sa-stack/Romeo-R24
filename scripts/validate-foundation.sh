#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Checking required paths"
required_paths=(
  apps/consumer/README.md
  apps/accountant/README.md
  apps/admin/README.md
  packages/shared/src/roles.ts
  packages/shared/src/enums.ts
  assets/branding/receipt24-logo.svg
  supabase/config.toml
  supabase/migrations/20260720000001_phase1_enums_and_helpers.sql
  supabase/migrations/20260720000002_phase2_core_tables.sql
  supabase/migrations/20260720000003_phase2_receipt_tables.sql
  supabase/migrations/20260720000004_phase2_ops_tables.sql
  supabase/migrations/20260720000005_phase2_rls_helpers.sql
  supabase/migrations/20260720000006_phase2_rls_policies.sql
  supabase/migrations/20260720000007_phase2_storage_and_auth_hooks.sql
  supabase/seed/01_reference_data.sql
  config/environments/.env.example
  docs/testing/phase1-phase2-checklist.md
)

for path in "${required_paths[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "Missing: $path" >&2
    exit 1
  fi
done

echo "==> Ensuring merchant roles are not in USER_ROLES allow-list"
# Extract USER_ROLES block and fail if any merchant_* role appears there.
user_roles_block="$(awk '/export const USER_ROLES/,/as const/' packages/shared/src/roles.ts)"
if printf '%s\n' "$user_roles_block" | rg -q 'merchant_'; then
  echo "Forbidden merchant roles appear inside USER_ROLES" >&2
  exit 1
fi
if ! rg -q "FORBIDDEN_MERCHANT_ROLES" packages/shared/src/roles.ts; then
  echo "FORBIDDEN_MERCHANT_ROLES list missing" >&2
  exit 1
fi

echo "==> Ensuring migrations mention RLS enablement"
rg -n "enable row level security" supabase/migrations/20260720000006_phase2_rls_policies.sql >/dev/null

echo "==> Ensuring merchant plans are blocked"
rg -n "subscription_plans_no_merchant_audience|audience in \\('consumer', 'accountant'\\)" \
  supabase/migrations/20260720000002_phase2_core_tables.sql >/dev/null

echo "==> Shared package typecheck (if npm deps present)"
if [[ -d node_modules/typescript ]]; then
  npm run typecheck:shared
else
  echo "Skipping typecheck (run npm install first)"
fi

echo "Foundation validation passed."
