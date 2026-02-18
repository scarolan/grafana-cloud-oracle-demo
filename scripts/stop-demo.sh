#!/usr/bin/env bash
# =============================================================================
# Stop Demo — Docker Compose down → Terraform destroy (if configured)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Stopping Demo ==="
echo ""

# ---- Step 1: Docker Compose ----
echo "--- Stopping Docker Compose services ---"
cd "$PROJECT_DIR"
docker compose down --volumes --remove-orphans
echo ""

# ---- Step 2: Terraform (if configured) ----
TF_DIR="$PROJECT_DIR/terraform"
if [ -f "$TF_DIR/terraform.tfstate" ]; then
  echo "--- Destroying Terraform resources ---"
  cd "$TF_DIR"
  terraform destroy -auto-approve
  cd "$PROJECT_DIR"
  echo ""
else
  echo "--- Skipping Terraform (no state file) ---"
  echo ""
fi

echo "=== Demo stopped ==="
