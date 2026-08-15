#!/usr/bin/env bash
# deploy-production.sh — Deploy all PareFood Edge Functions to a linked
# Supabase project. Run after `supabase link --project-ref <REF>`.
#
# Usage:
#   cd backend/supabase
#   chmod +x scripts/deploy-production.sh
#   ./scripts/deploy-production.sh
#
# Prerequisites:
#   - supabase CLI installed and logged in
#   - supabase link --project-ref <PROD_REF> already run
#   - secrets set via `supabase secrets set ...`

set -euo pipefail

echo "=========================================="
echo "  PareFood Edge Functions Deployment"
echo "=========================================="
echo ""

# All 16 Edge Functions (order matters for dependency clarity, though
# Supabase deploys them independently).
FUNCTIONS=(
  "place-order"
  "accept-order"
  "ready-order"
  "accept-job"
  "decline-job"
  "driver-pickup"
  "driver-delivered"
  "complete-order"
  "cancel-order"
  "process-payment"
  "webhook-psp"
  "send-notification"
  "register-device-token"
  "settle-restaurants"
  "payout-drivers"
  "reconcile"
  "dispatch"
)

FAILED=()
SUCCEEDED=()

for fn in "${FUNCTIONS[@]}"; do
  echo -n "  Deploying $fn ... "
  if supabase functions deploy "$fn" --no-verify-jwt 2>&1 | grep -q "Deployed Function"; then
    echo "✓"
    SUCCEEDED+=("$fn")
  else
    echo "✗ FAILED"
    FAILED+=("$fn")
  fi
done

echo ""
echo "=========================================="
echo "  Deployment Summary"
echo "=========================================="
echo "  Succeeded: ${#SUCCEEDED[@]}/${#FUNCTIONS[@]}"
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "  Failed:    ${#FAILED[@]}"
  for f in "${FAILED[@]}"; do
    echo "    - $f"
  done
  echo ""
  echo "  Re-run failed deployments:"
  for f in "${FAILED[@]}"; do
    echo "    supabase functions deploy $f --no-verify-jwt"
  done
  exit 1
else
  echo ""
  echo "  ✅ All functions deployed successfully."
  echo ""
  echo "  Next steps:"
  echo "    1. Verify: supabase functions list"
  echo "    2. Set cron jobs (see supabase-production-migration.md Phase 4)"
  echo "    3. Set storage bucket policies (Phase 5)"
  echo "    4. Seed pilot data (Phase 6)"
fi
