# SecuMon-Collector - Nœud Principal

## Objectif

Ensemble de services orchestrés recevant les données des agents et probes, gérant le stockage, l'alerting, et exposant une API pour l'interface web. Déployable sur l'infrastructure centrale ou directement chez un client.

## Architecture des Services

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           SECUMON-COLLECTOR                                      │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌────────────────┐    ┌────────────────┐    ┌────────────────┐                 │
│  │  WireGuard     │    │    NATS        │    │    Redis       │                 │
│  │  Manager       │◄───┤   Message      │◄───┤   Cache        │                 │
│  │  (Go Service)  │    │   Broker       │    │   (OVH Managed)│                 │
│  └───────┬────────┘    └───────┬────────┘    └───────┬────────┘                 │
│          │                     │                     │                          │
│  ┌───────▼────────────────────▼─────────────────────▼────────┐                 │
│  │                      gRPC Gateway                          │                 │
│  │                    (Load Balanced)                         │                 │
│  └───────┬───────────────────────────────────────────────────┘                 │
│          │                                                                      │
│  ┌───────▼────────┐    ┌────────────────┐    ┌────────────────┐                │
│  │  Ingestion     │    │   Alert        │    │   API          │                │
│  │  Workers       │    │   Engine       │    │   Server       │                │
│  │  (Scalable)    │    │   (Go Service) │    │   (Go + Fiber) │                │
│  └───────┬────────┘    └───────┬────────┘    └───────┬────────┘                │
│          │                     │                     │                          │
│  ┌───────▼─────────────────────▼─────────────────────▼───────┐                 │
│  │                       DATA LAYER                           │                 │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │                 │
│  │  │ TimescaleDB  │  │  PostgreSQL  │  │    Loki      │     │                 │
│  │  │  (Metrics)   │  │   (Config)   │  │   (Logs)     │     │                 │
│  │  │ OVH Managed  │  │ OVH Managed  │  │  Container   │     │                 │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │                 │
│  └───────────────────────────────────────────────────────────┘                 │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Services

### 1. WireGuard Manager
Gestion dynamique des tunnels WireGuard pour agents/probes.

### 2. gRPC Gateway
Point d'entrée pour toutes les communications agents/probes.

### 3. Ingestion Workers
Workers scalables pour le traitement des métriques et logs.

### 4. Alert Engine
Moteur d'alerting avec règles configurables.

### 5. API Server
API REST/GraphQL pour l'interface web.

## Structure du Projet

```
secumon-collector/
├── cmd/
│   ├── gateway/              # gRPC Gateway
│   │   └── main.go
│   ├── ingestion/            # Ingestion Workers
│   │   └── main.go
│   ├── alerter/              # Alert Engine
│   │   └── main.go
│   ├── api/                  # API Server
│   │   └── main.go
│   └── wgmanager/            # WireGuard Manager
│       └── main.go
├── internal/
│   ├── gateway/
│   │   ├── server.go
│   │   ├── auth.go
│   │   └── handlers/
│   │       ├── agent.go
│   │       └── probe.go
│   ├── ingestion/
│   │   ├── worker.go
│   │   ├── metrics.go
│   │   ├── logs.go
│   │   └── decompress.go
│   ├── alerter/
│   │   ├── engine.go
│   │   ├── rules.go
│   │   ├── evaluator.go
│   │   └── notifier/
│   │       ├── email.go
│   │       ├── slack.go
│   │       ├── webhook.go
│   │       └── sms.go
│   ├── api/
│   │   ├── server.go
│   │   ├── middleware/
│   │   │   ├── auth.go
│   │   │   ├── ratelimit.go
│   │   │   └── tenant.go
│   │   ├── handlers/
│   │   │   ├── auth.go
│   │   │   ├── agents.go
│   │   │   ├── probes.go
│   │   │   ├── metrics.go
│   │   │   ├── logs.go
│   │   │   ├── alerts.go
│   │   │   ├── targets.go
│   │   │   └── reports.go
│   │   └── graphql/
│   │       ├── schema.go
│   │       └── resolvers.go
│   ├── wireguard/
│   │   ├── manager.go
│   │   ├── provisioner.go
│   │   └── config.go
│   ├── storage/
│   │   ├── timescale/
│   │   │   ├── client.go
│   │   │   ├── metrics.go
│   │   │   └── retention.go
│   │   ├── postgres/
│   │   │   ├── client.go
│   │   │   ├── models.go
│   │   │   └── migrations/
│   │   ├── loki/
│   │   │   ├── client.go
│   │   │   └── queries.go
│   │   └── redis/
│   │       ├── client.go
│   │       └── cache.go
│   ├── auth/
│   │   ├── jwt.go
│   │   ├── mfa.go
│   │   ├── jumpcloud.go      # SSO JumpCloud
│   │   └── agent_auth.go
│   └── secrets/
│       └── ovh.go            # OVH Secret Manager
├── pkg/
│   ├── models/
│   │   ├── agent.go
│   │   ├── probe.go
│   │   ├── target.go
│   │   ├── metric.go
│   │   ├── alert.go
│   │   └── user.go
│   └── dto/
│       └── api.go
├── proto/
│   ├── agent.proto
│   ├── probe.proto
│   └── common.proto
├── migrations/
│   ├── postgres/
│   │   ├── 001_initial.up.sql
│   │   ├── 001_initial.down.sql
│   │   └── ...
│   └── timescale/
│       ├── 001_hypertables.sql
│       └── 002_retention.sql
├── configs/
│   ├── gateway.yaml
│   ├── ingestion.yaml
│   ├── alerter.yaml
│   ├── api.yaml
│   └── wgmanager.yaml
├── deployments/
│   ├── docker-compose.yaml
│   └── kubernetes/
│       ├── namespace.yaml
│       ├── gateway/
│       ├── ingestion/
│       ├── alerter/
│       ├── api/
│       └── wgmanager/
├── Dockerfile.gateway
├── Dockerfile.ingestion
├── Dockerfile.alerter
├── Dockerfile.api
├── Dockerfile.wgmanager
├── go.mod
└── README.md
```

