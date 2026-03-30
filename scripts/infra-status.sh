#!/usr/bin/env bash
# ---------------------------------------------------------------
# infra-status.sh — Show the status of all deployed environments.
#
# Usage:
#   ./scripts/infra-status.sh
# ---------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "============================================"
echo " Infrastructure Status"
echo "============================================"
echo ""

for env in dev prod; do
  env_dir="$REPO_ROOT/environments/$env"
  [[ -f "$env_dir/terraform.tfvars" ]] || continue

  location=$(grep '^location' "$env_dir/terraform.tfvars" | sed 's/.*= *"\(.*\)"/\1/')
  rg_name="opella-${env}-${location}-rg"
  vm_name="opella-${env}-${location}-vm"

  echo "--- $env ($location) ---"

  # Check resource group
  rg_exists=$(az group exists --name "$rg_name" 2>/dev/null || echo "false")
  if [[ "$rg_exists" != "true" ]]; then
    echo "  Resource group: NOT DEPLOYED"
    echo ""
    continue
  fi
  echo "  Resource group: $rg_name"

  # Count resources
  count=$(az resource list --resource-group "$rg_name" --query "length([])" --output tsv 2>/dev/null || echo "0")
  echo "  Resources:      $count"

  # VM status
  vm_status=$(az vm get-instance-view \
    --resource-group "$rg_name" \
    --name "$vm_name" \
    --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" \
    --output tsv 2>/dev/null || echo "not found")
  echo "  VM status:      $vm_status"

  echo ""
done
