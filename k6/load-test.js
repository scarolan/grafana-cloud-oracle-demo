import http from 'k6/http';
import { check, sleep } from 'k6';

// =============================================================================
// k6 Load Test — Oracle Demo
// =============================================================================
// Verifies the Alloy telemetry pipeline is working by polling the metrics
// endpoint and checking that Oracle metrics are flowing.
//
// The actual database load comes from the generate_load procedure.
// This k6 test serves as an end-to-end verification that metrics are being
// collected and can also stress-test the metrics pipeline itself.
//
// Run locally:   k6 run k6/load-test.js
// Run in cloud:  K6_CLOUD_TOKEN=<token> k6 cloud k6/load-test.js
// =============================================================================

export const options = {
  stages: [
    { duration: '30s', target: 10 },  // Ramp up to 10 virtual users
    { duration: '1m', target: 10 },   // Hold steady at 10 VUs
    { duration: '30s', target: 0 },   // Ramp down to 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],  // 95% of requests complete under 500ms
    http_req_failed: ['rate<0.01'],    // Less than 1% failure rate
  },
};

const ALLOY_URL = __ENV.ALLOY_URL || 'http://localhost:12345';

export default function () {
  // Check Alloy readiness
  const readyRes = http.get(`${ALLOY_URL}/-/ready`);
  check(readyRes, {
    'alloy is ready': (r) => r.status === 200,
  });

  // Check Alloy metrics endpoint — this is the main pipeline verification
  const metricsRes = http.get(`${ALLOY_URL}/metrics`);
  check(metricsRes, {
    'metrics endpoint returns 200': (r) => r.status === 200,
    'metrics contain alloy_build_info': (r) => r.body.includes('alloy_build_info'),
    'metrics contain remote_write data': (r) => r.body.includes('prometheus_remote_storage_samples_total'),
    'scrape targets active': (r) => r.body.includes('scrape_samples_scraped'),
  });

  // Simulate user think time
  sleep(1);
}