## Configuration

### Gateway Configuration
```yaml
# configs/gateway.yaml
server:
  grpc_port: 9443
  health_port: 8080
  max_connections: 10000
  
tls:
  enabled: true
  cert_file: "/etc/secumon/certs/server.crt"
  key_file: "/etc/secumon/certs/server.key"
  ca_file: "/etc/secumon/certs/ca.crt"
  
auth:
  token_validation: true
  jwt_secret_ref: "ovh://secrets/jwt-secret"
  
nats:
  url: "nats://nats:4222"
  cluster_id: "secumon"
  
redis:
  url: "redis://redis:6379"
  password_ref: "ovh://secrets/redis-password"
  
rate_limiting:
  enabled: true
  requests_per_second: 1000
  burst: 5000
  
logging:
  level: "info"
  format: "json"
```

### Ingestion Worker Configuration
```yaml
# configs/ingestion.yaml
worker:
  concurrency: 10
  batch_size: 1000
  flush_interval: 5s
  
nats:
  url: "nats://nats:4222"
  subjects:
    metrics: "secumon.metrics.>"
    logs: "secumon.logs.>"
    inventory: "secumon.inventory.>"
  queue_group: "ingestion-workers"
  
timescale:
  host: "timescale.ovh.net"
  port: 5432
  database: "secumon_metrics"
  user: "secumon"
  password_ref: "ovh://secrets/timescale-password"
  max_connections: 50
  
loki:
  url: "http://loki:3100"
  batch_size: 100000
  batch_wait: 1s
  
decompression:
  enabled: true
  algorithms:
    - "lz4"
    - "zstd"
```

### Alert Engine Configuration
```yaml
# configs/alerter.yaml
engine:
  evaluation_interval: 30s
  notification_cooldown: 5m
  
nats:
  url: "nats://nats:4222"
  subject: "secumon.alerts"
  
postgres:
  host: "postgres.ovh.net"
  database: "secumon"
  
timescale:
  host: "timescale.ovh.net"
  database: "secumon_metrics"
  
notifications:
  email:
    enabled: true
    smtp_host: "smtp.ovh.net"
    smtp_port: 587
    from: "alerts@secumon.io"
    credentials_ref: "ovh://secrets/smtp-credentials"
    
  slack:
    enabled: true
    webhook_url_ref: "ovh://secrets/slack-webhook"
    
  webhook:
    enabled: true
    default_timeout: 10s
    
  sms:
    enabled: false
    provider: "twilio"
    credentials_ref: "ovh://secrets/twilio-credentials"
```

