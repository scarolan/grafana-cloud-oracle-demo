.PHONY: help preflight start stop test test-preflight test-smoke test-telemetry load-test clean

help: ## Show this help message
	@echo "Demo Builder — Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""

preflight: ## Run preflight checks (Docker, .env, tools)
	@./scripts/preflight-check.sh

start: ## Start the demo (preflight -> terraform -> docker -> health check)
	@./scripts/start-demo.sh

stop: ## Stop the demo (docker down -> terraform destroy)
	@./scripts/stop-demo.sh

test: test-preflight test-smoke test-telemetry ## Run all tests

test-preflight: ## Run preflight tests
	@bats tests/preflight.bats

test-smoke: ## Run smoke tests (containers running and healthy)
	@bats tests/smoke.bats

test-telemetry: ## Run telemetry tests (metrics flowing to Grafana Cloud)
	@bats tests/telemetry.bats

load-test: ## Run k6 load test
	@k6 run k6/load-test.js

clean: ## Remove all demo containers, volumes, and networks
	@docker compose down --volumes --remove-orphans 2>/dev/null || true
	@echo "Cleaned up Docker resources."
