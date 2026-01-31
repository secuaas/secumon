# SecuMon v0.3.0 - Quick Reference Guide

## 🚀 Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| **REST API** | http://localhost:8099 | None (JWT optional) |
| **WebSocket** | ws://localhost:8099/ws/metrics/:agent_id | None |
| **Grafana** | http://localhost:3001 | admin / admin |
| **TimescaleDB** | localhost:5433 | metrics_writer / metrics_dev_pass |
| **Adminer** | http://localhost:8081 | - |

## 📡 API Endpoints

### Health & Status
```bash
curl http://localhost:8099/health
curl http://localhost:8099/api/v1/agents/stats
```

### Agents
```bash
# List agents
curl http://localhost:8099/api/v1/agents

# Get agent stats
curl http://localhost:8099/api/v1/agents/stats

# Get specific agent
curl http://localhost:8099/api/v1/agents/{id}

# Create agent
curl -X POST http://localhost:8099/api/v1/agents \
  -H "Content-Type: application/json" \
  -d '{"name":"server-01","hostname":"srv01.local"}'
```

### Metrics
```bash
# Latest metrics
curl "http://localhost:8099/api/v1/metrics/latest/tools?limit=10"

# Metrics by time range
curl "http://localhost:8099/api/v1/metrics/range/tools?start=2026-01-30T00:00:00Z&end=2026-01-31T00:00:00Z"

# Disk metrics
curl http://localhost:8099/api/v1/metrics/disk/tools

# Network metrics
curl http://localhost:8099/api/v1/metrics/network/tools

# Process metrics
curl http://localhost:8099/api/v1/metrics/process/tools
```

### Alerts
```bash
# List alerts
curl http://localhost:8099/api/v1/alerts

# Alert statistics
curl http://localhost:8099/api/v1/alerts/stats

# Acknowledge alert
curl -X POST http://localhost:8099/api/v1/alerts/{id}/acknowledge

# List alert rules
curl http://localhost:8099/api/v1/alert-rules

# Create alert rule
curl -X POST http://localhost:8099/api/v1/alert-rules \
  -H "Content-Type: application/json" \
  -d '{
    "name":"High CPU",
    "metric_type":"cpu",
    "metric_name":"usage_percent",
    "condition":"gt",
    "threshold":90,
    "severity":"critical"
  }'
```

## 🔌 WebSocket Connection

### JavaScript
```javascript
const ws = new WebSocket('ws://localhost:8099/ws/metrics/tools');

ws.onopen = () => console.log('Connected!');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Metrics:', data);
};

ws.onerror = (error) => console.error('Error:', error);

ws.onclose = () => console.log('Disconnected');
```

### Python
```python
import websocket
import json

def on_message(ws, message):
    data = json.loads(message)
    print(f"Metrics: {data}")

ws = websocket.WebSocketApp(
    "ws://localhost:8099/ws/metrics/tools",
    on_message=on_message
)
ws.run_forever()
```

## 🐳 Docker Commands

```bash
# Check all containers
docker ps --format "table {{.Names}}\t{{.Status}}"

# View TimescaleDB logs
docker logs secumon-timescaledb -f

# Connect to TimescaleDB
docker exec -it secumon-timescaledb psql -U metrics_writer -d metrics

# Restart services
docker restart secumon-timescaledb secumon-grafana
```

## 📊 Database Queries

```sql
-- Connect to TimescaleDB
docker exec -it secumon-timescaledb psql -U metrics_writer -d metrics

-- View latest metrics
SELECT agent_id, metric_type, metric_name, value, time
FROM metrics
ORDER BY time DESC
LIMIT 10;

-- Check continuous aggregates
SELECT view_name, materialization_hypertable_name
FROM timescaledb_information.continuous_aggregates;

-- View background jobs
SELECT job_id, hypertable_name, proc_name, scheduled
FROM timescaledb_information.jobs
WHERE hypertable_name IS NOT NULL;

-- Check compression status
SELECT hypertable_name, compression_enabled
FROM timescaledb_information.hypertables;
```

## 🔧 Service Management

### Check Running Services
```bash
# SecuMon services
ps aux | grep -E "(bin/ingestion|bin/api|bin/alerting|bin/secumon-agent)" | grep -v grep

# Docker services
docker ps | grep secumon
```

### Start/Stop Services
```bash
# Start API
API_PORT=8099 DB_HOST=localhost ./bin/api &

# Start Ingestion
GRPC_PORT=9090 DB_HOST=localhost ./bin/ingestion &

# Start Agent
./bin/secumon-agent --config=config.yaml &

# Kill services
pkill -f "bin/api"
pkill -f "bin/ingestion"
pkill -f "bin/secumon-agent"
```