### API Server Configuration
```yaml
# configs/api.yaml
server:
  http_port: 8080
  https_port: 8443
  
tls:
  enabled: true
  cert_file: "/etc/secumon/certs/api.crt"
  key_file: "/etc/secumon/certs/api.key"
  
auth:
  jwt_secret_ref: "ovh://secrets/jwt-secret"
  jwt_expiry: 24h
  refresh_expiry: 168h
  
  mfa:
    enabled: true
    issuer: "SecuMon"
    
  jumpcloud:
    enabled: true
    client_id_ref: "ovh://secrets/jumpcloud-client-id"
    client_secret_ref: "ovh://secrets/jumpcloud-client-secret"
    org_id: "secuaas"
    
cors:
  allowed_origins:
    - "https://app.secumon.io"
    - "https://*.secumon.io"
  allowed_methods:
    - "GET"
    - "POST"
    - "PUT"
    - "DELETE"
    - "PATCH"
  allowed_headers:
    - "Authorization"
    - "Content-Type"
    - "X-Tenant-ID"
    
rate_limiting:
  enabled: true
  requests_per_minute: 600
  
databases:
  postgres:
    host: "postgres.ovh.net"
    database: "secumon"
  timescale:
    host: "timescale.ovh.net"
    database: "secumon_metrics"
  redis:
    url: "redis://redis:6379"
```

## Schémas de Base de Données

### PostgreSQL - Configuration et Métadonnées
```sql
-- migrations/postgres/001_initial.up.sql

-- Tenants (Multi-tenancy)
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    totp_secret VARCHAR(255),
    mfa_enabled BOOLEAN DEFAULT false,
    role VARCHAR(50) NOT NULL DEFAULT 'viewer',
    sso_provider VARCHAR(50),
    sso_id VARCHAR(255),
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(tenant_id, email)
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_sso ON users(sso_provider, sso_id);

-- Agents
CREATE TABLE agents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    hostname VARCHAR(255),
    ip_addresses JSONB DEFAULT '[]',
    os VARCHAR(100),
    os_version VARCHAR(100),
    arch VARCHAR(50),
    version VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending',
    last_seen TIMESTAMP WITH TIME ZONE,
    config JSONB DEFAULT '{}',
    tags VARCHAR(100)[] DEFAULT '{}',
    wireguard_public_key VARCHAR(255),
    wireguard_ip VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_agents_tenant ON agents(tenant_id);
CREATE INDEX idx_agents_status ON agents(status);
CREATE INDEX idx_agents_tags ON agents USING GIN(tags);

-- Probes
CREATE TABLE probes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    type VARCHAR(50) DEFAULT 'external',
    status VARCHAR(50) DEFAULT 'pending',
    last_seen TIMESTAMP WITH TIME ZONE,
    config JSONB DEFAULT '{}',
    tags VARCHAR(100)[] DEFAULT '{}',
    wireguard_public_key VARCHAR(255),
    wireguard_ip VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_probes_tenant ON probes(tenant_id);

-- Targets (Cibles de scan)
CREATE TABLE targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    enabled BOOLEAN DEFAULT true,
    probe_ids UUID[] DEFAULT '{}',
    tests JSONB DEFAULT '[]',
    tags VARCHAR(100)[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_targets_tenant ON targets(tenant_id);
CREATE INDEX idx_targets_enabled ON targets(enabled);

-- SNMP Credentials
CREATE TABLE snmp_credentials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    version VARCHAR(10) NOT NULL,
    community_encrypted BYTEA,
    v3_username VARCHAR(255),
    v3_auth_proto VARCHAR(50),
    v3_auth_pass_encrypted BYTEA,
    v3_priv_proto VARCHAR(50),
    v3_priv_pass_encrypted BYTEA,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alert Rules
CREATE TABLE alert_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    enabled BOOLEAN DEFAULT true,
    severity VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL,
    conditions JSONB NOT NULL,
    for_duration INTERVAL,
    labels JSONB DEFAULT '{}',
    annotations JSONB DEFAULT '{}',
    notification_channels UUID[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_alert_rules_tenant ON alert_rules(tenant_id);
CREATE INDEX idx_alert_rules_enabled ON alert_rules(enabled);

-- Notification Channels
CREATE TABLE notification_channels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    config_encrypted BYTEA NOT NULL,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alert History
CREATE TABLE alert_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    rule_id UUID REFERENCES alert_rules(id) ON DELETE SET NULL,
    agent_id UUID,
    probe_id UUID,
    target_id UUID,
    severity VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    message TEXT,
    value DOUBLE PRECISION,
    threshold DOUBLE PRECISION,
    fired_at TIMESTAMP WITH TIME ZONE NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by UUID REFERENCES users(id),
    labels JSONB DEFAULT '{}',
    annotations JSONB DEFAULT '{}'
);

CREATE INDEX idx_alert_history_tenant ON alert_history(tenant_id);
CREATE INDEX idx_alert_history_fired ON alert_history(fired_at DESC);
CREATE INDEX idx_alert_history_status ON alert_history(status);

-- Audit Log
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    old_value JSONB,
    new_value JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_tenant ON audit_logs(tenant_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
```

