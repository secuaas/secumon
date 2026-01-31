# SecuMon - Guide de Déploiement

## Vue d'ensemble

SecuMon est une plateforme de monitoring complète pour MSP/MSSP avec:
- **Agent** - Collecte de métriques système (CPU, RAM, Disk, Network, Processes)
- **Collector** - Ingestion gRPC et stockage TimescaleDB
- **API REST** - Queries et visualisation des métriques

## Architecture

```
┌─────────────┐  gRPC    ┌──────────────┐  pgxpool  ┌──────────────┐
│   Agent     │ ────────>│  Collector   │ ─────────>│ TimescaleDB  │
│ (Go 1.24)   │          │  Ingestion   │           │  (Postgres)  │
└─────────────┘          └──────────────┘           └──────────────┘
                                │                            │
                                │                            │
                                v                            v
                         ┌──────────────┐           ┌──────────────┐
                         │   API REST   │ <─────────│  Hypertables │
                         │  (Fiber v2)  │           │   Metrics    │
                         └──────────────┘           └──────────────┘
```

## Installation

### Prérequis

- Go 1.24+
- Docker & Docker Compose
- PostgreSQL 16 avec TimescaleDB extension

### 1. Infrastructure (Docker Compose)

```bash
cd /home/ubuntu/projects/secumon
docker compose -f docker-compose.dev.yml up -d
```

Services démarrés:
- TimescaleDB sur port **5433**
- PostgreSQL sur port **5434**
- Redis sur port **6380**
- NATS sur port **4222**
- Loki sur port **3100**
- Grafana sur port **3000**
- Adminer sur port **8082**

### 2. Base de données TimescaleDB

Créer les tables (déjà fait):

```bash
psql -h localhost -p 5433 -U metrics_writer -d metrics < /path/to/create_timescale_tables.sql
```

Tables créées:
- `metrics` - Métriques CPU/Memory (key-value model)
- `disk_metrics` - Métriques disque par partition
- `network_metrics` - Métriques réseau par interface
- `process_metrics` - Top processes par CPU

### 3. Compiler les services

**secumon-common** (librairie partagée):
```bash
cd /home/ubuntu/projects/secumon-common
go mod tidy
go test ./...
```

**secumon-agent** (collecteur système):
```bash
cd /home/ubuntu/projects/secumon-agent
go mod tidy
go build -o bin/agent ./cmd/agent
```

**secumon-collector** (backend):
```bash
cd /home/ubuntu/projects/secumon-collector
go mod tidy
go build -o bin/ingestion ./cmd/ingestion
go build -o bin/api ./cmd/api
```

## Démarrage des services

### 1. Service d'Ingestion gRPC

```bash
cd /home/ubuntu/projects/secumon-collector
./bin/ingestion \
  --port 9090 \
  --db-host localhost \
  --db-port 5433 \
  --db-user metrics_writer \
  --db-password metrics_dev_pass \
  --db-name metrics \
  --db-sslmode disable \
  --log-level info
```

Écoute sur: **:9090** (gRPC)

### 2. API REST

```bash
cd /home/ubuntu/projects/secumon-collector
API_PORT=8080 \
DB_HOST=localhost \
DB_USER=metrics_writer \
DB_PASSWORD=metrics_dev_pass \
DB_NAME=metrics \
./bin/api
```

Écoute sur: **:8080** (HTTP)

### 3. Agent (sur chaque serveur à monitorer)

```bash
cd /home/ubuntu/projects/secumon-agent
./bin/agent \
  --config /etc/secumon/agent.yaml \
  --log-level info
```

Configuration par défaut:
- Collector: `localhost:9090`
- Intervalle: `60s`
- Métriques: CPU, Memory, Disk, Network, Processes

## Endpoints API REST

### Health Check
```bash
curl http://localhost:8080/health
```

### Liste des agents actifs
```bash
curl http://localhost:8080/api/v1/agents
```

### Dernières métriques
```bash
curl "http://localhost:8080/api/v1/metrics/latest/AGENT_ID?limit=100"
```

### Métriques par plage de temps
```bash
curl "http://localhost:8080/api/v1/metrics/range/AGENT_ID?start=2024-01-01T00:00:00Z&end=2024-01-02T00:00:00Z&limit=1000"
```

### Métriques disque
```bash
curl "http://localhost:8080/api/v1/metrics/disk/AGENT_ID?limit=100"
```

### Métriques réseau
```bash
curl "http://localhost:8080/api/v1/metrics/network/AGENT_ID?limit=100"
```

### Métriques processus (top CPU)
```bash
curl "http://localhost:8080/api/v1/metrics/process/AGENT_ID?limit=20"
```

## Configuration

### Agent (agent.yaml)

