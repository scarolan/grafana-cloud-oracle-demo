#!/usr/bin/env bash
# =============================================================================
# Start Demo — Preflight → Terraform → Docker Compose → Health → Status
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Starting Demo ==="
echo ""

# ---- Step 1: Preflight ----
echo "--- Running preflight checks ---"
"$SCRIPT_DIR/preflight-check.sh"
echo ""

# ---- Step 2: Terraform (if configured) ----
TF_DIR="$PROJECT_DIR/terraform"
if [ -f "$TF_DIR/main.tf" ] && grep -q 'resource\|module' "$TF_DIR/main.tf" 2>/dev/null; then
  echo "--- Applying Terraform ---"
  cd "$TF_DIR"

  if [ -f terraform.tfvars ]; then
    terraform init -input=false
    terraform apply -auto-approve
  else
    echo "  terraform/terraform.tfvars not found — skipping Terraform"
    echo "  Copy terraform.tfvars.example to terraform.tfvars and fill in values"
  fi

  cd "$PROJECT_DIR"
  echo ""
else
  echo "--- Skipping Terraform (no resources defined) ---"
  echo ""
fi

# ---- Step 3: Docker Compose ----
echo "--- Starting Docker Compose services ---"
cd "$PROJECT_DIR"
docker compose up -d
echo ""

# ---- Step 4: Wait for health ----
echo "--- Waiting for services to become healthy ---"
MAX_WAIT=180
ELAPSED=0
INTERVAL=5

while [ $ELAPSED -lt $MAX_WAIT ]; do
  # Check if all services are healthy or running (for those without healthchecks)
  UNHEALTHY=$(docker compose ps --format json 2>/dev/null | grep -c '"Health":"starting"' || true)

  if [ "$UNHEALTHY" -eq 0 ]; then
    echo "  All services are healthy!"
    break
  fi

  echo "  Waiting... ($ELAPSED/${MAX_WAIT}s)"
  sleep $INTERVAL
  ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
  echo "  Timed out waiting for services — check 'docker compose ps' and logs"
fi

echo ""

# ---- Step 5: Status ----
echo "--- Demo Status ---"
docker compose ps
echo ""

echo "=== Demo is running ==="
echo ""
echo "  Oracle DB:        localhost:1521  (grafanau/oracle)"
echo "  OTel Exporter:    http://localhost:19161/metrics"
echo ""
echo "  Connect to Oracle:"
echo "    docker exec -it demo-oracle-db sqlplus demo_user/oracle@XEPDB1"
echo ""
echo "  Run load generator:"
echo "    docker exec demo-oracle-db sqlplus -S demo_user/oracle@XEPDB1 <<< 'EXEC generate_load;'"
echo ""
echo "  To stop:        make stop"
echo "  To run tests:   make test"