### TimescaleDB - Métriques
```sql
-- migrations/timescale/001_hypertables.sql

-- Extension TimescaleDB
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Métriques système (agents)
CREATE TABLE system_metrics (
    time TIMESTAMPTZ NOT NULL,
    tenant_id UUID NOT NULL,
    agent_id UUID NOT NULL,
    
    -- CPU
    cpu_usage DOUBLE PRECISION,
    cpu_user DOUBLE PRECISION,
    cpu_system DOUBLE PRECISION,
    cpu_iowait DOUBLE PRECISION,
    load_avg_1 DOUBLE PRECISION,
    load_avg_5 DOUBLE PRECISION,
    load_avg_15 DOUBLE PRECISION,
    
    -- Memory
    mem_total BIGINT,
    mem_used BIGINT,
    mem_available BIGINT,
    mem_cached BIGINT,
    swap_used BIGINT,
    
    -- Extra fields (JSONB pour flexibilité)
    extra JSONB DEFAULT '{}'
);

SELECT create_hypertable('system_metrics', 'time',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

CREATE INDEX idx_system_metrics_agent ON system_metrics(agent_id, time DESC);
CREATE INDEX idx_system_metrics_tenant ON system_metrics(tenant_id, time DESC);

-- Métriques disques
CREATE TABLE disk_metrics (
    time TIMESTAMPTZ NOT NULL,
    tenant_id UUID NOT NULL,
    agent_id UUID NOT NULL,
    device VARCHAR(100) NOT NULL,
    mountpoint VARCHAR(255),
    
    total_bytes BIGINT,
    used_bytes BIGINT,
    usage_percent DOUBLE PRECISION,
    read_bytes BIGINT,
    write_bytes BIGINT,
    read_ops BIGINT,
    write_ops BIGINT,
    read_latency DOUBLE PRECISION,
    write_latency DOUBLE PRECISION
);

SELECT create_hypertable('disk_metrics', 'time',
    chunk_time_interval => INTERVAL '1 day'
);

CREATE INDEX idx_disk_metrics_agent ON disk_metrics(agent_id, time DESC);

-- Métriques réseau
CREATE TABLE network_metrics (
    time TIMESTAMPTZ NOT NULL,
    tenant_id UUID NOT NULL,
    agent_id UUID NOT NULL,
    interface VARCHAR(100) NOT NULL,
    
    rx_bytes BIGINT,
    tx_bytes BIGINT,
    rx_packets BIGINT,
    tx_packets BIGINT,
    rx_errors BIGINT,
    tx_errors BIGINT
);

SELECT create_hypertable('network_metrics', 'time',
    chunk_time_interval => INTERVAL '1 day'
);

-- Résultats de scans (probes)
CREATE TABLE scan_results (
    time TIMESTAMPTZ NOT NULL,
    tenant_id UUID NOT NULL,
    probe_id UUID NOT NULL,
    target_id UUID NOT NULL,
    test_type VARCHAR(50) NOT NULL,
    
    success BOOLEAN NOT NULL,
    error_message TEXT,
    
    -- Résultats génériques
    latency_ms DOUBLE PRECISION,
    packet_loss DOUBLE PRECISION,
    
    -- Données détaillées
    result_data JSONB DEFAULT '{}'
);

SELECT create_hypertable('scan_results', 'time',
    chunk_time_interval => INTERVAL '1 day'
);

CREATE INDEX idx_scan_results_target ON scan_results(target_id, time DESC);
CREATE INDEX idx_scan_results_type ON scan_results(test_type, time DESC);

-- Métriques SNMP
CREATE TABLE snmp_metrics (
    time TIMESTAMPTZ NOT NULL,
    tenant_id UUID NOT NULL,
    probe_id UUID NOT NULL,
    target_id UUID NOT NULL,
    
    oid VARCHAR(255) NOT NULL,
    oid_name VARCHAR(255),
    value_type VARCHAR(50),
    value_numeric DOUBLE PRECISION,
    value_string TEXT
);

SELECT create_hypertable('snmp_metrics', 'time',
    chunk_time_interval => INTERVAL '1 day'
);

CREATE INDEX idx_snmp_metrics_target ON snmp_metrics(target_id, time DESC);
CREATE INDEX idx_snmp_metrics_oid ON snmp_metrics(oid, time DESC);

-- Rétention automatique
-- migrations/timescale/002_retention.sql

-- Données brutes: 30 jours
SELECT add_retention_policy('system_metrics', INTERVAL '30 days');
SELECT add_retention_policy('disk_metrics', INTERVAL '30 days');
SELECT add_retention_policy('network_metrics', INTERVAL '30 days');
SELECT add_retention_policy('scan_results', INTERVAL '30 days');
SELECT add_retention_policy('snmp_metrics', INTERVAL '30 days');

-- Agrégations continues pour historique long terme

-- Agrégation 5 minutes (90 jours)
CREATE MATERIALIZED VIEW system_metrics_5m
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('5 minutes', time) AS bucket,
    tenant_id,
    agent_id,
    AVG(cpu_usage) AS cpu_usage_avg,
    MAX(cpu_usage) AS cpu_usage_max,
    AVG(mem_used::float / NULLIF(mem_total, 0) * 100) AS mem_usage_avg,
    AVG(load_avg_1) AS load_avg_1
FROM system_metrics
GROUP BY bucket, tenant_id, agent_id
WITH NO DATA;

SELECT add_continuous_aggregate_policy('system_metrics_5m',
    start_offset => INTERVAL '1 hour',
    end_offset => INTERVAL '5 minutes',
    schedule_interval => INTERVAL '5 minutes'
);

SELECT add_retention_policy('system_metrics_5m', INTERVAL '90 days');

-- Agrégation 1 heure (365 jours)
CREATE MATERIALIZED VIEW system_metrics_1h
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    tenant_id,
    agent_id,
    AVG(cpu_usage) AS cpu_usage_avg,
    MAX(cpu_usage) AS cpu_usage_max,
    MIN(cpu_usage) AS cpu_usage_min,
    AVG(mem_used::float / NULLIF(mem_total, 0) * 100) AS mem_usage_avg,
    AVG(load_avg_1) AS load_avg_1
FROM system_metrics
GROUP BY bucket, tenant_id, agent_id
WITH NO DATA;

SELECT add_continuous_aggregate_policy('system_metrics_1h',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);

SELECT add_retention_policy('system_metrics_1h', INTERVAL '365 days');
```