```yaml
agent:
  name: "server-001"
  labels:
    env: "production"
    role: "web"

collector:
  endpoint: "collector.example.com:9090"
  tls:
    enabled: false
    cert: "/etc/secumon/certs/agent.crt"
    key: "/etc/secumon/certs/agent.key"
    ca: "/etc/secumon/certs/ca.crt"

metrics:
  interval: 60s
  enabled:
    - cpu
    - memory
    - disk
    - network
    - processes

logs:
  enabled: false

probe_mode:
  enabled: false
```

### Service Systemd (agent)

```ini
[Unit]
Description=SecuMon Agent
After=network.target

[Service]
Type=simple
User=secumon
Group=secumon
ExecStart=/usr/local/bin/secumon-agent --config /etc/secumon/agent.yaml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

## Monitoring

### Vérifier l'ingestion gRPC

```bash
# Logs du service ingestion
journalctl -u secumon-ingestion -f
```

Rechercher:
- `Connected to TimescaleDB`
- `gRPC services registered`
- `[AGENT_ID] CPU: X.XX%` (métriques reçues)
- `[AGENT_ID] Metrics stored successfully`

### Vérifier le stockage TimescaleDB

```sql
-- Dernières métriques
SELECT time, agent_id, metric_type, metric_name, value
FROM metrics
ORDER BY time DESC
LIMIT 10;

-- Métriques par agent
SELECT agent_id, COUNT(*) as metric_count
FROM metrics
WHERE time > NOW() - INTERVAL '1 hour'
GROUP BY agent_id;

-- Usage disque récent
SELECT time, device, mount_point, usage_percent
FROM disk_metrics
WHERE agent_id = 'server-001'
ORDER BY time DESC
LIMIT 5;
```

### Vérifier l'API REST

```bash
# Health check
curl -s http://localhost:8080/health | jq

# Liste des agents
curl -s http://localhost:8080/api/v1/agents | jq

# Métriques récentes
curl -s "http://localhost:8080/api/v1/metrics/latest/server-001?limit=5" | jq
```

## Sécurité

### TLS pour gRPC

1. Générer certificats CA, serveur, et agents
2. Configurer `collector.tls.enabled = true` dans agent.yaml
3. Copier certificats dans `/etc/secumon/certs/`
4. Redémarrer services

### Authentication JWT (TODO)

API REST utilisera JWT tokens:
- Login: `POST /api/v1/auth/login`
- Refresh: `POST /api/v1/auth/refresh`
- Protected routes: `Authorization: Bearer <token>`

## Performance

### TimescaleDB Optimizations

**Continuous Aggregates** (TODO):
```sql
-- Agrégats 5 minutes
CREATE MATERIALIZED VIEW metrics_5min
WITH (timescaledb.continuous) AS
SELECT time_bucket('5 minutes', time) AS bucket,
       agent_id,
       AVG(value) as value_avg,
       MAX(value) as value_max
FROM metrics
GROUP BY bucket, agent_id;
```

**Retention Policies** (TODO):
```sql
-- Données brutes: 30 jours
SELECT add_retention_policy('metrics', INTERVAL '30 days');

-- Agrégats 5min: 90 jours
SELECT add_retention_policy('metrics_5min', INTERVAL '90 days');
```

**Compression** (TODO):
```sql
-- Compression après 7 jours
ALTER TABLE metrics SET (timescaledb.compress);
SELECT add_compression_policy('metrics', INTERVAL '7 days');
```

## Dépannage

### Agent ne se connecte pas au collector

```bash
# Tester connectivité
telnet collector.example.com 9090

# Vérifier logs agent
journalctl -u secumon-agent -f

# Vérifier certificats TLS si activé
openssl s_client -connect collector.example.com:9090
```

### Métriques non stockées

```bash
# Vérifier logs ingestion
tail -f /var/log/secumon/ingestion.log

# Vérifier connexion TimescaleDB
psql -h localhost -p 5433 -U metrics_writer -d metrics -c "SELECT NOW();"

# Vérifier tables
psql -h localhost -p 5433 -U metrics_writer -d metrics -c "\dt"
```

### API REST lente

```bash
# Vérifier index TimescaleDB
psql -h localhost -p 5433 -U metrics_writer -d metrics -c "\di"

# Analyser requêtes
EXPLAIN ANALYZE
SELECT * FROM metrics
WHERE agent_id = 'server-001'
  AND time > NOW() - INTERVAL '1 hour';
```

## Prochaines étapes

- [ ] Continuous aggregates (downsampling 5min, 1h)
- [ ] Retention policies automatiques
- [ ] Compression TimescaleDB
- [ ] Service alerting avec règles configurables
- [ ] Worker async pour processing
- [ ] NATS pour pub/sub
- [ ] Redis pour caching
- [ ] JWT authentication
- [ ] Frontend web (React/Vue)
- [ ] Grafana dashboards
- [ ] Probe mode (tests externes)
- [ ] WireGuard VPN pour agents distants

## Support

- Documentation: `/docs`
- Issues: GitHub Issues
- Logs: `/var/log/secumon/`
