# CLAUDE.md — Demo Builder Guide

You are building a customer demo that ships telemetry (metrics, logs, traces) to Grafana Cloud. This template provides the skeleton — your job is to flesh it out based on the SE's scenario description.

## Philosophy

1. **Working > Perfect** — A running demo with real telemetry beats a polished slide deck. Ship something that works, then iterate.
2. **Convention over Configuration** — Follow the patterns in this file. Don't invent new ones unless the scenario demands it.
3. **Test Everything** — Every demo must pass preflight, smoke, and telemetry tests before it's considered done.
4. **Ephemeral by Design** — Demos spin up fast and tear down clean. No persistent state, no snowflake infra.
5. **Credentials Never in Code** — All secrets come from `.env`. Period.

## 10-Step Workflow

Follow these steps sequentially when building a demo:

### Step 1: Understand the Scenario
- Ask the SE what they're demoing (product, integration, use case)
- Identify what services/applications are needed
- Determine if cloud infrastructure (AWS/Azure/GCP) is required or if Docker-only suffices
- Clarify which telemetry signals matter most (metrics, logs, traces, or all three)

### Step 2: Configure .env
- Copy `.env.example` to `.env`
- Add any demo-specific environment variables to both `.env` and `.env.example`
- Never put real credentials in `.env.example` — only placeholders

### Step 3: Build Docker Compose Services
- Add application services to `docker-compose.yml`
- Follow the conventions below for health checks, networking, and image tags
- The Alloy service is already configured — just add your application services

### Step 4: Configure Alloy Pipelines
- Edit `alloy/config.alloy` to collect telemetry from your services
- Uncomment and adapt the pipeline templates for your use case
- Ensure all three signal types (metrics, logs, traces) have pipelines if the demo uses them

### Step 5: Add Terraform Resources (if needed)
- Only if the demo requires cloud infrastructure (databases, VMs, managed services)
- Uncomment the relevant provider in `terraform/providers.tf`
- Add variables, resources, and outputs
- Skip this step entirely for Docker-only demos

### Step 6: Update Scripts
- `scripts/start-demo.sh` and `scripts/stop-demo.sh` may need demo-specific steps
- Add any initialization, data seeding, or cleanup commands
- Keep preflight-check.sh updated if you add new prerequisites

### Step 7: Write Tests
- Add demo-specific BATS tests to the existing test files
- `tests/smoke.bats` — verify your services are running and healthy
- `tests/telemetry.bats` — verify your telemetry is flowing
- Tests must pass before the demo is considered done

### Step 8: Create k6 Load Tests
- Edit `k6/load-test.js` to generate realistic traffic for your demo
- Target the endpoints that produce interesting telemetry
- Configure thresholds that match your demo narrative

### Step 9: Update README
- Document what this specific demo does
- List any additional prerequisites
- Add scenario-specific instructions

### Step 10: Dashboards
- Tell the SE: "Use Grafana Assistant in your Grafana Cloud instance to build dashboards for this demo"
- After the SE builds dashboards, they should:
  1. Export the dashboard JSON from Grafana (Share → Export → Save to file)
  2. Save it to `dashboards/<dashboard-name>.json`
  3. Update `dashboards/README.md` with import instructions
- Do NOT attempt to build Grafana dashboards programmatically — Grafana Assistant does this better interactively

## Docker Compose Conventions

### Service Structure
```yaml
services:
  my-service:
    image: vendor/image:1.2.3          # Always pin to a specific version
    container_name: demo-my-service     # Prefix with "demo-" for clarity
    restart: unless-stopped
    ports:
      - "8080:8080"                     # Host:Container
    environment:
      - ENV_VAR=${ENV_VAR}              # Reference .env variables
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    depends_on:
      alloy:
        condition: service_healthy
    networks:
      - demo
```

### Rules
- **Every service must have a health check** — this is how tests verify readiness
- **Use `depends_on` with `condition: service_healthy`** — not just `depends_on: [service]`
- **All services on the `demo` bridge network** — so they can reach each other by container name
- **Pin image versions** — never use `:latest`
- **Prefix container names with `demo-`** — avoids conflicts with other local containers
- **Use `restart: unless-stopped`** — resilient to transient failures during demos
- **Reference `.env` for all configuration** — `${VAR_NAME}` syntax in compose

### OTLP Configuration
Application services should send telemetry to Alloy via OTLP:
- gRPC: `http://alloy:4317`
- HTTP: `http://alloy:4318`

Use the container name `alloy` (not `localhost`) because services communicate over the Docker bridge network.

## Alloy Pipeline Patterns

### Metrics (Prometheus remote write)
```alloy
prometheus.remote_write "grafana_cloud" {
  endpoint {
    url = env("GRAFANA_METRICS_URL")
    basic_auth {
      username = env("GRAFANA_METRICS_USERNAME")
      password = env("GRAFANA_METRICS_API_KEY")
    }
  }
}
```

### Logs (Loki)
```alloy
loki.write "grafana_cloud" {
  endpoint {
    url = env("GRAFANA_LOGS_URL")
    basic_auth {
      username = env("GRAFANA_LOGS_USERNAME")
      password = env("GRAFANA_LOGS_API_KEY")
    }
  }
}
```

### Traces (Tempo via OTLP)
```alloy
otelcol.exporter.otlp "grafana_cloud" {
  client {
    endpoint = env("GRAFANA_TRACES_URL")
    auth     = otelcol.auth.basic.grafana_cloud.handler
  }
}

otelcol.auth.basic "grafana_cloud" {
  username = env("GRAFANA_TRACES_USERNAME")
  password = env("GRAFANA_TRACES_API_KEY")
}
```

