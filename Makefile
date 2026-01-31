.PHONY: help init clone build test clean docker deploy

help:
	@echo "SecuMon - Makefile Commands"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make init        - Initialize project (create dirs, download dependencies)"
	@echo "  make clone       - Clone all sub-projects (probe, agent, collector, web, common)"
	@echo ""
	@echo "Build Commands:"
	@echo "  make build       - Build all components"
	@echo "  make build-agent - Build agent binary"
	@echo "  make build-probe - Build probe binary"
	@echo ""
	@echo "Docker Commands:"
	@echo "  make docker      - Build all Docker images"
	@echo "  make docker-up   - Start development environment"
	@echo "  make docker-down - Stop development environment"
	@echo ""
	@echo "Deploy Commands:"
	@echo "  make deploy-dev  - Deploy to K8s dev (via secuops)"
	@echo "  make deploy-prod - Deploy to K8s prod (via secuops)"
	@echo ""
	@echo "Other Commands:"
	@echo "  make test        - Run all tests"
	@echo "  make clean       - Clean build artifacts"

init:
	@echo "==> Initializing SecuMon project..."
	mkdir -p bin logs scripts deploy/{k8s,docker}
	@echo "==> Done"

clone:
	@echo "==> Cloning sub-projects..."
	@if [ ! -d "secumon-common" ]; then \
		git clone git@github.com:secuaas/secumon-common.git || echo "Note: secumon-common repo not yet created"; \
	fi
	@if [ ! -d "secumon-probe" ]; then \
		git clone git@github.com:secuaas/secumon-probe.git || echo "Note: secumon-probe repo not yet created"; \
	fi
	@if [ ! -d "secumon-agent" ]; then \
		git clone git@github.com:secuaas/secumon-agent.git || echo "Note: secumon-agent repo not yet created"; \
	fi
	@if [ ! -d "secumon-collector" ]; then \
		git clone git@github.com:secuaas/secumon-collector.git || echo "Note: secumon-collector repo not yet created"; \
	fi
	@if [ ! -d "secumon-web" ]; then \
		git clone git@github.com:secuaas/secumon-web.git || echo "Note: secumon-web repo not yet created"; \
	fi
	@echo "==> Done"

build: build-agent build-probe

build-agent:
	@echo "==> Building secumon-agent..."
	@if [ -d "secumon-agent" ]; then \
		cd secumon-agent && go build -o ../bin/secumon-agent cmd/agent/main.go; \
	else \
		echo "Error: secumon-agent directory not found. Run 'make clone' first."; \
	fi

build-probe:
	@echo "==> Building secumon-probe..."
	@if [ -d "secumon-probe" ]; then \
		cd secumon-probe && go build -o ../bin/secumon-probe cmd/probe/main.go; \
	else \
		echo "Error: secumon-probe directory not found. Run 'make clone' first."; \
	fi

test:
	@echo "==> Running tests..."
	@if [ -d "secumon-agent" ]; then cd secumon-agent && go test ./...; fi
	@if [ -d "secumon-probe" ]; then cd secumon-probe && go test ./...; fi
	@if [ -d "secumon-collector" ]; then cd secumon-collector && go test ./...; fi
	@echo "==> Done"

docker:
	@echo "==> Building Docker images..."
	@if [ -d "secumon-collector" ]; then \
		cd secumon-collector && docker-compose build; \
	fi
	@echo "==> Done"

docker-up:
	@echo "==> Starting development environment..."
	docker-compose -f docker-compose.dev.yml up -d
	@echo "==> SecuMon dev environment running"
	@echo "==> Web UI: http://localhost:3000"
	@echo "==> API: http://localhost:8080"

docker-down:
	@echo "==> Stopping development environment..."
	docker-compose -f docker-compose.dev.yml down
	@echo "==> Done"

deploy-dev:
	@echo "==> Deploying to K8s dev..."
	secuops deploy --app=secumon-collector --env=k8s-dev
	secuops deploy --app=secumon-web --env=k8s-dev
	@echo "==> Done"

deploy-prod:
	@echo "==> Deploying to K8s prod..."
	@echo "WARNING: You are about to deploy to PRODUCTION"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	secuops deploy --app=secumon-collector --env=k8s-prod
	secuops deploy --app=secumon-web --env=k8s-prod
	@echo "==> Done"

clean:
	@echo "==> Cleaning build artifacts..."
	rm -rf bin/* logs/* coverage/
	@if [ -d "secumon-agent" ]; then cd secumon-agent && go clean; fi
	@if [ -d "secumon-probe" ]; then cd secumon-probe && go clean; fi
	@if [ -d "secumon-collector" ]; then cd secumon-collector && go clean; fi
	@echo "==> Done"
