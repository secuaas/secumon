# SecuMon - Production Deployment Guide

**Version:** 0.2.0+
**Date:** 2026-01-30/31
**Status:** Production-Ready

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Service Deployment](#service-deployment)
5. [Grafana Dashboards](#grafana-dashboards)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Troubleshooting](#troubleshooting)
8. [Security Hardening](#security-hardening)

## Prerequisites

### System Requirements

**Collector Server (Backend):**
- OS: Ubuntu 20.04+ / Debian 11+ / RHEL 8+
- CPU: 4+ cores
- RAM: 8GB+ (16GB recommended)
- Disk: 100GB+ SSD
- Network: Static IP, firewall configured

**Agent (per monitored server):**
- OS: Linux (any modern distribution)
- CPU: 1 core
- RAM: 256MB
- Disk: 100MB
- Network: Outbound access to collector

### Software Dependencies

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y postgresql-client git make curl

# RHEL/CentOS
sudo yum install -y postgresql git make curl
```

### Database: TimescaleDB

```bash
# Add TimescaleDB repository
sudo sh -c "echo 'deb https://packagecloud.io/timescale/timescaledb/ubuntu/ $(lsb_release -c -s) main' > /etc/apt/sources.list.d/timescaledb.list"
wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | sudo apt-key add -

# Install TimescaleDB
sudo apt update
sudo apt install -y timescaledb-2-postgresql-16

# Initialize
sudo timescaledb-tune --quiet --yes
sudo systemctl restart postgresql
```

### Docker & Docker Compose (Alternative)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Installation

### Option 1: From Source (Recommended)

```bash
# Clone repositories
cd /opt
sudo git clone https://github.com/secuaas/secumon.git
sudo git clone https://github.com/secuaas/secumon-common.git
sudo git clone https://github.com/secuaas/secumon-agent.git
sudo git clone https://github.com/secuaas/secumon-collector.git

# Build all services
cd /opt/secumon
sudo make -f Makefile.production build-all

# Install binaries
sudo make -f Makefile.production install

# Verify installation
secumon-agent --version
secumon-ingestion --help
secumon-api --help
secumon-alerting --help
```

### Option 2: Docker Compose

```bash
# Use development environment
cd /opt/secumon
docker compose -f docker-compose.dev.yml up -d

# Or build production images
make -f Makefile.production docker-build
```

## Configuration

### 1. Database Setup

```bash
# Create database and user
sudo -u postgres psql <<EOF
CREATE DATABASE metrics;
CREATE USER metrics_writer WITH PASSWORD 'CHANGE_ME_STRONG_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE metrics TO metrics_writer;
EOF

# Enable TimescaleDB extension
sudo -u postgres psql -d metrics <<EOF
CREATE EXTENSION IF NOT EXISTS timescaledb;
EOF

# Run migrations
cd /opt/secumon-collector
export PGPASSWORD='CHANGE_ME_STRONG_PASSWORD'
psql -h localhost -U metrics_writer -d metrics -f migrations/000001_init_schema.up.sql
psql -h localhost -U metrics_writer -d metrics -f migrations/000002_timescaledb_hypertables.up.sql
psql -h localhost -U metrics_writer -d metrics -f migrations/000003_continuous_aggregates.up.sql
psql -h localhost -U metrics_writer -d metrics -f migrations/000004_retention_compression.up.sql
psql -h localhost -U metrics_writer -d metrics -f migrations/000005_alerting_system.up.sql
```

### 2. Create System User

```bash
# Create secumon user
sudo useradd -r -s /bin/false -d /opt/secumon secumon

# Create directories
sudo mkdir -p /etc/secumon /var/log/secumon /opt/secumon
sudo chown -R secumon:secumon /etc/secumon /var/log/secumon /opt/secumon
```

### 3. Configure Services

**Ingestion Service** (`/etc/secumon/ingestion.env`):

```bash
# Copy template
sudo cp /opt/secumon/deploy/config/ingestion.env.example /etc/secumon/ingestion.env

# Edit configuration
sudo nano /etc/secumon/ingestion.env
```

```bash
# gRPC Configuration
GRPC_PORT=9090

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=metrics_writer
DB_PASSWORD=YOUR_STRONG_PASSWORD_HERE
DB_NAME=metrics
DB_SSLMODE=require

# Logging
LOG_LEVEL=info
```

**API Service** (`/etc/secumon/api.env`):

```bash
sudo cp /opt/secumon/deploy/config/api.env.example /etc/secumon/api.env
sudo nano /etc/secumon/api.env
```

```bash
# API Configuration
API_PORT=8080

# JWT Authentication
JWT_ENABLED=true
JWT_SECRET=$(openssl rand -base64 32)

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=metrics_writer
DB_PASSWORD=YOUR_STRONG_PASSWORD_HERE
DB_NAME=metrics
DB_SSLMODE=require

# Logging
LOG_LEVEL=info
```

**Alerting Service** (`/etc/secumon/alerting.env`):

```bash
sudo cp /opt/secumon/deploy/config/alerting.env.example /etc/secumon/alerting.env
sudo nano /etc/secumon/alerting.env
```

```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=metrics_writer
DB_PASSWORD=YOUR_STRONG_PASSWORD_HERE
DB_NAME=metrics
DB_SSLMODE=require

# Webhook Notifications (optional)
WEBHOOK_URL=https://your-webhook-endpoint.com/alerts

# Slack Notifications (optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Email Notifications
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=alerts@yourdomain.com
SMTP_PASS=your_app_specific_password
EMAIL_FROM=alerts@yourdomain.com
EMAIL_FROM_NAME=SecuMon Alerts
EMAIL_TO=admin@yourdomain.com,ops@yourdomain.com

# Logging
LOG_LEVEL=info
```

**Agent Configuration** (`/etc/secumon/agent.yaml`):

```bash
sudo cp /opt/secumon-agent/config/agent.yaml.example /etc/secumon/agent.yaml
sudo nano /etc/secumon/agent.yaml
```

```yaml
agent:
  name: "production-server-01"
  labels:
    environment: "production"
    datacenter: "us-east-1"
    role: "webserver"

collector:
  endpoint: "collector.yourdomain.com:9090"
  tls:
    enabled: true
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

### 4. Secure Configuration Files

```bash
# Set proper permissions
sudo chmod 600 /etc/secumon/*.env
sudo chmod 644 /etc/secumon/agent.yaml
sudo chown -R secumon:secumon /etc/secumon
```

## Service Deployment

### 1. Deploy Systemd Services

```bash
# Install systemd service files
cd /opt/secumon
sudo make -f Makefile.production deploy-systemd

# Reload systemd
sudo systemctl daemon-reload
```

### 2. Start Services

```bash
# Start ingestion service (must start first)
sudo systemctl enable secumon-ingestion
sudo systemctl start secumon-ingestion
sudo systemctl status secumon-ingestion

# Start API service
sudo systemctl enable secumon-api
sudo systemctl start secumon-api
sudo systemctl status secumon-api

# Start alerting service
sudo systemctl enable secumon-alerting
sudo systemctl start secumon-alerting
sudo systemctl status secumon-alerting

# On agent servers
sudo systemctl enable secumon-agent
sudo systemctl start secumon-agent
sudo systemctl status secumon-agent
```

### 3. Verify Services

```bash
# Check logs
sudo journalctl -u secumon-ingestion -f
sudo journalctl -u secumon-api -f
sudo journalctl -u secumon-alerting -f

# Test API
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/agents

# Check processes
ps aux | grep secumon
```

### 4. Firewall Configuration

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 9090/tcp  # gRPC ingestion
sudo ufw allow 8080/tcp  # API REST
sudo ufw reload

# RHEL/CentOS (firewalld)
sudo firewall-cmd --permanent --add-port=9090/tcp
sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --reload
```

## Grafana Dashboards

### 1. Install Grafana

```bash
# Add Grafana repository
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

# Install
sudo apt-get update
sudo apt-get install -y grafana

# Start Grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
```

### 2. Configure Datasource

**Option 1: Via UI**
1. Open Grafana: http://your-server:3000 (admin/admin)
2. Go to Configuration → Data Sources → Add data source
3. Select PostgreSQL
4. Configure:
   - Host: `localhost:5432`
   - Database: `metrics`
   - User: `metrics_writer`
   - Password: `your_password`
   - SSL Mode: `require`
   - TimescaleDB: `enabled`

**Option 2: Provisioning**

```bash
# Copy datasource config
sudo mkdir -p /etc/grafana/provisioning/datasources
sudo cp /opt/secumon/grafana/datasources/timescaledb.yml /etc/grafana/provisioning/datasources/

# Edit with production credentials
sudo nano /etc/grafana/provisioning/datasources/timescaledb.yml

# Restart Grafana
sudo systemctl restart grafana-server
```

### 3. Import Dashboards

```bash
# Copy dashboards
sudo mkdir -p /etc/grafana/provisioning/dashboards
sudo cp /opt/secumon/grafana/dashboards/*.json /var/lib/grafana/dashboards/

# Create provisioning config
sudo tee /etc/grafana/provisioning/dashboards/secumon.yml <<EOF
apiVersion: 1

providers:
  - name: 'SecuMon'
    orgId: 1
    folder: 'SecuMon'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

# Restart Grafana
sudo systemctl restart grafana-server
```

**Available Dashboards:**
- System Overview - CPU, Memory, Load Average, Disk Usage
- Network & Processes - Network traffic, Top processes
- Alerts - Active alerts, Alert frequency, Rules configuration

### 4. Access Dashboards

1. Login to Grafana: http://your-server:3000
2. Navigate to Dashboards → SecuMon
3. Select:
   - SecuMon - System Overview
   - SecuMon - Network & Processes
   - SecuMon - Alerts & Rules

## Monitoring & Maintenance

### Health Checks

```bash
# Service health
curl http://localhost:8080/health

# Agent list
curl http://localhost:8080/api/v1/agents

# Alert stats
curl http://localhost:8080/api/v1/alerts/stats

# TimescaleDB jobs
psql -h localhost -U metrics_writer -d metrics -c "SELECT * FROM timescaledb_information.jobs;"
```

### Log Monitoring

```bash
# View logs
sudo journalctl -u secumon-ingestion -n 100
sudo journalctl -u secumon-api -n 100
sudo journalctl -u secumon-alerting -n 100

# Follow logs
sudo journalctl -u secumon-ingestion -f

# Filter by severity
sudo journalctl -u secumon-api -p err -n 50
```

### Database Maintenance

```bash
# Check database size
psql -h localhost -U metrics_writer -d metrics -c "
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
"

# Check compression stats
psql -h localhost -U metrics_writer -d metrics -c "
SELECT
    ht.hypertable_name,
    sum(cs.total_chunks) as total_chunks,
    sum(cs.number_compressed_chunks) as compressed_chunks,
    pg_size_pretty(sum(cs.uncompressed_total_bytes)) as uncompressed_size,
    pg_size_pretty(sum(cs.compressed_total_bytes)) as compressed_size,
    round(100.0 * sum(cs.compressed_total_bytes) / sum(cs.uncompressed_total_bytes), 2) as compression_ratio
FROM _timescaledb_catalog.hypertable ht
LEFT JOIN _timescaledb_catalog.compression_chunk_size cs ON ht.id = cs.hypertable_id
GROUP BY ht.hypertable_name;
"

# Vacuum
psql -h localhost -U metrics_writer -d metrics -c "VACUUM ANALYZE;"
```

### Backup & Restore

```bash
# Backup database
pg_dump -h localhost -U metrics_writer -d metrics -F c -b -v -f /backup/secumon-$(date +%Y%m%d).dump

# Restore database
pg_restore -h localhost -U metrics_writer -d metrics -v /backup/secumon-YYYYMMDD.dump

# Backup configuration
tar -czf /backup/secumon-config-$(date +%Y%m%d).tar.gz /etc/secumon/
```

## Troubleshooting

### Service Won't Start

```bash
# Check service status
sudo systemctl status secumon-ingestion

# Check detailed logs
sudo journalctl -xeu secumon-ingestion

# Verify configuration
sudo -u secumon secumon-ingestion --help

# Test database connection
psql -h localhost -U metrics_writer -d metrics -c "SELECT NOW();"
```

### Metrics Not Appearing

```bash
# Check agent connection
sudo journalctl -u secumon-agent | grep -i error

# Verify gRPC port
sudo netstat -tlnp | grep 9090

# Test connectivity from agent
telnet collector.yourdomain.com 9090

# Check ingestion logs
sudo journalctl -u secumon-ingestion | grep "Metrics stored"
```

### Alerts Not Firing

```bash
# Check alerting service
sudo systemctl status secumon-alerting

# Check alert rules
curl http://localhost:8080/api/v1/alerts/rules

# Check logs
sudo journalctl -u secumon-alerting | grep -i alert

# Verify email/slack configuration
sudo cat /etc/secumon/alerting.env
```

### High Database Usage

```bash
# Check hypertable chunks
psql -h localhost -U metrics_writer -d metrics -c "
SELECT hypertable_name, num_chunks
FROM timescaledb_information.hypertables;
"

# Manually compress old chunks
psql -h localhost -U metrics_writer -d metrics -c "
SELECT compress_chunk(i, if_not_compressed => true)
FROM show_chunks('metrics', older_than => INTERVAL '7 days') i;
"

# Adjust retention policies
psql -h localhost -U metrics_writer -d metrics -c "
SELECT remove_retention_policy('metrics');
SELECT add_retention_policy('metrics', INTERVAL '15 days');
"
```

## Security Hardening

### 1. Enable TLS for gRPC

```bash
# Generate CA certificate
openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt

# Generate server certificate
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr
openssl x509 -req -days 365 -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt

# Generate client certificates for each agent
openssl genrsa -out agent.key 4096
openssl req -new -key agent.key -out agent.csr
openssl x509 -req -days 365 -in agent.csr -CA ca.crt -CAkey ca.key -set_serial 02 -out agent.crt

# Deploy certificates
sudo cp ca.crt server.crt server.key /etc/secumon/certs/
sudo cp ca.crt agent.crt agent.key /etc/secumon/certs/
sudo chown -R secumon:secumon /etc/secumon/certs
sudo chmod 600 /etc/secumon/certs/*.key
```

### 2. PostgreSQL Security

```bash
# Edit pg_hba.conf
sudo nano /etc/postgresql/16/main/pg_hba.conf

# Add SSL requirement
hostssl  metrics  metrics_writer  0.0.0.0/0  md5

# Edit postgresql.conf
sudo nano /etc/postgresql/16/main/postgresql.conf

# Enable SSL
ssl = on
ssl_cert_file = '/etc/postgresql/16/main/server.crt'
ssl_key_file = '/etc/postgresql/16/main/server.key'

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### 3. API Security

```bash
# Enable JWT (in /etc/secumon/api.env)
JWT_ENABLED=true
JWT_SECRET=$(openssl rand -base64 32)

# Setup reverse proxy (nginx)
sudo apt install -y nginx

# Configure nginx
sudo tee /etc/nginx/sites-available/secumon <<'EOF'
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/secumon /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4. Rate Limiting

Consider implementing rate limiting at nginx level or using tools like fail2ban.

## Production Checklist

- [ ] TimescaleDB installed and tuned
- [ ] All migrations applied
- [ ] System user `secumon` created
- [ ] Binaries installed to /usr/local/bin
- [ ] Configuration files in /etc/secumon with proper permissions
- [ ] JWT_SECRET generated and configured
- [ ] SMTP credentials configured
- [ ] TLS certificates generated and deployed
- [ ] Systemd services installed and enabled
- [ ] Firewall rules configured
- [ ] Grafana installed and dashboards imported
- [ ] Backup strategy implemented
- [ ] Monitoring and alerting tested
- [ ] Log rotation configured
- [ ] Documentation reviewed

## Support

- **Documentation:** /opt/secumon/docs/
- **Issues:** https://github.com/secuaas/secumon/issues
- **Logs:** /var/log/secumon/ and journalctl

---

**Last Updated:** 2026-01-30
**Version:** 0.2.0+
**Status:** Production-Ready
