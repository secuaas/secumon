# SecuMon K8s Deployment Status

**Date:** 2026-01-31
**Environment:** k8s-dev (OVH)
**Status:** Infrastructure Deployed ✅

---

## Deployment Summary

### ✅ Completed

1. **Kubernetes Manifests Created**
   - Location: `/home/ubuntu/projects/secumon/k8s/dev/`
   - Files: 11 YAML files covering all services
   - Namespace: `secumon`

2. **Docker Images Built**
   - API: `ghcr.io/secuaas/secumon-api:latest` (57.6MB)
   - Ingestion: `ghcr.io/secuaas/secumon-ingestion:latest` (50.4MB)
   - Alerting: `ghcr.io/secuaas/secumon-alerting:latest` (43.6MB)
   - Also tagged for OVH registry: `qq9o8vqe.c1.bhs5.container-registry.ovh.net/secumon/*`

3. **Infrastructure Deployed on k8s-dev**
   - ✅ Namespace: `secumon`
   - ✅ Secrets: DB credentials, Redis, JWT
   - ✅ TimescaleDB StatefulSet (1 replica, 10Gi storage)
   - ✅ Redis Deployment (1 replica)
   - ✅ Grafana Deployment (1 replica, 5Gi storage)
   - ✅ Database migrations applied successfully

4. **Database Status**
   ```
   16 tables created:
   - metrics (hypertable)
   - disk_metrics (hypertable)
   - network_metrics (hypertable)
   - process_metrics (hypertable)
   - disk_io_metrics (hypertable)
   - agents
   - alerts, alert_rules, alert_history
   - notification_channels, alert_rule_channels
   - tenants, users, agent_tokens
   - dashboards, audit_logs
   ```

### ⏸️ Pending

**SecuMon Services Deployment**

The following services are not yet deployed because Docker images need to be pushed to OVH Container Registry:

- SecuMon API (2 replicas)
- SecuMon Ingestion (2 replicas)
- SecuMon Alerting (1 replica)
- Ingress for API and Grafana

**Reason:** Images are built locally but require authentication to push to OVH registry.

---

## Current Infrastructure Status

```bash
$ secuops kubectl get pods -n secumon

NAME                      READY   STATUS      RESTARTS   AGE
grafana-c55846b74-fkzd6   1/1     Running     0          5m
redis-85c7458db5-q87zt    1/1     Running     0          7m
secumon-migrations-rkjws  0/1     Completed   0          2m
timescaledb-0             1/1     Running     0          5m
```

```bash
$ secuops kubectl get svc -n secumon

NAME          TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
grafana       ClusterIP   10.3.127.221    <none>        3000/TCP   5m
redis         ClusterIP   10.3.199.24     <none>        6379/TCP   7m
timescaledb   ClusterIP   10.3.129.148    <none>        5432/TCP   5m
```

```bash
$ secuops kubectl get pvc -n secumon

NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES
grafana-pvc       Bound    ovh-managed-kubernetes-xxx                 5Gi        RWO
timescaledb-pvc   Bound    ovh-managed-kubernetes-yyy                 10Gi       RWO
```

---

## Next Steps to Complete Deployment

### Option 1: Push Images to OVH Registry (Recommended)

1. **Create Robot Account for Registry**
   ```bash
   secuops registry users add \
     --registry=secuops-registry \
     --login=secumon-robot \
     --email=robot@secuaas.com
   ```

2. **Get Robot Password**
   - Via OVH Manager or API
   - Save credentials securely

3. **Login to Registry**
   ```bash
   docker login qq9o8vqe.c1.bhs5.container-registry.ovh.net \
     -u secumon-robot \
     -p <robot-password>
   ```

4. **Push Images**
   ```bash
   docker push qq9o8vqe.c1.bhs5.container-registry.ovh.net/secumon/api:latest
   docker push qq9o8vqe.c1.bhs5.container-registry.ovh.net/secumon/ingestion:latest
   docker push qq9o8vqe.c1.bhs5.container-registry.ovh.net/secumon/alerting:latest
   ```

5. **Create ImagePullSecret in K8s**
   ```bash
   secuops kubectl create secret docker-registry ovh-registry-secret \
     --docker-server=qq9o8vqe.c1.bhs5.container-registry.ovh.net \
     --docker-username=secumon-robot \
     --docker-password=<robot-password> \
     -n secumon
   ```

6. **Update Deployments to Use ImagePullSecret**
   Add to each deployment spec:
   ```yaml
   spec:
     template:
       spec:
         imagePullSecrets:
         - name: ovh-registry-secret
   ```

7. **Deploy Services**
   ```bash
   cd /home/ubuntu/projects/secumon/k8s/dev
   secuops kubectl apply -f 05-ingestion.yaml
   secuops kubectl apply -f 06-api.yaml
   secuops kubectl apply -f 07-alerting.yaml
   secuops kubectl apply -f 08-ingress.yaml
   ```

### Option 2: Use GitHub Container Registry