### Collecting from Docker containers
```alloy
// Scrape Prometheus metrics from a service
prometheus.scrape "my_service" {
  targets    = [{"__address__" = "demo-my-service:8080"}]
  forward_to = [prometheus.remote_write.grafana_cloud.receiver]
  metrics_path = "/metrics"
  scrape_interval = "15s"
}

// Collect Docker container logs
loki.source.docker "containers" {
  host = "unix:///var/run/docker.sock"
  targets = discovery.docker.containers.targets
  forward_to = [loki.write.grafana_cloud.receiver]
}

// Receive OTLP traces from application services
otelcol.receiver.otlp "default" {
  grpc { endpoint = "0.0.0.0:4317" }
  http { endpoint = "0.0.0.0:4318" }
  output {
    traces = [otelcol.exporter.otlp.grafana_cloud.input]
  }
}
```

## Terraform Conventions

### When to Use Terraform
- The demo needs cloud resources (RDS, EC2, AKS, GCS, etc.)
- The demo needs the Grafana Terraform provider to provision dashboards/alerts programmatically
- Docker-only demos should NOT use Terraform

### Structure
- `providers.tf` — uncomment the provider(s) you need
- `variables.tf` — declare all variables with descriptions and types
- `main.tf` — resources and modules
- `outputs.tf` — expose endpoints, IDs, connection strings
- `terraform.tfvars.example` — example values (never real secrets)

### State
- Local state only (`terraform.tfstate` in the `terraform/` directory)
- `.gitignore` excludes state files
- No remote backends — demos are ephemeral

### Variables
- Use `TF_VAR_` prefix in `.env` for Terraform variables that come from secrets
- Non-secret variables go in `terraform.tfvars`

## Testing Requirements

### Test Levels
1. **Preflight** (`tests/preflight.bats`) — Can this demo even run here?
   - Required tools installed (docker, docker compose, gh)
   - `.env` file exists and has required variables
   - Optional tools present (terraform, k6) — warn, don't fail

2. **Smoke** (`tests/smoke.bats`) — Is the demo running?
   - All containers are running
   - All containers pass health checks
   - Key ports are accessible
   - UIs load (HTTP 200)

3. **Telemetry** (`tests/telemetry.bats`) — Is data flowing?
   - Alloy's internal metrics show samples being sent
   - No persistent remote_write errors
   - Demo-specific metrics/logs/traces are present

### BATS Patterns
```bash
@test "docker is installed" {
  command -v docker
}

@test "alloy container is running" {
  run docker compose ps --format json alloy
  [ "$status" -eq 0 ]
  echo "$output" | grep -q '"State":"running"'
}

@test "alloy is healthy" {
  run docker inspect --format='{{.State.Health.Status}}' demo-alloy
  [ "$output" = "healthy" ]
}

@test "metrics are flowing" {
  # Check Alloy's internal metrics endpoint
  run curl -sf http://localhost:12345/metrics
  [ "$status" -eq 0 ]
  echo "$output" | grep -q 'prometheus_remote_write_samples_total'
}
```

## k6 Load Testing Patterns

### Standard Test Shape
```javascript
export const options = {
  stages: [
    { duration: '30s', target: 10 },   // Ramp up
    { duration: '1m',  target: 10 },   // Hold steady
    { duration: '30s', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],   // 95% of requests under 500ms
    http_req_failed: ['rate<0.01'],     // Less than 1% failure rate
  },
};
```

### Usage
```bash
# Run locally
k6 run k6/load-test.js

# Run with Grafana Cloud k6
K6_CLOUD_TOKEN=<token> k6 cloud k6/load-test.js
```

## GitHub Issue Workflow

When the SE wants to track work or improvements:
1. Create issues using `gh issue create`
2. Use labels: `demo`, `bug`, `enhancement`, `telemetry`, `infra`
3. Reference issues in commit messages
4. Close issues when the work is done

## Dashboard Workflow

Dashboards are a **first-class shareable artifact** in this template:

1. **Build**: SE uses Grafana Assistant in their Grafana Cloud instance to create dashboards
2. **Export**: Dashboard → Share → Export → Save to file
3. **Commit**: Save JSON to `dashboards/<descriptive-name>.json`
4. **Document**: Update `dashboards/README.md` with:
   - Dashboard name and description
   - Import instructions (Dashboards → New → Import → Upload JSON)
   - Screenshots (optional but helpful)
5. **Share**: Other SEs can import these dashboards into their own Grafana Cloud instances

This approach works because:
- Grafana Assistant builds better dashboards interactively than any code generation
- JSON export/import is a native Grafana capability
- Committed dashboards travel with the demo repo
- Any SE can import them in seconds

## Cross-Platform Notes

- Scripts use `#!/usr/bin/env bash` for portability
- Use `docker compose` (V2, space) not `docker-compose` (V1, hyphen)
- Makefile wraps scripts so Windows users can run scripts directly
- Avoid GNU-specific flags (`sed -i` differs between macOS and Linux)
- Test with `command -v` not `which` (more portable)

## DO NOT

- **Do not build Grafana dashboards programmatically** — use Grafana Assistant + export workflow
- **Do not configure Pyroscope** — out of scope for this template
- **Do not hardcode credentials** — everything comes from `.env`
- **Do not use `:latest` tags** — always pin image versions
- **Do not use Docker Compose V1** — `docker-compose` is deprecated
- **Do not add remote Terraform backends** — local state only
- **Do not skip health checks** — every Docker service needs one
- **Do not commit `.env` files** — `.gitignore` prevents this, don't override it
- **Do not over-engineer** — a working demo today beats a perfect demo next week