### Build Binaries
```bash
cd /home/ubuntu/projects/secumon-collector

# Build all
/usr/local/go/bin/go build -o bin/api cmd/api/main.go
/usr/local/go/bin/go build -o bin/ingestion cmd/ingestion/main.go
/usr/local/go/bin/go build -o bin/alerting cmd/alerting/main.go

# Build agent
cd /home/ubuntu/projects/secumon-agent
/usr/local/go/bin/go build -o bin/secumon-agent cmd/agent/main.go
```

## 📈 Grafana Dashboards

Access: http://localhost:3001 (admin / admin)

**Available Dashboards:**
1. **System Overview** - CPU, Memory, Load, Disk usage
2. **Network & Process** - Network traffic, top processes
3. **Alerts** - Active alerts, frequency, severity

**Datasource:**
- Name: TimescaleDB
- Type: PostgreSQL
- Host: secumon-timescaledb:5432
- Database: metrics
- Auto-provisioned: Yes

## 🧪 Testing

### Quick Health Check
```bash
# All-in-one test
curl -s http://localhost:8099/health | jq && \
curl -s http://localhost:8099/api/v1/agents/stats | jq && \
curl -s "http://localhost:8099/api/v1/metrics/latest/tools?limit=3" | jq '.count'
```

### Full E2E Test
```bash
# 1. Check services
ps aux | grep -E "bin/(api|ingestion|agent)" | grep -v grep

# 2. Test API
curl http://localhost:8099/health

# 3. Check metrics in DB
docker exec secumon-timescaledb psql -U metrics_writer -d metrics \
  -c "SELECT COUNT(*) FROM metrics;"

# 4. Verify aggregates
docker exec secumon-timescaledb psql -U metrics_writer -d metrics \
  -c "SELECT view_name FROM timescaledb_information.continuous_aggregates;"
```

## 📝 Configuration Files

### API Config (Environment)
```bash
export API_PORT=8099
export DB_HOST=localhost
export DB_PORT=5433
export DB_USER=metrics_writer
export DB_PASSWORD=metrics_dev_pass
export DB_NAME=metrics
export JWT_ENABLED=false
```

### Agent Config (YAML)
```yaml
# config.yaml
agent:
  name: "my-server"

collector:
  endpoint: "localhost:9090"
  tls:
    enabled: false

metrics:
  interval: 60s
  enabled:
    - cpu
    - memory
    - disk
    - network
    - processes
```

### Alerting Config (Environment)
```bash
export SMTP_HOST=smtp.gmail.com
export SMTP_PORT=587
export SMTP_USER=alerts@domain.com
export SMTP_PASS=app_password
export EMAIL_FROM=alerts@domain.com
export EMAIL_TO=admin@domain.com,ops@domain.com
export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX
```

## 🔍 Troubleshooting

### API Not Responding
```bash
# Check if running
ps aux | grep "bin/api"

# Check logs
tail -f /tmp/api.log

# Restart
pkill -f "bin/api"
API_PORT=8099 ./bin/api > /tmp/api.log 2>&1 &
```

### No Metrics in Database
```bash
# Check agent is running
ps aux | grep "secumon-agent"

# Check ingestion service
ps aux | grep "bin/ingestion"

# Check agent logs
tail -f /tmp/agent.log

# Verify gRPC connection
curl http://localhost:9090/health  # Should fail (gRPC not HTTP)
```

### TimescaleDB Issues
```bash
# Check container health
docker ps | grep timescale

# View logs
docker logs secumon-timescaledb --tail 50

# Restart
docker restart secumon-timescaledb

# Connect and verify
docker exec -it secumon-timescaledb psql -U metrics_writer -d metrics
```

## 📚 Documentation Links

- [Complete API Documentation](./API-DOCUMENTATION.md)
- [Phase 5 Completion Report](./PHASE5-COMPLETION-REPORT.md)
- [Production Deployment Guide](./PRODUCTION-DEPLOYMENT-GUIDE.md)
- [Session Summary](./SESSION-SUMMARY.md)
- [Main README](./README.md)

## 🎯 Common Tasks

### Add New Metric Type
1. Update agent collectors in `secumon-agent/internal/collector/`
2. Add to protobuf in `secumon-common/proto/metrics/`
3. Update writer in `secumon-collector/internal/storage/metrics/writer.go`
4. Create new hypertable if needed

### Create New Dashboard
1. Design in Grafana UI
2. Export JSON
3. Save to `grafana/dashboards/`
4. Restart Grafana

### Add Alert Rule
```bash
curl -X POST http://localhost:8099/api/v1/alert-rules \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Rule Name",
    "metric_type": "cpu",
    "metric_name": "usage_percent",
    "condition": "gt",
    "threshold": 80,
    "duration": "5m",
    "severity": "warning"
  }'
```

---

**Quick Links:**
- API: http://localhost:8099
- Grafana: http://localhost:3001
- WebSocket: ws://localhost:8099/ws/metrics/:agent_id

**Status:** ✅ All systems operational
