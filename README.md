# SecuMon - Security Monitoring Platform

Plateforme de monitoring de sécurité et d'infrastructure pour MSP/MSSP, avec capacités de surveillance serveurs, réseau et intégration avec les outils SecuAAS.

## 🎉 État Actuel - v0.3.0 (Phases 1-5 COMPLÈTES)

**Pipeline complète opérationnelle avec monitoring avancé temps réel:**
```
Agent → gRPC → Collector → TimescaleDB → REST API → Grafana Dashboards
                    ↓                        ↓
                Alerting Engine         WebSocket
                    ↓                        ↓
            Email/Slack/Webhook      Real-time Metrics
```

### ✅ Composants fonctionnels:
- **secumon-agent** - Collecte métriques système (CPU, RAM, Disk, Network, Processes)
- **secumon-collector** - Service d'ingestion gRPC + REST API étendue
- **TimescaleDB** - Stockage time-series optimisé (compression, aggregates, retention)
- **REST API** - 44+ endpoints (métriques + alertes + agents CRUD)
- **WebSocket** - Streaming temps réel des métriques
- **Alerting Engine** - Notifications multi-canal (Email, Slack, Webhook)
- **Grafana Dashboards** - 3 dashboards pré-configurés
- **Production Tooling** - Systemd services + Makefile

### 📊 Statistiques:
- **17 commits** - 3 repositories
- **75 fichiers** - ~8000 lignes de code
- **19 tests** unitaires passent
- **4 hypertables** + **4 continuous aggregates** TimescaleDB
- **44+ endpoints** REST API opérationnels
- **1 endpoint** WebSocket temps réel
- **13 jobs** TimescaleDB (compression, retention, refresh)
- **3 dashboards** Grafana prêts à l'emploi

### 📚 Documentation:
- [Deployment Guide](./DEPLOYMENT-GUIDE.md) - Installation et configuration (dev)
- [Production Deployment Guide](./PRODUCTION-DEPLOYMENT-GUIDE.md) - Déploiement production complet
- [API Documentation](./API-DOCUMENTATION.md) - Référence API REST complète

## Vue d'ensemble

SecuMon est une solution complète de monitoring temps réel conçue pour les fournisseurs de services gérés (MSP/MSSP). Elle combine :
- Monitoring de serveurs (métriques système, logs, processus)
- Monitoring réseau (ping, traceroute, ports, SSL/TLS)
- Alerting intelligent en temps réel
- Dashboards de visualisation interactifs
- Intégration native avec SecuOps et SecuScan

## Architecture Globale

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              SECUMON ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐           │
│  │   PROBE-SCANNER  │    │   PROBE-SCANNER  │    │   PROBE-SCANNER  │           │
│  │   (Internet)     │    │   (LAN Client A) │    │   (LAN Client B) │           │
│  │   [Go Binary]    │    │   [Go Binary]    │    │   [Go Binary]    │           │
│  └────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘           │
│           │                       │                       │                      │
│           │ WireGuard Tunnel      │ WireGuard Tunnel      │ WireGuard Tunnel    │
│           │ (Auto-provisioned)    │ (Auto-provisioned)    │ (Auto-provisioned)  │
│           ▼                       ▼                       ▼                      │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                        COLLECTOR NODE (Principal)                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │  WireGuard  │  │   gRPC      │  │  Ingestion  │  │   Alert     │      │   │
│  │  │  Manager    │  │   Gateway   │  │   Engine    │  │   Engine    │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  │                                                                           │   │
│  │  ┌─────────────────────────────────────────────────────────────────┐     │   │
│  │  │                      DATA LAYER                                  │     │   │
│  │  │  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌───────────┐ │     │   │
│  │  │  │ TimescaleDB│  │ PostgreSQL │  │   Loki     │  │   Redis   │ │     │   │
│  │  │  │ (Metrics)  │  │ (Config)   │  │  (Logs)    │  │  (Cache)  │ │     │   │
│  │  │  └────────────┘  └────────────┘  └────────────┘  └───────────┘ │     │   │
│  │  └─────────────────────────────────────────────────────────────────┘     │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│           ▲                       ▲                       ▲                      │
│           │ WireGuard Tunnel      │ WireGuard Tunnel      │ WireGuard Tunnel    │
│           │                       │                       │                      │
│  ┌────────┴─────────┐    ┌────────┴─────────┐    ┌────────┴─────────┐           │
│  │   SECUMON-AGENT  │    │   SECUMON-AGENT  │    │   SECUMON-AGENT  │           │
│  │   (Server 1)     │    │   (Server 2)     │    │   (Server 3)     │           │
│  │   [Go Binary]    │    │   [Go Binary]    │    │   [Go Binary]    │           │
│  │   + Probe Mode   │    │   + Probe Mode   │    │   + Probe Mode   │           │
│  └──────────────────┘    └──────────────────┘    └──────────────────┘           │
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │                           WEB INTERFACE                                   │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │  Dashboard  │  │   Alerts    │  │   Config    │  │   Reports   │      │   │
│  │  │             │  │   Center    │  │   Manager   │  │             │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  │  Auth: MFA + JumpCloud SSO (Super Admin)                                  │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Composants Principaux

