# SecuMon - Quick Start Guide

Guide de démarrage rapide pour utiliser SecuMon déployé sur k8s-dev.

---

## 🚀 Accès Rapide

### API
```bash
curl https://secumon-api.dev.secuaas.com/health
```

### Grafana
```
URL: https://secumon-grafana.dev.secuaas.com
User: admin
Pass: admin
```

---

## 📋 Commandes Utiles

### Vérifier le Statut
```bash
# Tous les pods
secuops kubectl get pods -n secumon

# Détails d'un pod
secuops kubectl describe pod -n secumon <pod-name>

# Logs en temps réel
secuops kubectl logs -f -n secumon -l app=secumon-api
```

### Déploiement (depuis k8s/dev/)
```bash
# Tout déployer
make deploy

# Vérifier le statut
make status

# Voir les logs
make logs-api
make logs-ingestion
make logs-alerting
```

### Database
```bash
# Se connecter à TimescaleDB
secuops kubectl -- exec -it -n secumon timescaledb-0 -- \
  psql -U metrics_writer -d metrics

# Vérifier les tables
\dt

# Vérifier les hypertables
SELECT * FROM timescaledb_information.hypertables;

# Voir les métriques
SELECT COUNT(*) FROM metrics;
```

---

## 🤖 Déployer un Agent

### 1. Créer un Agent Token (via API)
```bash
curl -X POST https://secumon-api.dev.secuaas.com/api/v1/agents \
  -H "Content-Type: application/json" \
  -d '{
    "id": "server-01",
    "hostname": "production-web-01",
    "labels": {
      "env": "production",
      "role": "webserver"
    }
  }'
```

### 2. Configurer l'Agent
```bash
# Sur le serveur à monitorer
cd /home/ubuntu/projects/secumon-agent

cat > config.yaml <<EOF
server:
  api_url: https://secumon-api.dev.secuaas.com
  ingestion_url: secumon-ingestion.secumon.svc.cluster.local:9090

agent:
  id: server-01
  hostname: $(hostname)

collection:
  interval: 30s

metrics:
  - cpu
  - memory
  - disk
  - network
  - processes
EOF
```

### 3. Démarrer l'Agent
```bash
./bin/agent --config config.yaml
```

---

## 📊 Créer un Dashboard Grafana

### 1. Se Connecter
https://secumon-grafana.dev.secuaas.com (admin/admin)

### 2. Nouveau Dashboard
- Click "+ Create" → "Dashboard"
- Add Visualization

### 3. Exemples de Requêtes

**CPU Usage:**
```sql
SELECT
  time_bucket('5 minutes', collected_at) AS time,
  avg(value) as avg_cpu
FROM metrics
WHERE metric_name = 'cpu_usage'
  AND agent_id = 'server-01'
  AND $__timeFilter(collected_at)
GROUP BY time
ORDER BY time;
```

**Memory Usage:**
```sql
SELECT
  time_bucket('5 minutes', collected_at) AS time,
  avg(memory_used) / (1024*1024*1024) as memory_gb,
  avg(memory_total) / (1024*1024*1024) as total_gb
FROM metrics
WHERE agent_id = 'server-01'
  AND $__timeFilter(collected_at)
GROUP BY time
ORDER BY time;
```

**Disk Usage:**
```sql
SELECT
  time_bucket('1 hour', collected_at) AS time,
  path,
  avg(used_percent) as disk_used_pct
FROM disk_metrics
WHERE agent_id = 'server-01'
  AND $__timeFilter(collected_at)
GROUP BY time, path
ORDER BY time;
```

---

## 🔔 Configurer des Alertes

### Via API

**1. Créer une Règle d'Alerte:**
```bash
curl -X POST https://secumon-api.dev.secuaas.com/api/v1/alerts/rules \
  -H "Content-Type: application/json" \
  -d '{
    "name": "High CPU Usage",
    "description": "Alert when CPU exceeds 80%",
    "metric_name": "cpu_usage",
    "condition": "greater_than",
    "threshold": 80,
    "duration": "5m",
    "severity": "warning",
    "enabled": true
  }'
```

**2. Créer un Canal de Notification (Webhook):**
```bash
curl -X POST https://secumon-api.dev.secuaas.com/api/v1/alerts/channels \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Slack Alerts",
    "type": "webhook",
    "config": {
      "url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL",
      "method": "POST"
    }
  }'
```

**3. Lier la Règle au Canal:**
```bash
curl -X POST https://secumon-api.dev.secuaas.com/api/v1/alerts/rules/<rule-id>/channels \
  -H "Content-Type: application/json" \
  -d '{
    "channel_id": "<channel-id>"
  }'
```

---

## 🔍 Requêtes API Utiles

