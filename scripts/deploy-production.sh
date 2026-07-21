#!/usr/bin/env bash
# One-shot production deployment orchestrator.
#
# Prerequisites:
#   1. Supabase access token: https://supabase.com/dashboard/account/tokens
#   2. Vercel project linked (see docs/deploy-now.md)
#
# Usage:
#   export SUPABASE_ACCESS_TOKEN=sbp_...
#   export SUPABASE_PROJECT_REF=ivflhhxjqxcskwixaggd
#   ./scripts/deploy-production.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_REF="${SUPABASE_PROJECT_REF:-ivflhhxjqxcskwixaggd}"

echo "============================================"
echo " Receipt24 Production Deployment"
echo " Project: $PROJECT_REF"
echo "============================================"
echo ""

# --- Step 1: Supabase backend ---
echo ">>> Step 1/2: Deploy Supabase (migrations + edge functions)"
if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" ]]; then
  echo "SKIP: SUPABASE_ACCESS_TOKEN not set."
  echo "      Get one at: https://supabase.com/dashboard/account/tokens"
  echo "      Then run:   export SUPABASE_ACCESS_TOKEN=sbp_..."
  echo ""
else
  export SUPABASE_PROJECT_REF="$PROJECT_REF"
  bash "$ROOT/scripts/setup-supabase.sh" cloud
  echo ""
fi

# --- Step 2: Next.js web (Vercel) ---
echo ">>> Step 2/2: Deploy Next.js web app"
if [[ -z "${VERCEL_TOKEN:-}" ]]; then
  echo "SKIP: VERCEL_TOKEN not set."
  echo ""
  echo "Option A — Vercel Dashboard (easiest):"
  echo "  1. Go to https://vercel.com/new"
  echo "  2. Import: https://github.com/romy3sa-stack/Romeo-R24"
  echo "  3. Root Directory: apps/web"
  echo "  4. Add environment variables:"
  echo "       NEXT_PUBLIC_SUPABASE_URL=https://${PROJECT_REF}.supabase.co"
  echo "       NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=<your-key>"
  echo "  5. Click Deploy"
  echo ""
  echo "Option B — Vercel CLI:"
  echo "  cd apps/web && npx vercel --prod"
  echo ""
else
  cd "$ROOT/apps/web"
  npx vercel deploy --prod --token="$VERCEL_TOKEN"
  echo ""
fi

echo "============================================"
echo " Post-deploy checklist"
echo "============================================"
echo ""
echo " Supabase Auth URLs:"
echo "   https://supabase.com/dashboard/project/${PROJECT_REF}/auth/url-configuration"
echo ""
echo " Add your Vercel URL to Redirect URLs, e.g.:"
echo "   https://your-app.vercel.app/**"
echo ""
echo " Create a test user:"
echo "   https://supabase.com/dashboard/project/${PROJECT_REF}/auth/users"
echo ""
echo " Done."