### 1. SecuMon-Probe (Sonde Scanner)
- **Type**: Binaire Go cross-compilé (~8MB)
- **Fonction**: Tests externes (ping, traceroute, ports, SSL/TLS, SNMP, HTTP/HTTPS)
- **Déploiement**: N'importe où (Internet, LAN client, cloud)
- **Communication**: gRPC over WireGuard
- **Métriques**: Latence réseau, disponibilité, certificats SSL, validité DNS

**Scans supportés**:
- Tests ICMP (ping, MTR)
- Scan de ports TCP/UDP
- Analyse SSL/TLS (certificats, ciphers, OCSP)
- Requêtes HTTP/HTTPS avec validation
- DNS resolution et propagation
- SNMP (optionnel)

### 2. SecuMon-Agent
- **Type**: Binaire Go ultra-léger (~10MB)
- **Fonction**: Monitoring serveur + mode sonde optionnel
- **Déploiement**: Sur chaque serveur à monitorer
- **Communication**: gRPC over WireGuard
- **Consommation**: <50MB RAM, <1% CPU

**Métriques collectées**:
- CPU (load average, utilisation par core)
- Mémoire (RAM, swap, cache)
- Disques (espace, I/O, IOPS)
- Réseau (bande passante, connexions, erreurs)
- Processus (top CPU/RAM, zombies)
- Services (systemd units, docker containers)
- Logs système (syslog, journald)

### 3. SecuMon-Collector (Nœud Principal)
- **Type**: Services Docker/K8s
- **Fonction**: Agrégation, stockage, alerting, API
- **Déploiement**: Infrastructure centrale OVH ou on-premise client
- **Scalabilité**: Horizontal avec load balancing

**Services inclus**:
- **WireGuard Manager**: Auto-provisioning des tunnels VPN
- **gRPC Gateway**: Ingestion des métriques/logs
- **Ingestion Engine**: Traitement et normalisation des données
- **Alert Engine**: Règles d'alerting configurable avec escalade
- **API REST**: Interface pour la web app et intégrations
- **Workers**: Processing asynchrone des tâches

### 4. SecuMon-Web
- **Type**: Application web SPA (React/Vue 3)
- **Fonction**: Interface de gestion et visualisation
- **Auth**: MFA standard + SSO JumpCloud (super admin)
- **Features**: Dashboards, alertes, configuration, rapports

## Stack Technologique

