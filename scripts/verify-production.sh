#!/usr/bin/env bash
# End-to-end production verification for Receipt24.
# Usage: ./scripts/verify-production.sh

set -euo pipefail

PROJECT_REF="${SUPABASE_PROJECT_REF:-ivflhhxjqxcskwixaggd}"
SUPABASE_URL="https://${PROJECT_REF}.supabase.co"
WEB_URL="${WEB_URL:-https://romeo-r24.vercel.app}"
PASSWORD="${RECEIPT24_TEST_PASSWORD:-Receipt24Test!}"

PASS=0
FAIL=0

check() {
  local name="$1"
  local result="$2"
  if [[ "$result" == "ok" ]]; then
    echo "  ✓ $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name — $result"
    FAIL=$((FAIL + 1))
  fi
}

echo "==> Receipt24 Production Verification"
echo "    Web: $WEB_URL"
echo "    API: $SUPABASE_URL"
echo ""

# Web routes
echo "Web routes:"
for path in "/" "/login" "/dashboard" "/logo.svg"; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" -L "${WEB_URL}${path}" 2>/dev/null || echo "000")
  if [[ "$path" == "/dashboard" ]]; then
    # Unauthenticated should redirect (307/302) or show login
    [[ "$code" =~ ^(200|302|307)$ ]] && check "$path ($code)" "ok" || check "$path" "HTTP $code"
  else
    [[ "$code" == "200" ]] && check "$path" "ok" || check "$path" "HTTP $code"
  fi
done

# Auth for each role
echo ""
echo "Auth (email/password):"
ANON_KEY=$(supabase projects api-keys --project-ref "$PROJECT_REF" -o json 2>/dev/null \
  | python3 -c "import json,sys; print([k['api_key'] for k in json.load(sys.stdin) if k['name']=='anon'][0])")

for email in test@receipt24.dev accountant@receipt24.dev admin@receipt24.dev support@receipt24.dev; do
  resp=$(curl -sS -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
    -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$PASSWORD\"}" 2>/dev/null)
  token=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null || true)
  if [[ -n "$token" ]]; then
    role=$(curl -sS "${SUPABASE_URL}/rest/v1/users?email=eq.${email}&select=role" \
      -H "apikey: $ANON_KEY" \
      -H "Authorization: Bearer $token" 2>/dev/null \
      | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['role'] if d else 'unknown')" 2>/dev/null || echo "unknown")
    check "$email → $role" "ok"
  else
    err=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('error_description','failed'))" 2>/dev/null || echo "failed")
    check "$email" "$err"
  fi
done

# Edge functions (with consumer JWT)
echo ""
echo "Edge functions:"
CONSUMER_TOKEN=$(curl -sS -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@receipt24.dev\",\"password\":\"$PASSWORD\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

CONSUMER_ID=$(curl -sS -X POST "${SUPABASE_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"test@receipt24.dev\",\"password\":\"$PASSWORD\"}" \
  | python3 -c "import json,sys; print(json.load(sys.stdin).get('user',{}).get('id',''))" 2>/dev/null)

if [[ -n "$CONSUMER_TOKEN" && -n "$CONSUMER_ID" ]]; then
  # send-notification (correct API shape)
  notif_code=$(curl -sS -o /dev/null -w "%{http_code}" -X POST \
    "${SUPABASE_URL}/functions/v1/send-notification" \
    -H "Authorization: Bearer $CONSUMER_TOKEN" \
    -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$CONSUMER_ID\",\"notificationType\":\"general\",\"title\":\"Test\",\"message\":\"Verification\"}" 2>/dev/null || echo "000")
  [[ "$notif_code" =~ ^(200|201)$ ]] && check "send-notification ($notif_code)" "ok" || check "send-notification" "HTTP $notif_code"

  # process-receipt-ocr (mock)
  ocr_code=$(curl -sS -o /dev/null -w "%{http_code}" -X POST \
    "${SUPABASE_URL}/functions/v1/process-receipt-ocr" \
    -H "Authorization: Bearer $CONSUMER_TOKEN" \
    -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" \
    -d '{"upload_id":"00000000-0000-0000-0000-000000000001"}' 2>/dev/null || echo "000")
  [[ "$ocr_code" =~ ^(200|400|404)$ ]] && check "process-receipt-ocr ($ocr_code)" "ok" || check "process-receipt-ocr" "HTTP $ocr_code"

  # create-checkout-session (mock mode without Stripe)
  checkout_code=$(curl -sS -o /dev/null -w "%{http_code}" -X POST \
    "${SUPABASE_URL}/functions/v1/create-checkout-session" \
    -H "Authorization: Bearer $CONSUMER_TOKEN" \
    -H "apikey: $ANON_KEY" \
    -H "Content-Type: application/json" \
    -d '{"plan":"consumer_monthly"}' 2>/dev/null || echo "000")
  [[ "$checkout_code" =~ ^(200|201|400)$ ]] && check "create-checkout-session ($checkout_code)" "ok" || check "create-checkout-session" "HTTP $checkout_code"
else
  check "edge functions" "no consumer token"
fi

# Database tables accessible
echo ""
echo "Database (reference data):"
if [[ -n "$CONSUMER_TOKEN" ]]; then
  cats=$(curl -sS "${SUPABASE_URL}/rest/v1/receipt_categories?select=count" \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $CONSUMER_TOKEN" \
    -H "Prefer: count=exact" -I 2>/dev/null | grep -i content-range | awk -F/ '{print $2}' | tr -d '\r' || echo "0")
  [[ "${cats:-0}" -gt 0 ]] && check "receipt_categories ($cats rows)" "ok" || check "receipt_categories" "empty or blocked"

  countries=$(curl -sS "${SUPABASE_URL}/rest/v1/countries?select=count" \
    -H "apikey: $ANON_KEY" \
    -H "Authorization: Bearer $CONSUMER_TOKEN" \
    -H "Prefer: count=exact" -I 2>/dev/null | grep -i content-range | awk -F/ '{print $2}' | tr -d '\r' || echo "0")
  [[ "${countries:-0}" -gt 0 ]] && check "countries ($countries rows)" "ok" || check "countries" "empty or blocked"
fi

echo ""
echo "==> Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] && exit 0 || exit 1
