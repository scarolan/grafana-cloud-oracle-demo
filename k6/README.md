# k6 Load Tests

Load tests generate realistic traffic for your demo, producing telemetry data that shows up in Grafana dashboards.

## Prerequisites

Install k6: https://grafana.com/docs/k6/latest/set-up/install-k6/

```bash
# macOS
brew install k6

# Ubuntu/Debian
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6

# Docker
docker run --rm -i grafana/k6:0.54.0 run - <k6/load-test.js
```

## Running Locally

```bash
# Default (targets http://localhost:12345)
make load-test

# Custom Alloy URL
ALLOY_URL=http://localhost:12345 k6 run k6/load-test.js
```

## Running in Grafana Cloud k6

```bash
K6_CLOUD_TOKEN=<your-token> k6 cloud k6/load-test.js
```

Get your token from: grafana.com > My Account > k6 Cloud > API Token

## Customizing

Edit `k6/load-test.js` to:

1. **Target your demo's endpoints** — Replace the example health check with real API calls
2. **Adjust the load profile** — Modify `stages` for different ramp-up/hold/ramp-down patterns
3. **Set thresholds** — Define what "acceptable performance" means for your demo
4. **Add checks** — Validate response bodies, headers, and status codes
