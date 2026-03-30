#!/usr/bin/env bash
# ---------------------------------------------------------------
# infra-up.sh — Initialize and deploy the infrastructure, or
#               resume stopped resources.
#
# Usage:
#   ./scripts/infra-up.sh          # deploy dev (default)
#   ./scripts/infra-up.sh dev      # deploy dev
#   ./scripts/infra-up.sh prod     # deploy prod
#   ./scripts/infra-up.sh all      # deploy both
# ---------------------------------------------------------------
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV="${1:-dev}"

deploy_env() {
  local env="$1"
  local env_dir="$REPO_ROOT/environments/$env"

  echo ""
  echo "============================================"
  echo " Deploying: $env"
  echo "============================================"

  # Read location and resource group from tfvars
  local location rg_name vm_name
  location=$(grep '^location' "$env_dir/terraform.tfvars" | sed 's/.*= *"\(.*\)"/\1/')
  rg_name="opella-${env}-${location}-rg"
  vm_name="opella-${env}-${location}-vm"

  # Check if resources already exist but are just stopped
  local vm_status
  vm_status=$(az vm get-instance-view \
    --resource-group "$rg_name" \
    --name "$vm_name" \
    --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" \
    --output tsv 2>/dev/null || echo "not_found")

  if [[ "$vm_status" == "VM deallocated" ]]; then
    echo "VM is deallocated. Starting it..."
    az vm start --resource-group "$rg_name" --name "$vm_name" --no-wait
    echo "VM start initiated (running in background)."
    return
  elif [[ "$vm_status" == "VM running" ]]; then
    echo "VM is already running. Nothing to do."
    return
  fi

  # Resources don't exist — full Terraform deploy
  echo "Initializing Terraform..."
  cd "$env_dir"
  terraform init -input=false

  echo "Planning..."
  terraform plan -out="${env}.tfplan"

  echo "Applying..."
  terraform apply "${env}.tfplan"
  rm -f "${env}.tfplan"

  echo ""
  echo "$env environment is up!"
}

if [[ "$ENV" == "all" ]]; then
  deploy_env "dev"
  deploy_env "prod"
else
  deploy_env "$ENV"
fi

echo ""
echo "Done."
