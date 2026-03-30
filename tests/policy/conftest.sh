#!/usr/bin/env bash
# Run OPA/Conftest policy tests against Terraform plan output.
# Prerequisites: conftest (https://www.conftest.dev/install/)
#
# Usage:
#   ./tests/policy/conftest.sh dev
#   ./tests/policy/conftest.sh prod
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV="${1:-dev}"
POLICY_DIR="$REPO_ROOT/tests/policy"
ENV_DIR="$REPO_ROOT/environments/$ENV"

echo "============================================"
echo " OPA Policy Tests — $ENV"
echo "============================================"

cd "$ENV_DIR"

echo "[1] Generating plan JSON..."
terraform plan -out=tfplan.binary > /dev/null 2>&1
terraform show -json tfplan.binary > tfplan.json

echo "[2] Running conftest..."
conftest test tfplan.json --policy "$POLICY_DIR" --no-color

echo "[3] Cleaning up..."
rm -f tfplan.binary tfplan.json

echo ""
echo "Policy tests complete."