1. **Authenticate to GHCR**
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u secuaas --password-stdin
   ```

2. **Push Images to GHCR**
   ```bash
   docker push ghcr.io/secuaas/secumon-api:latest
   docker push ghcr.io/secuaas/secumon-ingestion:latest
   docker push ghcr.io/secuaas/secumon-alerting:latest
   ```

3. **Update Manifests to Use GHCR**
   Change image references in `05-ingestion.yaml`, `06-api.yaml`, `07-alerting.yaml`:
   ```yaml
   image: ghcr.io/secuaas/secumon-api:latest
   ```

4. **Create GHCR ImagePullSecret** (if repos are private)
   ```bash
   secuops kubectl create secret docker-registry ghcr-secret \
     --docker-server=ghcr.io \
     --docker-username=secuaas \
     --docker-password=$GITHUB_TOKEN \
     -n secumon
   ```

5. **Deploy Services**

---

## Quick Deploy with Makefile

Once images are pushed to registry:

```bash
cd /home/ubuntu/projects/secumon/k8s/dev
make deploy   # Deploys all services
make status   # Check deployment status
make logs-api # View API logs
```

---

## Service URLs (After Full Deployment)

| Service | Internal URL | External URL (after Ingress) |
|---------|-------------|------------------------------|
| **API** | http://secumon-api.secumon.svc.cluster.local | https://secumon-api.dev.secuaas.com |
| **WebSocket** | ws://secumon-api.secumon.svc.cluster.local/ws/metrics/:agent_id | wss://secumon-api.dev.secuaas.com/ws/metrics/:agent_id |
| **Grafana** | http://grafana.secumon.svc.cluster.local:3000 | https://secumon-grafana.dev.secuaas.com |
| **TimescaleDB** | timescaledb.secumon.svc.cluster.local:5432 | Internal only |
| **Redis** | redis.secumon.svc.cluster.local:6379 | Internal only |

---

## Testing After Deployment

### 1. Verify API Health
```bash
# Via kubectl port-forward
secuops kubectl port-forward -n secumon svc/secumon-api 8099:80
curl http://localhost:8099/health

# Or via Ingress (after deployment)
curl https://secumon-api.dev.secuaas.com/health
```

### 2. Test WebSocket Connection
```javascript
const ws = new WebSocket('wss://secumon-api.dev.secuaas.com/ws/metrics/tools');
ws.onmessage = (e) => console.log(JSON.parse(e.data));
```

### 3. Access Grafana
```
URL: https://secumon-grafana.dev.secuaas.com
User: admin
Pass: admin
```

### 4. Query Metrics API
```bash
curl https://secumon-api.dev.secuaas.com/api/v1/metrics/latest/tools?limit=10
```

---

## Resources Created

### Deployments
- `grafana` (1 replica)
- `redis` (1 replica)
- `secumon-api` (pending - 2 replicas)
- `secumon-ingestion` (pending - 2 replicas)
- `secumon-alerting` (pending - 1 replica)

### StatefulSets
- `timescaledb` (1 replica)

### Services
- `grafana` (ClusterIP, port 3000)
- `redis` (ClusterIP, port 6379)
- `timescaledb` (ClusterIP, port 5432)
- `secumon-api` (pending - ClusterIP, port 80)
- `secumon-ingestion` (pending - ClusterIP, port 9090)

### PVCs
- `grafana-pvc` (5Gi, csi-cinder-high-speed)
- `timescaledb-pvc` (10Gi, csi-cinder-high-speed)

### ConfigMaps
- `timescaledb-init` (initial SQL scripts)
- `grafana-datasources` (TimescaleDB datasource config)
- `secumon-migrations` (all database migrations)

### Secrets
- `secumon-db` (TimescaleDB credentials)
- `secumon-redis` (Redis connection info)
- `secumon-jwt` (JWT configuration)

### Ingress (pending)
- `secumon-api` (TLS, cert-manager, WebSocket support)
- `secumon-grafana` (TLS, cert-manager)

---

## Troubleshooting

### TimescaleDB Not Starting
- Check PVC is bound: `secuops kubectl get pvc -n secumon`
- Check logs: `secuops kubectl logs -n secumon timescaledb-0`
- Verify PGDATA env var: `/var/lib/postgresql/data/pgdata`

### Grafana Permission Issues
- Ensure securityContext is set:
  ```yaml
  securityContext:
    fsGroup: 472
    runAsUser: 472
  ```

### Migrations Failing
- Check TimescaleDB is ready first
- View job logs: `secuops kubectl logs -n secumon <migration-pod>`
- Re-run: `secuops kubectl delete job secumon-migrations -n secumon && secuops kubectl apply -f 11-migrations-job.yaml`

---

## Files

All K8s manifests are in `/home/ubuntu/projects/secumon/k8s/dev/`:

```
00-namespace.yaml           # Namespace definition
01-timescaledb.yaml         # TimescaleDB StatefulSet + PVC
02-redis.yaml               # Redis Deployment
03-grafana.yaml             # Grafana Deployment + PVC
04-secrets.yaml             # All secrets
05-ingestion.yaml           # Ingestion Deployment (pending push)
06-api.yaml                 # API Deployment (pending push)
07-alerting.yaml            # Alerting Deployment (pending push)
08-ingress.yaml             # Ingress rules
11-migrations-job.yaml      # Database migrations Job
Makefile                    # Deployment automation
```

---

**Status:** Infrastructure ready, awaiting image push to registry for final service deployment.

**Last Updated:** 2026-01-31