## Implémentation des Services

### gRPC Gateway
```go
// internal/gateway/server.go
package gateway

import (
    "context"
    "crypto/tls"
    "net"
    
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials"
    
    pb "github.com/secuaas/secumon-collector/proto"
)

type Server struct {
    pb.UnimplementedAgentServiceServer
    pb.UnimplementedProbeServiceServer
    
    config      *Config
    nats        *nats.Conn
    redis       *redis.Client
    auth        *AuthService
}

func NewServer(cfg *Config) (*Server, error) {
    s := &Server{config: cfg}
    
    // Connexion NATS
    nc, err := nats.Connect(cfg.NATS.URL)
    if err != nil {
        return nil, err
    }
    s.nats = nc
    
    // Connexion Redis
    s.redis = redis.NewClient(&redis.Options{
        Addr:     cfg.Redis.URL,
        Password: cfg.Redis.Password,
    })
    
    return s, nil
}

func (s *Server) Start() error {
    // Configuration TLS
    cert, _ := tls.LoadX509KeyPair(s.config.TLS.CertFile, s.config.TLS.KeyFile)
    tlsConfig := &tls.Config{
        Certificates: []tls.Certificate{cert},
        ClientAuth:   tls.RequireAndVerifyClientCert,
    }
    
    // Server gRPC
    grpcServer := grpc.NewServer(
        grpc.Creds(credentials.NewTLS(tlsConfig)),
        grpc.UnaryInterceptor(s.authInterceptor),
        grpc.StreamInterceptor(s.streamAuthInterceptor),
    )
    
    pb.RegisterAgentServiceServer(grpcServer, s)
    pb.RegisterProbeServiceServer(grpcServer, s)
    
    lis, _ := net.Listen("tcp", s.config.Server.GRPCPort)
    return grpcServer.Serve(lis)
}

// Handler pour les métriques d'agents
func (s *Server) SendMetrics(stream pb.AgentService_SendMetricsServer) error {
    for {
        batch, err := stream.Recv()
        if err != nil {
            return err
        }
        
        // Validation du token
        agentID, err := s.auth.ValidateAgentToken(stream.Context())
        if err != nil {
            return err
        }
        
        // Publier vers NATS pour traitement asynchrone
        subject := fmt.Sprintf("secumon.metrics.%s", agentID)
        s.nats.Publish(subject, batch.CompressedData)
        
        // Update last_seen dans Redis
        s.redis.Set(stream.Context(), 
            fmt.Sprintf("agent:lastseen:%s", agentID),
            time.Now().Unix(),
            5*time.Minute,
        )
    }
    
    return stream.SendAndClose(&pb.SendResponse{Success: true})
}
```