| Composant | Technologie | Version | Justification |
|-----------|-------------|---------|---------------|
| Probe/Agent | Go | 1.22+ | Performance, cross-compilation, faible empreinte |
| API Backend | Go + Fiber | 2.52+ | Performance, cohérence avec agents |
| Frontend | React/Vue 3 | Latest | Légèreté, réactivité, écosystème |
| Base Metrics | TimescaleDB | 2.14+ | Time-series optimisé, rétention automatique |
| Base Config | PostgreSQL | 16+ | Relationnel, ACID, RLS pour multi-tenant |
| Base Logs | Loki | 2.9+ | Scalable, compatible Grafana |
| Cache/Queue | Redis | 7.2+ | Pub/Sub, cache, rate limiting |
| Message Broker | NATS | 2.10+ | Léger, performant, cloud-native |
| Tunnel | WireGuard | Latest | Sécurité, performance, simplicité |
| Secrets | OVH Secret Manager | - | Intégration native |
| Container | Docker / K8s OVH | - | Orchestration managée |

## Flux de Données

### Flux Métriques (Hot Path)
```
Agent/Probe → gRPC/Protobuf → Collector → NATS → Ingestion Worker → TimescaleDB
                                      ↓
                                   Redis (Real-time cache)
                                      ↓
                                   Alert Engine
```

### Flux Logs (Warm Path)
```
Agent → Compression LZ4 → gRPC Stream → Collector → Loki
```

### Flux Configuration (Cold Path)
```
Web UI → API → PostgreSQL → NATS (Config Update) → Agents/Probes
```

## Rétention des Données

| Type | Granularité | Rétention | Stockage |
|------|-------------|-----------|----------|
| Métriques Raw | 1 minute | 30 jours | TimescaleDB |
| Métriques Agrégées 5min | 5 minutes | 90 jours | TimescaleDB |
| Métriques Agrégées 1h | 1 heure | 365 jours | TimescaleDB |
| Logs | Brut | 30 jours | Loki |
| Logs Compressés | Compressé | 365 jours | S3/OVH Object Storage |
| Alertes | Brut | 365 jours | PostgreSQL |
| Events | Brut | 180 jours | PostgreSQL |

**Politique de compression**:
- Agrégation automatique via continuous aggregates (TimescaleDB)
- Compression chunk-based après 7 jours
- Archive S3/OVH pour données historiques >365 jours

## Sécurité

### Authentification
- **Users Standard**: Email/Password + TOTP MFA
- **Super Admin**: JumpCloud SSO (module existant)
- **Agents/Probes**: Certificats mTLS + Token rotatif (24h)
- **API**: JWT tokens + API keys

### Communication
- Tout le trafic passe par WireGuard (point-to-point encryption)
- gRPC avec TLS mutuel (mTLS)
- Tokens JWT pour l'API web (RS256)
- Rate limiting par tenant et par endpoint

### Secrets
- OVH Secret Manager pour credentials
- Rotation automatique des clés WireGuard (90 jours)
- Chiffrement at-rest pour données sensibles (AES-256-GCM)
- Vault pour certificats et tokens

### Isolation
- Row Level Security (RLS) PostgreSQL pour multi-tenant
- Namespaces K8s séparés par environnement
- Network policies pour segmentation réseau

## Scalabilité

### Horizontal
- **Collectors**: Load balancer (HAProxy/Envoy) + auto-scaling K8s
- **Workers**: Queue-based scaling via NATS (auto-scale sur queue depth)
- **Databases**:
  - TimescaleDB avec replication et sharding
  - PostgreSQL avec read replicas
  - Redis Cluster mode

### Vertical
- Agents optimisés pour faible consommation (<50MB RAM, <1% CPU)
- Compression des données en transit (LZ4)
- Batch processing pour réduire le overhead réseau
- Connection pooling pour bases de données

### Performance Targets
| Métrique | Target | Notes |
|----------|--------|-------|
| Agents supportés | 10,000+ | Par cluster collector |
| Métriques/sec | 100,000+ | Ingestion rate |
| Latence API | <100ms | P95 |
| Latence alerting | <10s | Détection à notification |
| Uptime | 99.9% | SLA monitoring |

## Structure des Repositories

