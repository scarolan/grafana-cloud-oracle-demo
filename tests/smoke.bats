#!/usr/bin/env bats
# =============================================================================
# Smoke Tests — Verify demo services are running and healthy
# =============================================================================

# --- Alloy ---

@test "alloy container is running" {
  run docker compose ps --format json alloy
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"State":"running"'
}

@test "alloy container is healthy" {
  run docker compose ps --format json alloy
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"Health":"healthy"'
}

@test "alloy is ready" {
  run docker compose exec alloy bash -c 'echo > /dev/tcp/localhost/12345'
  [ "$status" -eq 0 ]
}

@test "alloy metrics endpoint is accessible" {
  run docker compose exec alloy bash -c 'exec 3<>/dev/tcp/localhost/12345; echo -e "GET /metrics HTTP/1.0\r\nHost: localhost\r\n\r\n" >&3; cat <&3; exec 3>&-'
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'alloy_build_info'
}

# --- Oracle DB ---

@test "oracle-db container is running" {
  run docker compose ps --format json oracle-db
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"State":"running"'
}

@test "oracle-db container is healthy" {
  run docker compose ps --format json oracle-db
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"Health":"healthy"'
}

@test "oracle-db port 1521 is accessible" {
  run bash -c "echo > /dev/tcp/localhost/1521"
  [ "$status" -eq 0 ]
}

@test "XEPDB1 pluggable database is accessible" {
  run docker compose exec oracle-db bash -c 'echo "SELECT 1 FROM DUAL;" | sqlplus -S grafanau/oracle@XEPDB1'
  [ "$status" -eq 0 ]
}

@test "demo tables exist" {
  run docker compose exec oracle-db bash -c 'echo "SELECT table_name FROM user_tables ORDER BY table_name;" | sqlplus -S demo_user/oracle@XEPDB1'
  [ "$status" -eq 0 ]
  echo "$output" | grep -qi 'SALES'
  echo "$output" | grep -qi 'CUSTOMERS'
}

# --- Oracle OTel Exporter ---

@test "oracle-otel-exporter container is running" {
  run docker compose ps --format json oracle-otel-exporter
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"State":"running"'
}

@test "oracle-otel-exporter container is healthy" {
  run docker compose ps --format json oracle-otel-exporter
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"Health":"healthy"'
}

@test "oracle-otel-exporter metrics endpoint is accessible" {
  run curl -sf http://localhost:19161/metrics
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'oracledb_up'
}