### Ingestion Worker
```go
// internal/ingestion/worker.go
package ingestion

import (
    "context"
    
    "github.com/nats-io/nats.go"
    "github.com/pierrec/lz4/v4"
)

type Worker struct {
    config    *Config
    nats      *nats.Conn
    timescale *TimescaleClient
    loki      *LokiClient
}

func (w *Worker) Start(ctx context.Context) error {
    // S'abonner aux métriques
    w.nats.QueueSubscribe("secumon.metrics.>", "ingestion-workers", func(msg *nats.Msg) {
        go w.processMetrics(msg)
    })
    
    // S'abonner aux logs
    w.nats.QueueSubscribe("secumon.logs.>", "ingestion-workers", func(msg *nats.Msg) {
        go w.processLogs(msg)
    })
    
    <-ctx.Done()
    return nil
}

func (w *Worker) processMetrics(msg *nats.Msg) {
    // Extraire l'agent ID du sujet
    // secumon.metrics.<agent_id>
    agentID := extractAgentID(msg.Subject)
    
    // Décompresser
    decompressed := make([]byte, 10*len(msg.Data))
    n, _ := lz4.UncompressBlock(msg.Data, decompressed)
    
    // Désérialiser
    var batch SystemMetricsList
    proto.Unmarshal(decompressed[:n], &batch)
    
    // Insérer dans TimescaleDB
    w.timescale.InsertMetrics(agentID, batch.Metrics)
}

func (w *Worker) processLogs(msg *nats.Msg) {
    agentID := extractAgentID(msg.Subject)
    
    var batch LogBatch
    // Décompression et désérialisation...
    
    // Envoyer vers Loki
    w.loki.Push(agentID, batch.Entries)
}
```

### Alert Engine
```go
// internal/alerter/engine.go
package alerter

import (
    "context"
    "time"
)

type AlertEngine struct {
    config     *Config
    postgres   *PostgresClient
    timescale  *TimescaleClient
    notifier   *Notifier
    rules      []*AlertRule
}

type AlertRule struct {
    ID          string
    TenantID    string
    Name        string
    Type        string            // "threshold", "change", "anomaly"
    Conditions  []Condition
    ForDuration time.Duration
    Severity    string
    Channels    []string
}

type Condition struct {
    Metric    string
    Operator  string            // "gt", "lt", "eq", "ne", "change"
    Value     float64
    Labels    map[string]string
}

func (e *AlertEngine) Start(ctx context.Context) {
    ticker := time.NewTicker(e.config.EvaluationInterval)
    defer ticker.Stop()
    
    for {
        select {
        case <-ticker.C:
            e.evaluate()
        case <-ctx.Done():
            return
        }
    }
}

func (e *AlertEngine) evaluate() {
    for _, rule := range e.rules {
        firing, value := e.evaluateRule(rule)
        
        if firing {
            e.handleFiring(rule, value)
        } else {
            e.handleResolved(rule)
        }
    }
}

func (e *AlertEngine) evaluateRule(rule *AlertRule) (bool, float64) {
    for _, cond := range rule.Conditions {
        value, err := e.queryMetric(rule.TenantID, cond)
        if err != nil {
            continue
        }
        
        if !e.checkCondition(cond, value) {
            return false, 0
        }
    }
    return true, 0
}

func (e *AlertEngine) handleFiring(rule *AlertRule, value float64) {
    // Vérifier le cooldown
    if e.inCooldown(rule.ID) {
        return
    }
    
    // Créer l'alerte
    alert := &Alert{
        RuleID:   rule.ID,
        TenantID: rule.TenantID,
        Severity: rule.Severity,
        Message:  rule.Name,
        Value:    value,
        FiredAt:  time.Now(),
    }
    
    // Sauvegarder
    e.postgres.SaveAlert(alert)
    
    // Notifier
    for _, channelID := range rule.Channels {
        e.notifier.Send(channelID, alert)
    }
}
```