```
secumon/
├── secumon-probe/          # Sonde scanner externe
│   ├── cmd/
│   ├── internal/
│   │   ├── scanner/       # Modules de scan (ping, port, SSL, HTTP)
│   │   ├── wireguard/     # Client WireGuard
│   │   └── grpc/          # Client gRPC
│   └── pkg/
│
├── secumon-agent/          # Agent serveur léger
│   ├── cmd/
│   ├── internal/
│   │   ├── collector/     # Collecteurs métriques système
│   │   ├── probe/         # Mode probe optionnel
│   │   └── grpc/          # Client gRPC
│   └── pkg/
│
├── secumon-collector/      # Nœud principal (services)
│   ├── cmd/
│   │   ├── api/           # API REST
│   │   ├── ingestion/     # Service ingestion
│   │   ├── alerting/      # Service alerting
│   │   └── wireguard/     # Service WireGuard manager
│   ├── internal/
│   │   ├── api/           # Handlers API
│   │   ├── storage/       # Couche stockage (TS, PG, Loki)
│   │   ├── alert/         # Moteur d'alerting
│   │   └── auth/          # Authentification
│   └── migrations/        # Migrations SQL
│
├── secumon-web/            # Interface web
│   ├── src/
│   │   ├── app/           # Pages (React Router / Next.js)
│   │   ├── components/    # Composants UI
│   │   ├── lib/           # Utilities et API client
│   │   └── hooks/         # Custom hooks
│   └── public/
│
├── secumon-common/         # Librairies partagées
│   ├── proto/             # Protobuf definitions
│   ├── auth/              # Auth utils
│   ├── crypto/            # Crypto utils (mTLS, tokens)
│   └── metrics/           # Métriques types
│
└── docs/                  # Documentation
    ├── 00_ARCHITECTURE_OVERVIEW.md
    ├── 01_PROBE_SCANNER.md
    ├── 02_AGENT.md
    ├── 03_COLLECTOR.md
    └── 04_WEB_INTERFACE.md
```

## Intégrations SecuAAS

### SecuOps Integration
SecuMon s'intègre avec SecuOps pour:
- **Déploiement**: Utilisation de `secuops` CLI pour déployer sur K8s OVH
- **DNS**: Configuration automatique via l'API OVH (secuops dns)
- **Monitoring**: SecuOps API expose des métriques infrastructure
- **Alerting**: Alertes SecuMon peuvent déclencher actions SecuOps

**Exemple d'intégration**:
```bash
# Déployer SecuMon collector sur K8s
secuops deploy --app=secumon-collector --env=k8s-prod

# Configurer DNS pour interface web
secuops dns add --zone=secuaas.ovh --domain=monitor --target=<lb-ip>

# Monitorer SecuOps lui-même
secumon-agent --monitor-service=secuops-api
```

### SecuScan Integration
SecuMon peut monitorer les résultats de SecuScan:
- **Scans programmés**: Déclencher scans SecuScan via webhook
- **Métriques sécurité**: Ingérer scores et vulnérabilités dans SecuMon
- **Alerting**: Nouvelles vulnérabilités critiques → alertes SecuMon
- **Dashboards unifiés**: Vue combinée infrastructure + sécurité

**Exemple d'intégration**:
```bash
# Agent SecuMon avec monitoring SecuScan
secumon-agent --integrations=secuscan --secuscan-api=https://api.secuscan.io

# Configurer alerting sur vulnérabilités
# (via SecuMon Web UI ou API)
POST /api/v1/alerts/rules
{
  "name": "Critical Vulnerability Detected",
  "source": "secuscan",
  "condition": "severity >= CRITICAL",
  "actions": ["email", "slack", "pagerduty"]
}
```

## Installation et Déploiement

### Quick Start (Dev)

```bash
# Cloner le repository principal
git clone git@github.com:secuaas/secumon.git
cd secumon

# Cloner les sous-projets
git clone git@github.com:secuaas/secumon-probe.git
git clone git@github.com:secuaas/secumon-agent.git
git clone git@github.com:secuaas/secumon-collector.git
git clone git@github.com:secuaas/secumon-web.git
git clone git@github.com:secuaas/secumon-common.git

# Démarrer l'environnement de dev (Docker Compose)
docker-compose -f docker-compose.dev.yml up -d

# Compiler l'agent (exemple)
cd secumon-agent
go build -o bin/secumon-agent cmd/agent/main.go

# Lancer l'agent localement
./bin/secumon-agent --config=config.dev.yaml
```

