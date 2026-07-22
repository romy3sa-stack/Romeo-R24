#!/usr/bin/env bash
# Provision production test users and seed reference data for Receipt24.
# Requires: SUPABASE_ACCESS_TOKEN, linked project (ivflhhxjqxcskwixaggd)
#
# Usage: ./scripts/provision-production.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_REF="${SUPABASE_PROJECT_REF:-ivflhhxjqxcskwixaggd}"
SUPABASE_URL="https://${PROJECT_REF}.supabase.co"
PASSWORD="${RECEIPT24_TEST_PASSWORD:-Receipt24Test!}"

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "ERROR: SUPABASE_ACCESS_TOKEN is required" >&2
  exit 1
fi

SERVICE_KEY=$(supabase projects api-keys --project-ref "$PROJECT_REF" -o json \
  | python3 -c "import json,sys; print([k['api_key'] for k in json.load(sys.stdin) if k['name']=='service_role'][0])")

create_user() {
  local email="$1"
  local role="$2"
  local full_name="$3"
  local extra_meta="${4:-{}}"

  echo "==> User: $email ($role)"

  # Check if user exists (paginate admin list by email)
  existing=$(curl -sS -G "https://${PROJECT_REF}.supabase.co/auth/v1/admin/users" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    --data-urlencode "page=1" \
    --data-urlencode "per_page=1000" | python3 -c "
import json,sys
email=sys.argv[1]
d=json.load(sys.stdin)
for u in d.get('users',[]):
    if u.get('email','').lower()==email.lower():
        print(u['id'])
        break
" "$email" 2>/dev/null || true)

  if [[ -n "$existing" ]]; then
    echo "    Already exists ($existing)"
    user_id="$existing"
  else
    meta="{\"role\":\"$role\",\"full_name\":\"$full_name\""
    if [[ "$role" == "accountant" || "$role" == "accounting_firm_manager" ]]; then
      meta+=",\"firm_name\":\"Receipt24 Demo Firm\",\"country\":\"ZA\""
    fi
    meta+="}"

    resp=$(curl -sS -X POST "https://${PROJECT_REF}.supabase.co/auth/v1/admin/users" \
      -H "Authorization: Bearer $SERVICE_KEY" \
      -H "apikey: $SERVICE_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"$email\",\"password\":\"$PASSWORD\",\"email_confirm\":true,\"user_metadata\":$meta}")

    user_id=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null || true)
    if [[ -z "$user_id" ]]; then
      echo "    FAILED: $resp" >&2
      return 1
    fi
    echo "    Created ($user_id)"
  fi

  # Promote admin roles (trigger only handles consumer/accountant on insert)
  if [[ "$role" == "super_administrator" || "$role" == "support_administrator" ]]; then
  curl -sS -X PATCH "https://${PROJECT_REF}.supabase.co/rest/v1/users?id=eq.${user_id}" \
    -H "Authorization: Bearer $SERVICE_KEY" \
    -H "apikey: $SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "{\"role\":\"$role\",\"account_status\":\"active\"}" >/dev/null
    echo "    Role set to $role"
  fi

  # Activate accountant after admin review
  if [[ "$role" == "accountant" ]]; then
    curl -sS -X PATCH "https://${PROJECT_REF}.supabase.co/rest/v1/users?id=eq.${user_id}" \
      -H "Authorization: Bearer $SERVICE_KEY" \
      -H "apikey: $SERVICE_KEY" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=minimal" \
      -d '{"account_status":"active"}' >/dev/null
    curl -sS -X PATCH "https://${PROJECT_REF}.supabase.co/rest/v1/accountants?user_id=eq.${user_id}" \
      -H "Authorization: Bearer $SERVICE_KEY" \
      -H "apikey: $SERVICE_KEY" \
      -H "Content-Type: application/json" \
      -H "Prefer: return=minimal" \
      -d '{"verification_status":"verified"}' >/dev/null 2>/dev/null || true
    echo "    Accountant activated and verified"
  fi
}

echo "==> Provisioning Receipt24 production users"
echo "    Project: $PROJECT_REF"
echo "    Password: $PASSWORD (all test users)"
echo ""

create_user "test@receipt24.dev" "consumer" "Test Consumer"
create_user "accountant@receipt24.dev" "accountant" "Demo Accountant"
create_user "admin@receipt24.dev" "super_administrator" "Platform Admin"
create_user "support@receipt24.dev" "support_administrator" "Support Admin"

echo ""
echo "==> Seeding reference data (categories, countries, legal)..."
cd "$ROOT"
supabase db query --linked -f supabase/seed/seed_dev.sql 2>&1 | tail -3 || {
  echo "    Seed may already be applied (ON CONFLICT safe)"
}

echo ""
echo "==> Production users ready:"
echo "    consumer   test@receipt24.dev"
echo "    accountant accountant@receipt24.dev"
echo "    admin      admin@receipt24.dev"
echo "    support    support@receipt24.dev"
echo "    password   $PASSWORD"