### API Server (Fiber)
```go
// internal/api/server.go
package api

import (
    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/cors"
    "github.com/gofiber/fiber/v2/middleware/limiter"
)

type Server struct {
    app       *fiber.App
    config    *Config
    postgres  *PostgresClient
    timescale *TimescaleClient
    redis     *RedisClient
    auth      *AuthService
}

func NewServer(cfg *Config) *Server {
    app := fiber.New(fiber.Config{
        AppName: "SecuMon API",
    })
    
    s := &Server{
        app:    app,
        config: cfg,
    }
    
    s.setupMiddleware()
    s.setupRoutes()
    
    return s
}

func (s *Server) setupMiddleware() {
    // CORS
    s.app.Use(cors.New(cors.Config{
        AllowOrigins:     s.config.CORS.AllowedOrigins,
        AllowMethods:     s.config.CORS.AllowedMethods,
        AllowHeaders:     s.config.CORS.AllowedHeaders,
        AllowCredentials: true,
    }))
    
    // Rate limiting
    s.app.Use(limiter.New(limiter.Config{
        Max:        s.config.RateLimiting.RequestsPerMinute,
        Expiration: time.Minute,
        KeyGenerator: func(c *fiber.Ctx) string {
            return c.Get("X-Tenant-ID") + ":" + c.IP()
        },
    }))
}

func (s *Server) setupRoutes() {
    // Public routes
    s.app.Post("/api/v1/auth/login", s.handleLogin)
    s.app.Post("/api/v1/auth/refresh", s.handleRefresh)
    s.app.Get("/api/v1/auth/sso/jumpcloud", s.handleJumpCloudSSO)
    s.app.Get("/api/v1/auth/sso/jumpcloud/callback", s.handleJumpCloudCallback)
    
    // Protected routes
    api := s.app.Group("/api/v1", s.authMiddleware)
    
    // Agents
    api.Get("/agents", s.handleListAgents)
    api.Get("/agents/:id", s.handleGetAgent)
    api.Post("/agents", s.handleCreateAgent)
    api.Put("/agents/:id", s.handleUpdateAgent)
    api.Delete("/agents/:id", s.handleDeleteAgent)
    api.Get("/agents/:id/metrics", s.handleGetAgentMetrics)
    api.Get("/agents/:id/logs", s.handleGetAgentLogs)
    
    // Probes
    api.Get("/probes", s.handleListProbes)
    api.Get("/probes/:id", s.handleGetProbe)
    api.Post("/probes", s.handleCreateProbe)
    
    // Targets
    api.Get("/targets", s.handleListTargets)
    api.Post("/targets", s.handleCreateTarget)
    api.Get("/targets/:id/results", s.handleGetTargetResults)
    
    // Alerts
    api.Get("/alerts", s.handleListAlerts)
    api.Get("/alerts/rules", s.handleListAlertRules)
    api.Post("/alerts/rules", s.handleCreateAlertRule)
    api.Post("/alerts/:id/acknowledge", s.handleAcknowledgeAlert)
    
    // Metrics API
    api.Post("/metrics/query", s.handleMetricsQuery)
    
    // Admin routes (super admin only)
    admin := s.app.Group("/api/v1/admin", s.authMiddleware, s.superAdminMiddleware)
    admin.Get("/tenants", s.handleListTenants)
    admin.Post("/tenants", s.handleCreateTenant)
}

// Handler exemple: Métriques d'un agent
func (s *Server) handleGetAgentMetrics(c *fiber.Ctx) error {
    tenantID := c.Locals("tenant_id").(string)
    agentID := c.Params("id")
    
    // Paramètres de requête
    from := c.Query("from", "-1h")
    to := c.Query("to", "now")
    resolution := c.Query("resolution", "auto")
    
    metrics, err := s.timescale.QueryAgentMetrics(tenantID, agentID, from, to, resolution)
    if err != nil {
        return c.Status(500).JSON(fiber.Map{"error": err.Error()})
    }
    
    return c.JSON(metrics)
}
```

## Déploiement Kubernetes

