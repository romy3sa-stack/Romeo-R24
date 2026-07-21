#!/usr/bin/env bash
# Deploy Receipt24 Supabase migrations and edge functions to a linked project.
# Prerequisites: supabase CLI, `supabase link --project-ref <ref>`
#
# Usage:
#   ./scripts/deploy-supabase.sh              # migrations + all functions
#   ./scripts/deploy-supabase.sh --migrations-only
#   ./scripts/deploy-supabase.sh --functions-only

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MIGRATIONS_ONLY=false
FUNCTIONS_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --migrations-only) MIGRATIONS_ONLY=true ;;
    --functions-only) FUNCTIONS_ONLY=true ;;
  esac
done

if ! command -v supabase >/dev/null 2>&1; then
  echo "supabase CLI is required. Install: https://supabase.com/docs/guides/cli" >&2
  exit 1
fi

FUNCTIONS=(
  get-signed-url
  process-receipt-ocr
  send-notification
  process-reminders
  create-checkout-session
  cancel-subscription
  stripe-webhook
)

deploy_migrations() {
  echo "==> Pushing database migrations..."
  supabase db push
}

deploy_functions() {
  echo "==> Deploying edge functions..."
  for fn in "${FUNCTIONS[@]}"; do
    echo "    Deploying $fn..."
    if [[ "$fn" == "stripe-webhook" ]]; then
      supabase functions deploy "$fn" --no-verify-jwt
    else
      supabase functions deploy "$fn"
    fi
  done
}

set_edge_secrets() {
  if [[ -n "${STRIPE_SECRET_KEY:-}" ]]; then
    echo "==> Setting Stripe secrets..."
    supabase secrets set \
      STRIPE_SECRET_KEY="$STRIPE_SECRET_KEY" \
      STRIPE_WEBHOOK_SECRET="${STRIPE_WEBHOOK_SECRET:-}" \
      STRIPE_PUBLISHABLE_KEY="${STRIPE_PUBLISHABLE_KEY:-}"
  fi
  if [[ -n "${RESEND_API_KEY:-}" ]]; then
    supabase secrets set RESEND_API_KEY="$RESEND_API_KEY" EMAIL_FROM="${EMAIL_FROM:-noreply@receipt24.com}"
  fi
  if [[ -n "${GOOGLE_VISION_API_KEY:-}" ]]; then
    supabase secrets set GOOGLE_VISION_API_KEY="$GOOGLE_VISION_API_KEY"
  fi
}

if [[ "$FUNCTIONS_ONLY" == false ]]; then
  deploy_migrations
fi

if [[ "$MIGRATIONS_ONLY" == false ]]; then
  set_edge_secrets
  deploy_functions
fi

echo "==> Supabase deployment complete."