### Lister les Agents
```bash
curl https://secumon-api.dev.secuaas.com/api/v1/agents | jq
```

### Statistiques Agents
```bash
curl https://secumon-api.dev.secuaas.com/api/v1/agents/stats | jq
```

### Dernières Métriques d'un Agent
```bash
curl "https://secumon-api.dev.secuaas.com/api/v1/metrics/latest/server-01?limit=100" | jq
```

### Historique Métriques
```bash
curl "https://secumon-api.dev.secuaas.com/api/v1/metrics/history/server-01?hours=24" | jq
```

### Time Series (pour graphiques)
```bash
curl "https://secumon-api.dev.secuaas.com/api/v1/metrics/timeseries/server-01?metric=cpu_usage&interval=5m&hours=24" | jq
```

---

## 🌊 WebSocket Real-time

### JavaScript Example
```javascript
const ws = new WebSocket('wss://secumon-api.dev.secuaas.com/ws/metrics/server-01');

ws.onopen = () => {
  console.log('Connected to SecuMon WebSocket');
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log('Real-time metrics:', data);

  // Update your UI with real-time data
  updateCPUGauge(data.cpu_usage);
  updateMemoryChart(data.memory_used);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('Disconnected, reconnecting...');
  setTimeout(connectWebSocket, 5000);
};
```

---

## 🛠️ Maintenance

### Redémarrer un Service
```bash
secuops kubectl rollout restart deployment secumon-api -n secumon
```

### Voir les Logs
```bash
# API
secuops kubectl logs -n secumon -l app=secumon-api --tail=100

# Ingestion
secuops kubectl logs -n secumon -l app=secumon-ingestion --tail=100

# Alerting
secuops kubectl logs -n secumon -l app=secumon-alerting --tail=100
```

### Backup Database
```bash
# Export
secuops kubectl -- exec -n secumon timescaledb-0 -- \
  pg_dump -U metrics_writer metrics > backup-$(date +%Y%m%d).sql

# Restore
secuops kubectl -- exec -i -n secumon timescaledb-0 -- \
  psql -U metrics_writer metrics < backup-20260131.sql
```

### Mettre à Jour une Image
```bash
# 1. Rebuild l'image
cd /home/ubuntu/projects
docker build -f secumon-collector/Dockerfile.api \
  -t qq9o8vqe.c1.bhs5.container-registry.ovh.net/secuops/secumon-api:latest .

# 2. Push vers le registry
docker push qq9o8vqe.c1.bhs5.container-registry.ovh.net/secuops/secumon-api:latest

# 3. Redémarrer le déploiement
secuops kubectl rollout restart deployment secumon-api -n secumon
```

---

## 📈 Scaling

### Augmenter les Replicas
```bash
# API
secuops kubectl scale deployment secumon-api -n secumon --replicas=3

# Ingestion
secuops kubectl scale deployment secumon-ingestion -n secumon --replicas=3
```

### Augmenter les Ressources
```bash
secuops kubectl set resources deployment secumon-api -n secumon \
  --requests=cpu=200m,memory=256Mi \
  --limits=cpu=2000m,memory=1Gi
```

---

## 🆘 Troubleshooting

### Pod ne démarre pas
```bash
# Voir les events
secuops kubectl get events -n secumon --sort-by='.lastTimestamp'

# Décrire le pod
secuops kubectl describe pod -n secumon <pod-name>

# Logs du pod précédent (si crash)
secuops kubectl logs -n secumon <pod-name> --previous
```

### Problème de connexion DB
```bash
# Tester depuis un pod
secuops kubectl -- run -n secumon psql-test --rm -it --restart=Never \
  --image=postgres:16-alpine -- \
  psql postgresql://metrics_writer:metrics_prod_pass_2026@timescaledb:5432/metrics
```

### Ingress non accessible
```bash
# Vérifier les certificats
secuops kubectl get certificates -n secumon

# Vérifier l'Ingress
secuops kubectl describe ingress secumon-api -n secumon

# Vérifier Ingress Controller
secuops kubectl get pods -n ingress-nginx
```

---

## 📖 Documentation Complète

- **DEPLOYMENT-COMPLETE.md** - Guide de déploiement complet
- **API-DOCUMENTATION.md** - Documentation API complète (44+ endpoints)
- **QUICK-REFERENCE.md** - Référence rapide
- **K8S-DEPLOYMENT-STATUS.md** - État du déploiement

---

## 🔗 Liens Utiles

- **API:** https://secumon-api.dev.secuaas.com
- **Grafana:** https://secumon-grafana.dev.secuaas.com
- **GitHub Repo:** https://github.com/secuaas/secumon
- **Collector Repo:** https://github.com/secuaas/secumon-collector

---

**Happy Monitoring! 🚀**
