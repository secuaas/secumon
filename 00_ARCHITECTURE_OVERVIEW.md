# SecuMon - Architecture Globale

## Vue d'ensemble

SecuMon est une solution de monitoring de serveurs et d'infrastructure réseau conçue pour les MSP/MSSP. Elle se compose de plusieurs modules indépendants qui communiquent via des canaux sécurisés.

## Schéma d'architecture

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
- **Type**: Binaire Go cross-compilé
- **Fonction**: Tests externes (ping, traceroute, ports, SSL, SNMP)
- **Déploiement**: N'importe où (Internet, LAN client)
- **Communication**: gRPC over WireGuard

### 2. SecuMon-Agent
- **Type**: Binaire Go ultra-léger (~10MB)
- **Fonction**: Monitoring serveur + mode sonde optionnel
- **Déploiement**: Sur chaque serveur à monitorer
- **Communication**: gRPC over WireGuard

### 3. SecuMon-Collector (Nœud Principal)
- **Type**: Services Docker/K8s
- **Fonction**: Agrégation, stockage, alerting
- **Déploiement**: Infrastructure centrale ou chez client
- **Scalabilité**: Horizontal avec load balancing

### 4. SecuMon-Web
- **Type**: Application web SPA + API
- **Fonction**: Interface de gestion et visualisation
- **Auth**: MFA standard + SSO JumpCloud

## Stack Technologique

| Composant | Technologie | Justification |
|-----------|-------------|---------------|
| Probe/Agent | Go 1.22+ | Performance, cross-compilation, faible empreinte |
| API Backend | Go + Fiber | Performance, cohérence avec agents |
| Frontend | Vue 3 + Vite | Légèreté, réactivité |
| Base Metrics | TimescaleDB (OVH Managed) | Time-series optimisé, rétention automatique |
| Base Config | PostgreSQL (OVH Managed) | Relationnel, ACID |
| Base Logs | Loki | Scalable, compatible Grafana |
| Cache/Queue | Redis (OVH Managed) | Pub/Sub, cache, rate limiting |
| Message Broker | NATS | Léger, performant, cloud-native |
| Tunnel | WireGuard | Sécurité, performance, simplicité |
| Secrets | OVH Secret Manager | Intégration native |
| Container | Docker / K8s OVH | Orchestration managée |

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

| Type | Granularité | Rétention |
|------|-------------|-----------|
| Métriques Raw | 1 minute | 30 jours |
| Métriques Agrégées 5min | 5 minutes | 90 jours |
| Métriques Agrégées 1h | 1 heure | 365 jours |
| Logs | Brut | 30 jours |
| Logs Compressés | Compressé | 365 jours |
| Alertes | Brut | 365 jours |

## Sécurité

### Authentification
- **Users Standard**: Email/Password + TOTP MFA
- **Super Admin**: JumpCloud SSO (module existant)
- **Agents/Probes**: Certificats mTLS + Token rotatif

### Communication
- Tout le trafic passe par WireGuard
- gRPC avec TLS mutuel
- Tokens JWT pour l'API web

### Secrets
- OVH Secret Manager pour les credentials
- Rotation automatique des clés WireGuard
- Chiffrement at-rest pour les données sensibles

## Scalabilité

### Horizontal
- Collectors: Load balancer + auto-scaling
- Workers: Queue-based scaling via NATS
- Databases: Réplication + sharding (TimescaleDB)

### Vertical
- Agents optimisés pour faible consommation (<50MB RAM, <1% CPU)
- Compression des données en transit

## Structure des Repositories

```
secumon/
├── secumon-probe/          # Sonde scanner externe
├── secumon-agent/          # Agent serveur léger
├── secumon-collector/      # Nœud principal (services)
├── secumon-web/            # Interface web
├── secumon-common/         # Librairies partagées (proto, utils)
├── secumon-deploy/         # Scripts déploiement K8s/Docker
└── secumon-docs/           # Documentation
```

## Phases de Développement

### Phase 1: Foundation (4-6 semaines)
- [ ] secumon-common (proto, auth, crypto)
- [ ] secumon-collector (core services)
- [ ] WireGuard auto-provisioning

### Phase 2: Agents (4-6 semaines)
- [ ] secumon-agent (monitoring système)
- [ ] secumon-probe (scans externes)
- [ ] Tests unitaires et intégration

### Phase 3: Web Interface (4-6 semaines)
- [ ] API REST/GraphQL
- [ ] Frontend Vue 3
- [ ] Auth MFA + JumpCloud

### Phase 4: Advanced Features (4-6 semaines)
- [ ] Alerting avancé
- [ ] Rapports automatisés
- [ ] Multi-tenancy complet

### Phase 5: Production (2-4 semaines)
- [ ] Déploiement K8s OVH
- [ ] Monitoring de la plateforme elle-même
- [ ] Documentation utilisateur