### Production Deployment (K8s via SecuOps)

```bash
# Déployer le collector (services backend)
secuops deploy --app=secumon-collector --env=k8s-prod

# Déployer l'interface web
secuops deploy --app=secumon-web --env=k8s-prod

# Configurer le DNS
secuops dns add --zone=secuaas.ovh --domain=monitor --target=<ingress-ip>

# Déployer un agent sur un serveur
# 1. Télécharger le binaire
wget https://releases.secuaas.ovh/secumon-agent/latest/secumon-agent-linux-amd64

# 2. Installer
sudo mv secumon-agent-linux-amd64 /usr/local/bin/secumon-agent
sudo chmod +x /usr/local/bin/secumon-agent

# 3. Configurer
sudo secumon-agent setup --collector=collector.secuaas.ovh:9090

# 4. Démarrer le service
sudo systemctl enable secumon-agent
sudo systemctl start secumon-agent
```

## API REST

L'API REST SecuMon expose les fonctionnalités suivantes:

### Endpoints Principaux

```
# Authentification
POST   /api/v1/auth/login
POST   /api/v1/auth/mfa/verify
POST   /api/v1/auth/refresh

# Agents
GET    /api/v1/agents
GET    /api/v1/agents/:id
POST   /api/v1/agents/provision
DELETE /api/v1/agents/:id

# Métriques
GET    /api/v1/metrics/hosts/:id
GET    /api/v1/metrics/hosts/:id/history
GET    /api/v1/metrics/network/:id

# Alertes
GET    /api/v1/alerts                      # Liste des alertes (avec filtres status/severity)
GET    /api/v1/alerts/stats                # Statistiques des alertes
POST   /api/v1/alerts/:id/acknowledge      # Marquer alerte comme acquittée
GET    /api/v1/alert-rules                 # Liste des règles d'alerting
POST   /api/v1/alert-rules                 # Créer une règle
PUT    /api/v1/alert-rules/:id             # Modifier une règle
DELETE /api/v1/alert-rules/:id             # Supprimer une règle
GET    /api/v1/alert-rules/:id/test        # Tester une règle
GET    /api/v1/alert-rules/:id/history     # Historique d'une règle

# Configuration
GET    /api/v1/config
PUT    /api/v1/config

# Dashboards
GET    /api/v1/dashboards
POST   /api/v1/dashboards
GET    /api/v1/dashboards/:id

# Intégrations
GET    /api/v1/integrations
POST   /api/v1/integrations/secuops
POST   /api/v1/integrations/secuscan
```

### Exemple d'utilisation

```bash
# Login
TOKEN=$(curl -X POST https://monitor.secuaas.ovh/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"xxx"}' | jq -r .token)

# Lister les agents
curl -H "Authorization: Bearer $TOKEN" \
  https://monitor.secuaas.ovh/api/v1/agents

# Obtenir métriques d'un host
curl -H "Authorization: Bearer $TOKEN" \
  "https://monitor.secuaas.ovh/api/v1/metrics/hosts/srv-prod-01?period=1h"
```

## Configuration

### Agent Configuration (YAML)

```yaml
# /etc/secumon/agent.yaml
agent:
  name: "srv-prod-01"
  labels:
    environment: production
    datacenter: bhs
    role: webserver

collector:
  endpoint: "collector.secuaas.ovh:9090"
  tls:
    enabled: true
    cert: "/etc/secumon/agent.crt"
    key: "/etc/secumon/agent.key"
    ca: "/etc/secumon/ca.crt"

metrics:
  interval: 60s
  enabled:
    - cpu
    - memory
    - disk
    - network
    - processes
    - services

logs:
  enabled: true
  sources:
    - /var/log/syslog
    - /var/log/auth.log
    - /var/log/nginx/*.log

probe_mode:
  enabled: true
  targets:
    - type: http
      url: "https://example.com"
      interval: 5m
    - type: tcp
      host: "example.com"
      port: 443
      interval: 1m
```

