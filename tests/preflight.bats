#!/usr/bin/env bats
# =============================================================================
# Preflight Tests — Verify prerequisites for running the demo
# =============================================================================

@test "docker is installed" {
  command -v docker
}

@test "docker daemon is running" {
  docker info >/dev/null 2>&1
}

@test "docker compose v2 is available" {
  docker compose version
}

@test "github cli is installed" {
  command -v gh
}

@test ".env file exists" {
  [ -f .env ]
}

@test "GRAFANA_METRICS_URL is set in .env" {
  grep -q "^GRAFANA_METRICS_URL=" .env
  value=$(grep "^GRAFANA_METRICS_URL=" .env | cut -d'=' -f2-)
  [ -n "$value" ]
  ! echo "$value" | grep -qE '(000000|xxxxxxxx|placeholder)'
}

@test "GRAFANA_METRICS_USERNAME is set in .env" {
  grep -q "^GRAFANA_METRICS_USERNAME=" .env
  value=$(grep "^GRAFANA_METRICS_USERNAME=" .env | cut -d'=' -f2-)
  [ -n "$value" ]
  ! echo "$value" | grep -qE '(000000|xxxxxxxx|placeholder)'
}

@test "GRAFANA_METRICS_API_KEY is set in .env" {
  grep -q "^GRAFANA_METRICS_API_KEY=" .env
  value=$(grep "^GRAFANA_METRICS_API_KEY=" .env | cut -d'=' -f2-)
  [ -n "$value" ]
  ! echo "$value" | grep -qE '(000000|xxxxxxxx|placeholder)'
}

@test "GRAFANA_LOGS_URL is set in .env" {
  grep -q "^GRAFANA_LOGS_URL=" .env
  value=$(grep "^GRAFANA_LOGS_URL=" .env | cut -d'=' -f2-)
  [ -n "$value" ]
  ! echo "$value" | grep -qE '(000000|xxxxxxxx|placeholder)'
}

@test "GRAFANA_LOGS_USERNAME is set in .env" {
  grep -q "^GRAFANA_LOGS_USERNAME=" .env
  value=$(grep "^GRAFANA_LOGS_USERNAME=" .env | cut -d'=' -f2-)
  [ -n "$value" ]
  ! echo "$value" | grep -qE '(000000|xxxxxxxx|placeholder)'
}

@test "GRAFANA_LOGS_API_KEY is set in .env" {
  grep -q "^GRAFANA_LOGS_API_KEY=" .env
  value=$(grep "^GRAFANA_LOGS_API_KEY=" .env | cut -d'=' -f2-)
  [ -n "$value" ]
  ! echo "$value" | grep -qE '(000000|xxxxxxxx|placeholder)'
}

@test "ORACLE_PASSWORD is set in .env" {
  grep -q "^ORACLE_PASSWORD=" .env
  value=$(grep "^ORACLE_PASSWORD=" .env | cut -d'=' -f2-)
  [ -n "$value" ]
  ! echo "$value" | grep -qE '(changeme|placeholder)'
}
