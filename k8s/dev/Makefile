.PHONY: help deploy delete status logs build-images

KUBECTL=secuops kubectl

help:
	@echo "SecuMon K8s Deployment - Dev Environment"
	@echo ""
	@echo "Available targets:"
	@echo "  deploy        - Deploy all SecuMon services"
	@echo "  delete        - Delete all SecuMon resources"
	@echo "  status        - Show status of all resources"
	@echo "  logs-api      - Show API logs"
	@echo "  logs-ingestion - Show Ingestion logs"
	@echo "  logs-alerting  - Show Alerting logs"
	@echo "  build-images  - Build Docker images"

deploy:
	@echo "Deploying SecuMon to k8s-dev..."
	$(KUBECTL) apply -f 00-namespace.yaml
	$(KUBECTL) apply -f 04-secrets.yaml
	$(KUBECTL) apply -f 01-timescaledb.yaml
	$(KUBECTL) apply -f 02-redis.yaml
	@echo "Waiting for TimescaleDB to be ready..."
	$(KUBECTL) wait --for=condition=ready pod -l app=timescaledb -n secumon --timeout=300s || true
	@echo "Deploying Grafana..."
	$(KUBECTL) apply -f 03-grafana.yaml
	@echo "Deploying SecuMon services..."
	$(KUBECTL) apply -f 05-ingestion.yaml
	$(KUBECTL) apply -f 06-api.yaml
	$(KUBECTL) apply -f 07-alerting.yaml
	$(KUBECTL) apply -f 08-ingress.yaml
	@echo "Deployment complete!"

delete:
	@echo "Deleting SecuMon from k8s-dev..."
	$(KUBECTL) delete -f 08-ingress.yaml --ignore-not-found=true
	$(KUBECTL) delete -f 07-alerting.yaml --ignore-not-found=true
	$(KUBECTL) delete -f 06-api.yaml --ignore-not-found=true
	$(KUBECTL) delete -f 05-ingestion.yaml --ignore-not-found=true
	$(KUBECTL) delete -f 03-grafana.yaml --ignore-not-found=true
	$(KUBECTL) delete -f 02-redis.yaml --ignore-not-found=true
	$(KUBECTL) delete -f 01-timescaledb.yaml --ignore-not-found=true
	$(KUBECTL) delete -f 04-secrets.yaml --ignore-not-found=true
	$(KUBECTL) delete -f 00-namespace.yaml --ignore-not-found=true
	@echo "Deletion complete!"

status:
	@echo "=== Namespace ==="
	$(KUBECTL) get namespace secumon || echo "Namespace not found"
	@echo ""
	@echo "=== Pods ==="
	$(KUBECTL) get pods -n secumon
	@echo ""
	@echo "=== Services ==="
	$(KUBECTL) get svc -n secumon
	@echo ""
	@echo "=== Ingress ==="
	$(KUBECTL) get ingress -n secumon
	@echo ""
	@echo "=== PVCs ==="
	$(KUBECTL) get pvc -n secumon

logs-api:
	$(KUBECTL) logs -n secumon -l app=secumon-api -f --tail=100

logs-ingestion:
	$(KUBECTL) logs -n secumon -l app=secumon-ingestion -f --tail=100

logs-alerting:
	$(KUBECTL) logs -n secumon -l app=secumon-alerting -f --tail=100

build-images:
	@echo "Building Docker images..."
	cd ../../secumon-collector && ./build-push-images.sh latest