### Collector Configuration (ENV)

```bash
# Database
POSTGRES_HOST=postgres.secuaas.ovh
POSTGRES_PORT=5432
POSTGRES_DB=secumon
POSTGRES_USER=secumon
POSTGRES_PASSWORD=<secret>

TIMESCALE_HOST=timescale.secuaas.ovh
TIMESCALE_PORT=5432
TIMESCALE_DB=metrics
TIMESCALE_USER=metrics_writer
TIMESCALE_PASSWORD=<secret>

# Redis
REDIS_HOST=redis.secuaas.ovh
REDIS_PORT=6379
REDIS_PASSWORD=<secret>

# NATS
NATS_URL=nats://nats.secuaas.ovh:4222

# Loki
LOKI_URL=http://loki.secuaas.ovh:3100

# Auth
JWT_SECRET=<secret>
JWT_EXPIRY=24h

# WireGuard
WIREGUARD_INTERFACE=wg0
WIREGUARD_PORT=51820
WIREGUARD_SUBNET=10.200.0.0/16

# API
API_PORT=8080
API_TLS_CERT=/certs/tls.crt
API_TLS_KEY=/certs/tls.key
```

## Grafana Dashboards

SecuMon inclut 3 dashboards Grafana pré-configurés avec connexion automatique à TimescaleDB:

### 1. System Overview Dashboard
- **Active Agents**: Nombre d'agents connectés
- **Metrics Rate**: Métriques par minute ingérées
- **CPU Usage**: Timeline de l'utilisation CPU
- **Memory Usage**: Timeline de la mémoire
- **Load Average**: Charge système
- **Disk Usage**: Gauges par filesystem

### 2. Network & Process Dashboard
- **Network Traffic**: Timeline du trafic in/out
- **Network Errors**: Erreurs et drops
- **Network Interfaces**: Table de statut des interfaces
- **Active Processes**: Nombre de processus actifs
- **Top Processes**: Table des top CPU/Memory
- **Network Connections**: Connexions actives

### 3. Alerts Dashboard
- **Alert Counters**: Total, actives, acknowledged
- **Active Alerts**: Table des alertes en cours
- **Alert Frequency**: Timeline des alertes
- **Severity Distribution**: Pie chart par sévérité
- **Alert Rules**: Table des règles configurées
- **Alert Response Time**: Temps de réponse moyen

### Installation Grafana

```bash
# Démarrer Grafana (Docker)
docker run -d -p 3000:3000 \
  -v ./grafana/dashboards:/etc/grafana/provisioning/dashboards \
  -v ./grafana/datasources:/etc/grafana/provisioning/datasources \
  --name secumon-grafana \
  grafana/grafana:latest

# Accès: http://localhost:3000
# Login par défaut: admin / admin
```

Les datasources et dashboards sont provisionnés automatiquement au démarrage.

## Production Deployment

SecuMon est production-ready avec des outils de déploiement complets:

### Makefile Production

```bash
# Compiler tous les binaires pour production (Linux amd64)
make -f Makefile.production build-all

# Installer les binaires dans /usr/local/bin
sudo make -f Makefile.production install

# Déployer les services systemd
sudo make -f Makefile.production deploy-systemd

# Vérifier le statut de tous les services
sudo make -f Makefile.production status
```

### Services Systemd

4 services systemd sécurisés inclus:
- **secumon-ingestion.service**: Service d'ingestion gRPC (port 9090)
- **secumon-api.service**: API REST (port 8080)
- **secumon-alerting.service**: Moteur d'alerting
- **secumon-agent.service**: Agent local (optionnel)

Tous les services incluent:
- Security hardening (NoNewPrivileges, PrivateTmp, ProtectSystem)
- Auto-restart avec backoff
- Logging vers journald
- Configuration via fichiers .env

