#!/usr/bin/env bats
# =============================================================================
# Telemetry Tests — Verify metrics/logs are flowing to Grafana Cloud
# =============================================================================

ALLOY_URL="http://localhost:12345"

# --- Alloy baseline ---

@test "alloy exposes prometheus metrics" {
  run curl -sf "$ALLOY_URL/metrics"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'alloy_build_info'
}

@test "prometheus remote_write is configured" {
  run curl -sf "$ALLOY_URL/metrics"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'prometheus_remote_write'
}

@test "metrics samples are being sent" {
  run curl -sf "$ALLOY_URL/metrics"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'prometheus_remote_storage_samples_total'
}

@test "no persistent remote_write errors" {
  run curl -sf "$ALLOY_URL/metrics"
  [ "$status" -eq 0 ]

  failed=$(echo "$output" | grep '^prometheus_remote_storage_samples_failed_total' | head -1 | awk '{print $2}' || echo "0")
  total=$(echo "$output" | grep '^prometheus_remote_storage_samples_total' | head -1 | awk '{print $2}' || echo "1")

  # If no failed metric exists, that's fine
  [ -z "$failed" ] && return 0
  [ -z "$total" ] && return 0

  failed_int=${failed%%.*}
  total_int=${total%%.*}

  [ "${failed_int:-0}" -lt "$((${total_int:-1} / 10 + 1))" ]
}

# --- Oracle metrics (native integration) ---

@test "oracledb integration component is active" {
  run curl -sf "$ALLOY_URL/api/v0/web/components"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'prometheus.exporter.oracledb.integration'
}

@test "oracledb integration scrape is active" {
  run curl -sf "$ALLOY_URL/api/v0/web/components"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'prometheus.scrape.integration'
}

# --- Oracle metrics (OTel exporter) ---

@test "otel exporter scrape target is active" {
  run curl -sf "$ALLOY_URL/api/v0/web/components"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'prometheus.scrape.otel_exporter'
}

# --- Log collection ---

@test "loki write endpoint is configured" {
  run curl -sf "$ALLOY_URL/api/v0/web/components"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'loki.write.grafana_cloud'
}

@test "docker log discovery is active" {
  run curl -sf "$ALLOY_URL/api/v0/web/components"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'discovery.docker.oracle'
}

@test "oracle log processing pipeline is active" {
  run curl -sf "$ALLOY_URL/api/v0/web/components"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'loki.process.oracle_logs'
}

@test "loki entries are being sent" {
  run curl -sf "$ALLOY_URL/metrics"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'loki_write_sent_entries_total'
}
