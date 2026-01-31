#!/bin/bash

# SecuMon Setup Script
# This script initializes the SecuMon development environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "========================================"
echo "SecuMon Setup Script"
echo "========================================"
echo ""

# Check prerequisites
echo "==> Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    exit 1
fi
echo "✓ Docker found"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed"
    exit 1
fi
echo "✓ Docker Compose found"

# Check Go (optional)
if command -v go &> /dev/null; then
    echo "✓ Go found ($(go version))"
else
    echo "⚠ Go not found (optional for building agents)"
fi

# Check git
if ! command -v git &> /dev/null; then
    echo "Error: Git is not installed"
    exit 1
fi
echo "✓ Git found"

echo ""
echo "==> Creating directory structure..."
cd "$PROJECT_ROOT"
mkdir -p bin logs scripts deploy/{k8s,docker} .github/workflows

echo ""
echo "==> Creating .env file from example..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ Created .env file (please edit with your configuration)"
else
    echo "⚠ .env file already exists (skipping)"
fi

echo ""
echo "==> Checking for sub-projects..."
SUBPROJECTS=("secumon-common" "secumon-probe" "secumon-agent" "secumon-collector" "secumon-web")
MISSING_PROJECTS=()

for project in "${SUBPROJECTS[@]}"; do
    if [ -d "$project" ]; then
        echo "✓ $project found"
    else
        echo "⚠ $project not found"
        MISSING_PROJECTS+=("$project")
    fi
done

if [ ${#MISSING_PROJECTS[@]} -gt 0 ]; then
    echo ""
    echo "Missing sub-projects detected. Would you like to clone them? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "==> Cloning sub-projects..."
        for project in "${MISSING_PROJECTS[@]}"; do
            echo "Cloning $project..."
            git clone "git@github.com:secuaas/$project.git" 2>&1 || echo "Note: $project repo may not exist yet"
        done
    fi
fi

echo ""
echo "==> Starting Docker Compose services..."
docker-compose -f docker-compose.dev.yml up -d

echo ""
echo "==> Waiting for services to be healthy..."
sleep 10

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "Services running:"
echo "  - PostgreSQL:    localhost:5432"
echo "  - TimescaleDB:   localhost:5433"
echo "  - Redis:         localhost:6379"
echo "  - NATS:          localhost:4222"
echo "  - Loki:          localhost:3100"
echo "  - Grafana:       http://localhost:3001 (admin/admin)"
echo "  - Adminer:       http://localhost:8081"
echo ""
echo "Next steps:"
echo "  1. Edit .env file with your configuration"
echo "  2. Build agents: make build"
echo "  3. Run tests: make test"
echo ""
echo "For more commands, run: make help"
echo ""
