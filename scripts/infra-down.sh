#!/usr/bin/env bash
# ---------------------------------------------------------------
# infra-down.sh — Deallocate VMs to save costs without destroying
#                 any infrastructure.
#
# Deallocated VMs incur NO compute charges. Storage, networking,
# and Key Vault remain available at minimal cost.
#
# Usage:
#   ./scripts/infra-down.sh          # stop dev (default)
#   ./scripts/infra-down.sh dev      # stop dev
#   ./scripts/infra-down.sh prod     # stop prod
#   ./scripts/infra-down.sh all      # stop both
# ---------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV="${1:-dev}"

stop_env() {
  local env="$1"
  local env_dir="$REPO_ROOT/environments/$env"

  echo ""
  echo "============================================"
  echo " Stopping: $env"
  echo "============================================"

  local location rg_name vm_name
  location=$(grep '^location' "$env_dir/terraform.tfvars" | sed 's/.*= *"\(.*\)"/\1/')
  rg_name="opella-${env}-${location}-rg"
  vm_name="opella-${env}-${location}-vm"

  local vm_status
  vm_status=$(az vm get-instance-view \
    --resource-group "$rg_name" \
    --name "$vm_name" \
    --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" \
    --output tsv 2>/dev/null || echo "not_found")

  if [[ "$vm_status" == "not_found" ]]; then
    echo "VM '$vm_name' not found in '$rg_name'. Nothing to stop."
    return
  elif [[ "$vm_status" == "VM deallocated" ]]; then
    echo "VM is already deallocated."
    return
  fi

  echo "Deallocating VM '$vm_name'..."
  az vm deallocate --resource-group "$rg_name" --name "$vm_name" --no-wait
  echo "Deallocation initiated (running in background)."
  echo "  - Compute charges: STOPPED"
  echo "  - Disk/Storage/KeyVault: still active (minimal cost)"
}

if [[ "$ENV" == "all" ]]; then
  stop_env "dev"
  stop_env "prod"
else
  stop_env "$ENV"
fi

echo ""
echo "Done. Run './scripts/infra-up.sh $ENV' to resume."