### Configuration Production

Copier et éditer les fichiers d'exemple:

```bash
sudo mkdir -p /etc/secumon
sudo cp deploy/config/ingestion.env.example /etc/secumon/ingestion.env
sudo cp deploy/config/api.env.example /etc/secumon/api.env
sudo cp deploy/config/alerting.env.example /etc/secumon/alerting.env

# Éditer avec vos valeurs de production
sudo nano /etc/secumon/ingestion.env
sudo nano /etc/secumon/api.env
sudo nano /etc/secumon/alerting.env
```

### Multi-Channel Alerting

Le moteur d'alerting supporte 3 canaux de notification:

**1. Email (SMTP)**
```bash
# Dans /etc/secumon/alerting.env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=alerts@yourdomain.com
SMTP_PASS=your_app_password
EMAIL_FROM=alerts@yourdomain.com
EMAIL_FROM_NAME=SecuMon Alerts
EMAIL_TO=admin@yourdomain.com,ops@yourdomain.com
```

**2. Slack Webhook**
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

**3. Generic Webhook**
```bash
WEBHOOK_URL=https://your-webhook-endpoint.com/alerts
```

Les emails incluent un template HTML avec styling selon la sévérité (critical=rouge, warning=orange, info=bleu).

## Roadmap et Développement

### Phase 1: Foundation (Semaines 1-6)
- [x] Architecture et design documents
- [ ] secumon-common (proto, auth, crypto)
- [ ] secumon-collector (core services)
- [ ] WireGuard auto-provisioning
- [ ] Base PostgreSQL + TimescaleDB
- [ ] Tests unitaires foundation

### Phase 2: Agents (Semaines 7-12)
- [ ] secumon-agent (monitoring système)
- [ ] secumon-probe (scans externes)
- [ ] Protocol gRPC complet
- [ ] Tests d'intégration
- [ ] Binaries cross-compilés (Linux, Windows, macOS)

### Phase 3: Web Interface (Semaines 13-18)
- [ ] API REST complète
- [ ] Frontend React/Vue 3
- [ ] Auth MFA + JumpCloud integration
- [ ] Dashboards interactifs
- [ ] Configuration UI

### Phase 4: Advanced Features (Semaines 19-24)
- [x] Alerting avancé avec notifications multi-canal (Email, Slack, Webhook)
- [x] API complète pour alertes (CRUD sur règles et historique)
- [x] Grafana dashboards (System Overview, Network/Process, Alerts)
- [x] Production deployment (Systemd services, Makefile, env configs)
- [ ] Rapports automatisés (PDF, Excel)
- [ ] Multi-tenancy complet avec RLS
- [ ] Intégrations SecuOps/SecuScan avancées
- [ ] Escalade automatique des alertes

### Phase 5: Production (Semaines 25-28)
- [ ] Déploiement K8s OVH (via SecuOps)
- [ ] Monitoring de la plateforme elle-même (dogfooding)
- [ ] Documentation utilisateur complète
- [ ] Tests de charge et performance
- [ ] CI/CD pipeline
- [ ] Disaster recovery procedures

## Support et Documentation

- **Documentation**: [/docs](/docs)
- **Architecture**: [docs/00_ARCHITECTURE_OVERVIEW.md](docs/00_ARCHITECTURE_OVERVIEW.md)
- **API Reference**: [docs/API.md](docs/API.md)
- **Issues**: GitHub Issues dans chaque sous-projet
- **Discussions**: GitHub Discussions

## Contribution

Ce projet fait partie de l'écosystème SecuAAS et est développé en interne.

Pour contribuer:
1. Créer une branche feature/fix
2. Faire vos modifications avec tests
3. Ouvrir une Pull Request
4. Attendre review et merge

## Licence

Private - SecuAAS © 2026

## Contact

- **Organisation**: secuaas
- **GitHub**: https://github.com/secuaas
- **Email**: support@secuaas.ovh
