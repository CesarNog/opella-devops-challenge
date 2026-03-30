#!/usr/bin/env bash
# Static validation tests for Terraform configurations.
# These tests require no cloud credentials and run entirely offline.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0
FAIL=0
ERRORS=()

pass() { ((PASS++)); echo "  PASS: $1"; }
fail() { ((FAIL++)); ERRORS+=("$1"); echo "  FAIL: $1"; }

echo "============================================"
echo " Static Validation Tests"
echo "============================================"
echo ""

# -------------------------------------------------------
# Test 1: Terraform formatting
# -------------------------------------------------------
echo "[1] Terraform format check"
if terraform fmt -check -recursive "$REPO_ROOT" > /dev/null 2>&1; then
  pass "All files are properly formatted"
else
  fail "Some files are not formatted — run 'terraform fmt -recursive .'"
fi

# -------------------------------------------------------
# Test 2: Module has required files
# -------------------------------------------------------
echo "[2] Module structure check (modules/vnet)"
for f in main.tf variables.tf outputs.tf versions.tf README.md; do
  if [[ -f "$REPO_ROOT/modules/vnet/$f" ]]; then
    pass "modules/vnet/$f exists"
  else
    fail "modules/vnet/$f is missing"
  fi
done

# -------------------------------------------------------
# Test 3: All variables have descriptions
# -------------------------------------------------------
echo "[3] Variable documentation check"
for dir in modules/vnet environments/dev environments/prod; do
  vars_file="$REPO_ROOT/$dir/variables.tf"
  if [[ -f "$vars_file" ]]; then
    var_count=$(grep -c 'variable "' "$vars_file" || true)
    desc_count=$(grep -c 'description' "$vars_file" || true)
    if [[ "$var_count" -le "$desc_count" ]]; then
      pass "$dir/variables.tf — all $var_count variables documented"
    else
      fail "$dir/variables.tf — $var_count variables but only $desc_count descriptions"
    fi
  fi
done

# -------------------------------------------------------
# Test 4: All outputs have descriptions
# -------------------------------------------------------
echo "[4] Output documentation check"
for dir in modules/vnet environments/dev environments/prod; do
  out_file="$REPO_ROOT/$dir/outputs.tf"
  if [[ -f "$out_file" ]]; then
    out_count=$(grep -c 'output "' "$out_file" || true)
    desc_count=$(grep -c 'description' "$out_file" || true)
    if [[ "$out_count" -le "$desc_count" ]]; then
      pass "$dir/outputs.tf — all $out_count outputs documented"
    else
      fail "$dir/outputs.tf — $out_count outputs but only $desc_count descriptions"
    fi
  fi
done

# -------------------------------------------------------
# Test 5: No hardcoded secrets
# -------------------------------------------------------
echo "[5] Secret detection"
if grep -rE '(password|secret|api_key)\s*=\s*"[^"$]' "$REPO_ROOT/modules" "$REPO_ROOT/environments" 2>/dev/null; then
  fail "Possible hardcoded secrets found"
else
  pass "No hardcoded secrets detected"
fi

# -------------------------------------------------------
# Test 6: Provider version constraints
# -------------------------------------------------------
echo "[6] Provider version constraints"
for dir in modules/vnet environments/dev environments/prod; do
  ver_file="$REPO_ROOT/$dir/versions.tf"
  if [[ -f "$ver_file" ]]; then
    if grep -q 'required_version' "$ver_file"; then
      pass "$dir — Terraform version constraint set"
    else
      fail "$dir — missing required_version constraint"
    fi
    if grep -q 'required_providers' "$ver_file"; then
      pass "$dir — required_providers block present"
    else
      fail "$dir — missing required_providers block"
    fi
  fi
done

# -------------------------------------------------------
# Test 7: Terraform validate (each environment)
# -------------------------------------------------------
echo "[7] Terraform validate"
for env in dev prod; do
  env_dir="$REPO_ROOT/environments/$env"
  if [[ -d "$env_dir/.terraform" ]]; then
    if (cd "$env_dir" && terraform validate) > /dev/null 2>&1; then
      pass "environments/$env passes terraform validate"
    else
      fail "environments/$env fails terraform validate"
    fi
  else
    echo "  SKIP: environments/$env not initialized (run terraform init first)"
  fi
done

# -------------------------------------------------------
# Test 8: Naming convention check
# -------------------------------------------------------
echo "[8] Resource naming convention"
for env in dev prod; do
  main_file="$REPO_ROOT/environments/$env/main.tf"
  if grep -q 'name_prefix' "$main_file"; then
    pass "environments/$env uses name_prefix for consistent naming"
  else
    fail "environments/$env does not use name_prefix pattern"
  fi
done

# -------------------------------------------------------
# Test 9: Tags enforcement
# -------------------------------------------------------
echo "[9] Tag enforcement check"
for env in dev prod; do
  main_file="$REPO_ROOT/environments/$env/main.tf"
  for tag in environment project region managed_by; do
    if grep -q "$tag" "$main_file"; then
      pass "environments/$env — '$tag' tag present"
    else
      fail "environments/$env — '$tag' tag missing"
    fi
  done
done

# -------------------------------------------------------
# Test 10: Security checks
# -------------------------------------------------------
echo "[10] Security configuration check"
for env in dev prod; do
  main_file="$REPO_ROOT/environments/$env/main.tf"
  if grep -q 'min_tls_version.*TLS1_2' "$main_file"; then
    pass "environments/$env — TLS 1.2 minimum enforced on storage"
  else
    fail "environments/$env — TLS 1.2 not enforced on storage"
  fi
  if grep -q 'disable_password_authentication.*true' "$main_file"; then
    pass "environments/$env — password auth disabled on VM"
  else
    fail "environments/$env — password auth not disabled on VM"
  fi
  if grep -q 'default_action' "$main_file"; then
    pass "environments/$env — network default_action configured"
  else
    fail "environments/$env — network default_action not configured"
  fi
  if grep -q 'container_access_type.*private' "$main_file"; then
    pass "environments/$env — blob container set to private"
  else
    fail "environments/$env — blob container not private"
  fi
done

# -------------------------------------------------------
# Summary
# -------------------------------------------------------
echo ""
echo "============================================"
echo " Results: $PASS passed, $FAIL failed"
echo "============================================"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failures:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  exit 1
fi
