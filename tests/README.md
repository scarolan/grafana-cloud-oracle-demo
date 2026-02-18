# Tests

This demo uses [BATS](https://github.com/bats-core/bats-core) (Bash Automated Testing System) for infrastructure and telemetry verification.

## Philosophy

Tests exist to answer three questions:

1. **Can this demo run here?** (`preflight.bats`) — Are the right tools installed? Is `.env` configured?
2. **Is the demo running?** (`smoke.bats`) — Are containers up and healthy? Are ports accessible?
3. **Is data flowing?** (`telemetry.bats`) — Are metrics/logs/traces reaching Grafana Cloud?

## Installing BATS

### macOS
```bash
brew install bats-core
```

### Ubuntu/Debian
```bash
sudo apt install bats
```

### From source
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

```bash
# Run all tests
make test

# Run individual test suites
make test-preflight
make test-smoke
make test-telemetry

# Or run BATS directly
bats tests/preflight.bats
bats tests/smoke.bats
bats tests/telemetry.bats
```

## Adding Demo-Specific Tests

When building out a demo, add tests for your specific services:

```bash
# In tests/smoke.bats — add container checks
@test "my-app container is running" {
  run docker compose ps --format json my-app
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"State":"running"'
}

# In tests/telemetry.bats — add metrics checks
@test "my-app metrics are being scraped" {
  run curl -sf http://localhost:12345/metrics
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'my_app_requests_total'
}
```
