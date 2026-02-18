#!/usr/bin/env bash
# =============================================================================
# Preflight Check — Verify prerequisites before running the demo
# =============================================================================
set -uo pipefail

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✓ $1"; ((PASS++)); }
fail() { echo "  ✗ $1"; ((FAIL++)); }
warn() { echo "  ⚠ $1 (optional)"; ((WARN++)); }

echo "=== Preflight Check ==="
echo ""

# ---- Required tools ----
echo "Required tools:"

if command -v docker &>/dev/null; then
  pass "Docker is installed ($(docker --version | head -1))"
else
  fail "Docker is not installed — install Docker Desktop: https://docs.docker.com/get-docker/"
fi

if docker info &>/dev/null; then
  pass "Docker daemon is running"
else
  fail "Docker daemon is not running — make sure Docker Desktop is installed and running"
fi

if docker compose version &>/dev/null; then
  pass "Docker Compose V2 is available ($(docker compose version --short))"
else
  fail "Docker Compose V2 is not available — update Docker Desktop"
fi

if command -v gh &>/dev/null; then
  pass "GitHub CLI is installed ($(gh --version | head -1))"
else
  fail "GitHub CLI is not installed — install: https://cli.github.com/"
fi

echo ""

# ---- Optional tools ----
echo "Optional tools:"

if command -v terraform &>/dev/null; then
  pass "Terraform is installed ($(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || terraform version | head -1))"
else
  warn "Terraform is not installed — needed only for cloud resource demos"
fi

if command -v k6 &>/dev/null; then
  pass "k6 is installed ($(k6 version 2>&1 | head -1))"
else
  warn "k6 is not installed — needed only for load testing"
fi

if command -v bats &>/dev/null; then
  pass "BATS is installed ($(bats --version))"
else
  warn "BATS is not installed — needed for running tests"
fi

echo ""

# ---- .env file ----
echo "Environment:"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  pass ".env file exists"

  # Check required variables
  REQUIRED_VARS=(
    "GRAFANA_METRICS_URL"
    "GRAFANA_METRICS_USERNAME"
    "GRAFANA_METRICS_API_KEY"
    "GRAFANA_LOGS_URL"
    "GRAFANA_LOGS_USERNAME"
    "GRAFANA_LOGS_API_KEY"
    "ORACLE_PASSWORD"
  )

  for var in "${REQUIRED_VARS[@]}"; do
    value=$(grep "^${var}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- || true)
    if [ -z "$value" ]; then
      fail "$var is not set in .env"
    elif echo "$value" | grep -qE '(000000|xxxxxxxx|changeme|placeholder)'; then
      fail "$var has a placeholder value in .env"
    else
      pass "$var is configured"
    fi
  done
else
  fail ".env file not found — run: cp .env.example .env"
fi

echo ""

# ---- Summary ----
echo "=== Summary ==="
echo "  Passed:  $PASS"
echo "  Failed:  $FAIL"
echo "  Warned:  $WARN"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Preflight check FAILED — fix the issues above before proceeding."
  exit 1
else
  echo "Preflight check PASSED — ready to start the demo."
  exit 0
fi