### Namespace et ConfigMap
```yaml
# deployments/kubernetes/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secumon
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: secumon-config
  namespace: secumon
data:
  gateway.yaml: |
    server:
      grpc_port: 9443
    # ...
  ingestion.yaml: |
    worker:
      concurrency: 10
    # ...
```

### Gateway Deployment
```yaml
# deployments/kubernetes/gateway/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secumon-gateway
  namespace: secumon
spec:
  replicas: 3
  selector:
    matchLabels:
      app: secumon-gateway
  template:
    metadata:
      labels:
        app: secumon-gateway
    spec:
      containers:
      - name: gateway
        image: registry.secumon.io/gateway:latest
        ports:
        - containerPort: 9443
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        volumeMounts:
        - name: config
          mountPath: /etc/secumon
        - name: certs
          mountPath: /etc/secumon/certs
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
      volumes:
      - name: config
        configMap:
          name: secumon-config
      - name: certs
        secret:
          secretName: secumon-tls
---
apiVersion: v1
kind: Service
metadata:
  name: secumon-gateway
  namespace: secumon
spec:
  type: LoadBalancer
  ports:
  - port: 9443
    targetPort: 9443
    name: grpc
  selector:
    app: secumon-gateway
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: secumon-gateway-hpa
  namespace: secumon
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: secumon-gateway
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Ingestion Worker Deployment
```yaml
# deployments/kubernetes/ingestion/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secumon-ingestion
  namespace: secumon
spec:
  replicas: 5
  selector:
    matchLabels:
      app: secumon-ingestion
  template:
    metadata:
      labels:
        app: secumon-ingestion
    spec:
      containers:
      - name: ingestion
        image: registry.secumon.io/ingestion:latest
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        env:
        - name: TIMESCALE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: secumon-db-secrets
              key: timescale-password
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: secumon-ingestion-hpa
  namespace: secumon
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: secumon-ingestion
  minReplicas: 5
  maxReplicas: 20
  metrics:
  - type: External
    external:
      metric:
        name: nats_pending_messages
        selector:
          matchLabels:
            subject: secumon.metrics
      target:
        type: AverageValue
        averageValue: "1000"
```

## Docker Compose (Dev/Small Deploy)

```yaml
# deployments/docker-compose.yaml
version: '3.8'

services:
  gateway:
    build:
      context: .
      dockerfile: Dockerfile.gateway
    ports:
      - "9443:9443"
    volumes:
      - ./configs:/etc/secumon
      - ./certs:/etc/secumon/certs
    depends_on:
      - nats
      - redis
    networks:
      - secumon
      
  ingestion:
    build:
      context: .
      dockerfile: Dockerfile.ingestion
    deploy:
      replicas: 3
    depends_on:
      - nats
      - timescale
      - loki
    networks:
      - secumon
      
  alerter:
    build:
      context: .
      dockerfile: Dockerfile.alerter
    depends_on:
      - nats
      - postgres
      - timescale
    networks:
      - secumon
      
  api:
    build:
      context: .
      dockerfile: Dockerfile.api
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - timescale
      - redis
    networks:
      - secumon
      
  wgmanager:
    build:
      context: .
      dockerfile: Dockerfile.wgmanager
    cap_add:
      - NET_ADMIN
    sysctls:
      - net.ipv4.ip_forward=1
    volumes:
      - /etc/wireguard:/etc/wireguard
    networks:
      - secumon
      
  nats:
    image: nats:2.10-alpine
    ports:
      - "4222:4222"
    networks:
      - secumon
      
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - secumon
      
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: secumon
      POSTGRES_USER: secumon
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./migrations/postgres:/docker-entrypoint-initdb.d
    secrets:
      - postgres_password
    networks:
      - secumon
      
  timescale:
    image: timescale/timescaledb:latest-pg16
    environment:
      POSTGRES_DB: secumon_metrics
      POSTGRES_USER: secumon
      POSTGRES_PASSWORD_FILE: /run/secrets/timescale_password
    volumes:
      - timescale_data:/var/lib/postgresql/data
      - ./migrations/timescale:/docker-entrypoint-initdb.d
    secrets:
      - timescale_password
    networks:
      - secumon
      
  loki:
    image: grafana/loki:2.9.0
    ports:
      - "3100:3100"
    volumes:
      - loki_data:/loki
    networks:
      - secumon

networks:
  secumon:
    driver: bridge

volumes:
  redis_data:
  postgres_data:
  timescale_data:
  loki_data:

secrets:
  postgres_password:
    external: true
  timescale_password:
    external: true
```
