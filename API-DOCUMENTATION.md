# SecuMon - API REST Documentation

Version: 0.3.0

## Base URL

```
http://localhost:8080
```

## Authentication

JWT authentication is optional and can be enabled via environment variable `JWT_ENABLED=true`.

When enabled, protected endpoints require:
```
Authorization: Bearer <jwt_token>
```

### Auth Endpoints

#### Login
**POST** `/api/v1/auth/login`

**Request:**
```json
{
  "username": "admin",
  "password": "password"
}
```

**Response:**
```json
{
  "token": "eyJhbGc...",
  "refresh_token": "eyJhbGc...",
  "expires_in": 3600
}
```

#### Refresh Token
**POST** `/api/v1/auth/refresh`

**Request:**
```json
{
  "refresh_token": "eyJhbGc..."
}
```

#### Logout
**POST** `/api/v1/auth/logout`

## Response Format

All API responses follow this structure:

**Success:**
```json
{
  "data": { ... },
  "count": 10,
  "message": "Success"
}
```

**Error:**
```json
{
  "error": "Error message",
  "code": 400
}
```

## Endpoints

### Health Check

Check API health status.

**Endpoint:** `GET /health`

**Response:**
```json
{
  "status": "healthy",
  "service": "secumon-api",
  "timestamp": 1769829882
}
```

---

### List Active Agents

Get list of agents that sent metrics in the last hour.

**Endpoint:** `GET /api/v1/agents`

**Response:**
```json
{
  "count": 2,
  "agents": [
    "server-001",
    "server-002"
  ]
}
```

---

### Get Latest Metrics

Retrieve the most recent metrics for a specific agent.

**Endpoint:** `GET /api/v1/metrics/latest/:agent_id`

**Parameters:**
- `agent_id` (path, required) - Agent identifier
- `limit` (query, optional) - Number of metrics to return (default: 100, max: 10000)

**Example:**
```bash
GET /api/v1/metrics/latest/server-001?limit=5
```

**Response:**
```json
{
  "agent_id": "server-001",
  "count": 5,
  "metrics": [
    {
      "time": "2024-01-30T22:19:11.131228-05:00",
      "agent_id": "server-001",
      "metric_type": "cpu",
      "metric_name": "usage_percent",
      "value": 39.37,
      "tags": {}
    },
    {
      "time": "2024-01-30T22:19:11.131228-05:00",
      "agent_id": "server-001",
      "metric_type": "cpu",
      "metric_name": "load_avg_1",
      "value": 2.95,
      "tags": {}
    },
    ...
  ]
}
```

---

### Get Metrics by Time Range

Query metrics within a specific time range.

**Endpoint:** `GET /api/v1/metrics/range/:agent_id`

**Parameters:**
- `agent_id` (path, required) - Agent identifier
- `start` (query, optional) - Start time in RFC3339 format (default: -24h)
- `end` (query, optional) - End time in RFC3339 format (default: now)
- `limit` (query, optional) - Max results (default: 1000, max: 10000)

**Example:**
```bash
GET /api/v1/metrics/range/server-001?start=2024-01-29T00:00:00Z&end=2024-01-30T00:00:00Z&limit=500
```

**Response:**
```json
{
  "agent_id": "server-001",
  "start": "2024-01-29T00:00:00Z",
  "end": "2024-01-30T00:00:00Z",
  "count": 450,
  "metrics": [
    {
      "time": "2024-01-29T23:59:00Z",
      "agent_id": "server-001",
      "metric_type": "memory",
      "metric_name": "usage_percent",
      "value": 75.2,
      "tags": {}
    },
    ...
  ]
}
```

---

### Get Disk Metrics

Retrieve disk usage metrics per partition.

**Endpoint:** `GET /api/v1/metrics/disk/:agent_id`

**Parameters:**
- `agent_id` (path, required) - Agent identifier
- `start` (query, optional) - Start time RFC3339 (default: -24h)
- `end` (query, optional) - End time RFC3339 (default: now)
- `limit` (query, optional) - Max results (default: 1000, max: 10000)

**Example:**
```bash
GET /api/v1/metrics/disk/server-001?limit=10
```

**Response:**
```json
{
  "agent_id": "server-001",
  "start": "2024-01-29T22:30:00Z",
  "end": "2024-01-30T22:30:00Z",
  "count": 3,
  "metrics": [
    {
      "time": "2024-01-30T22:19:11Z",
      "agent_id": "server-001",
      "device": "/dev/sda1",
      "mount_point": "/",
      "filesystem": "ext4",
      "total_bytes": 206900281344,
      "used_bytes": 37557932032,
      "available_bytes": 169325572096,
      "usage_percent": 18.15,
      "inodes_total": 26083328,
      "inodes_used": 997477,
      "inodes_percent": 3.82
    },
    {
      "time": "2024-01-30T22:19:11Z",
      "agent_id": "server-001",
      "device": "/dev/sda16",
      "mount_point": "/boot",
      "filesystem": "ext4",
      "total_bytes": 923156480,
      "used_bytes": 122003456,
      "available_bytes": 736509952,
      "usage_percent": 14.21,
      "inodes_total": 58496,
      "inodes_used": 604,
      "inodes_percent": 1.03
    },
    ...
  ]
}
```

---

### Get Network Metrics

Retrieve network statistics per interface.

**Endpoint:** `GET /api/v1/metrics/network/:agent_id`

**Parameters:**
- `agent_id` (path, required) - Agent identifier
- `start` (query, optional) - Start time RFC3339 (default: -24h)
- `end` (query, optional) - End time RFC3339 (default: now)
- `limit` (query, optional) - Max results (default: 1000, max: 10000)

**Example:**
```bash
GET /api/v1/metrics/network/server-001?limit=5
```

**Response:**
```json
{
  "agent_id": "server-001",
  "start": "2024-01-29T22:30:00Z",
  "end": "2024-01-30T22:30:00Z",
  "count": 5,
  "metrics": [
    {
      "time": "2024-01-30T22:19:11Z",
      "agent_id": "server-001",
      "interface": "eth0",
      "bytes_sent": 1382943312,
      "bytes_recv": 2505301971,
      "packets_sent": 8523412,
      "packets_recv": 9234521,
      "errors_in": 0,
      "errors_out": 0,
      "drop_in": 0,
      "drop_out": 0,
      "is_up": true
    },
    {
      "time": "2024-01-30T22:19:11Z",
      "agent_id": "server-001",
      "interface": "docker0",
      "bytes_sent": 823577268,
      "bytes_recv": 13924739,
      "packets_sent": 524123,
      "packets_recv": 98234,
      "errors_in": 0,
      "errors_out": 0,
      "drop_in": 0,
      "drop_out": 0,
      "is_up": true
    },
    ...
  ]
}
```

---

### Get Process Metrics

Retrieve top processes by CPU usage.

**Endpoint:** `GET /api/v1/metrics/process/:agent_id`

**Parameters:**
- `agent_id` (path, required) - Agent identifier
- `start` (query, optional) - Start time RFC3339 (default: -24h)
- `end` (query, optional) - End time RFC3339 (default: now)
- `limit` (query, optional) - Max results (default: 100, max: 100)

**Example:**
```bash
GET /api/v1/metrics/process/server-001?limit=5
```

**Response:**
```json
{
  "agent_id": "server-001",
  "start": "2024-01-29T22:30:00Z",
  "end": "2024-01-30T22:30:00Z",
  "count": 5,
  "metrics": [
    {
      "time": "2024-01-30T22:19:11Z",
      "agent_id": "server-001",
      "pid": 603576,
      "name": "node",
      "cmdline": "",
      "username": "root",
      "cpu_percent": 144.19,
      "memory_bytes": 316416000,
      "memory_percent": 1.29,
      "num_threads": 11,
      "status": "running"
    },
    {
      "time": "2024-01-30T22:19:11Z",
      "agent_id": "server-001",
      "pid": 600666,
      "name": "claude",
      "cmdline": "",
      "username": "root",
      "cpu_percent": 12.17,
      "memory_bytes": 501776384,
      "memory_percent": 2.04,
      "num_threads": 8,
      "status": "running"
    },
    ...
  ]
}
```

---

## Error Codes

| Code | Description |
|------|-------------|
| 200  | Success |
| 400  | Bad Request - Invalid parameters |
| 404  | Not Found - Resource doesn't exist |
| 500  | Internal Server Error |

## Rate Limiting

Currently no rate limiting (TODO).

## Query Tips

### Time Range Format

Use RFC3339 format for timestamps:
```
2024-01-30T15:30:00Z        # UTC
2024-01-30T10:30:00-05:00   # EST
```

### Pagination

For large datasets, use `limit` and time-based pagination:

```bash
# First page (latest 1000)
GET /api/v1/metrics/range/server-001?limit=1000

# Next page (older data)
GET /api/v1/metrics/range/server-001?end=<oldest_time_from_previous>&limit=1000
```

### Performance

- Queries with time ranges are faster than open-ended queries
- Smaller time ranges return results faster
- Use appropriate limits to avoid large payloads
- CPU/Memory metrics use key-value model (more rows)
- Disk/Network/Process metrics are normalized (fewer rows)

### Filtering by Metric Type

To get only specific metrics, filter the response client-side or use time-range queries with smaller windows.

Example (client-side filtering):
```javascript
const response = await fetch('/api/v1/metrics/latest/server-001?limit=100');
const data = await response.json();

// Filter only CPU metrics
const cpuMetrics = data.metrics.filter(m => m.metric_type === 'cpu');

// Filter specific metric
const cpuUsage = data.metrics.find(m =>
  m.metric_type === 'cpu' && m.metric_name === 'usage_percent'
);
```

## Future Endpoints (TODO)

### Authentication
- `POST /api/v1/auth/login` - Login with credentials
- `POST /api/v1/auth/refresh` - Refresh JWT token
- `POST /api/v1/auth/logout` - Logout and invalidate token

### Agents Management
- `GET /api/v1/agents` - List all agents (enhanced)
- `GET /api/v1/agents/:id` - Get agent details
- `POST /api/v1/agents` - Register new agent
- `PUT /api/v1/agents/:id` - Update agent
- `DELETE /api/v1/agents/:id` - Delete agent

### Alerts
- `GET /api/v1/alerts` - List alerts
- `GET /api/v1/alerts/:id` - Get alert details
- `POST /api/v1/alerts` - Create alert rule
- `PUT /api/v1/alerts/:id` - Update alert rule
- `DELETE /api/v1/alerts/:id` - Delete alert rule

### Dashboards
- `GET /api/v1/dashboards` - List dashboards
- `GET /api/v1/dashboards/:id` - Get dashboard
- `POST /api/v1/dashboards` - Create dashboard
- `PUT /api/v1/dashboards/:id` - Update dashboard
- `DELETE /api/v1/dashboards/:id` - Delete dashboard

### Users (Multi-tenant)
- `GET /api/v1/users` - List users
- `POST /api/v1/users` - Create user
- `PUT /api/v1/users/:id` - Update user
- `DELETE /api/v1/users/:id` - Delete user

## Examples

### JavaScript (Fetch API)

```javascript
// Get latest metrics
async function getLatestMetrics(agentId, limit = 100) {
  const response = await fetch(
    `http://localhost:8080/api/v1/metrics/latest/${agentId}?limit=${limit}`
  );
  return response.json();
}

// Get metrics for last 24 hours
async function getMetricsLast24h(agentId) {
  const end = new Date().toISOString();
  const start = new Date(Date.now() - 24*60*60*1000).toISOString();

  const response = await fetch(
    `http://localhost:8080/api/v1/metrics/range/${agentId}?start=${start}&end=${end}`
  );
  return response.json();
}
```

### Python (requests)

```python
import requests
from datetime import datetime, timedelta

# Get active agents
def get_agents():
    response = requests.get('http://localhost:8080/api/v1/agents')
    return response.json()

# Get disk metrics
def get_disk_metrics(agent_id, limit=100):
    response = requests.get(
        f'http://localhost:8080/api/v1/metrics/disk/{agent_id}',
        params={'limit': limit}
    )
    return response.json()

# Get metrics for last hour
def get_metrics_last_hour(agent_id):
    end = datetime.utcnow().isoformat() + 'Z'
    start = (datetime.utcnow() - timedelta(hours=1)).isoformat() + 'Z'

    response = requests.get(
        f'http://localhost:8080/api/v1/metrics/range/{agent_id}',
        params={'start': start, 'end': end}
    )
    return response.json()
```

### cURL

```bash
# Health check
curl -s http://localhost:8080/health | jq

# List agents
curl -s http://localhost:8080/api/v1/agents | jq

# Get latest metrics
curl -s "http://localhost:8080/api/v1/metrics/latest/server-001?limit=10" | jq

# Get metrics for specific time range
curl -s "http://localhost:8080/api/v1/metrics/range/server-001?\
start=2024-01-29T00:00:00Z&\
end=2024-01-30T00:00:00Z&\
limit=500" | jq

# Get disk metrics
curl -s "http://localhost:8080/api/v1/metrics/disk/server-001" | jq '.metrics[] | {device, mount_point, usage_percent}'

# Get network metrics
curl -s "http://localhost:8080/api/v1/metrics/network/server-001?limit=5" | jq

# Get process metrics
curl -s "http://localhost:8080/api/v1/metrics/process/server-001?limit=10" | jq '.metrics[] | {pid, name, cpu_percent, memory_bytes}'
```

---

## Agents Management

### List Agents

Get a paginated list of agents with optional filtering.

**Endpoint:** `GET /api/v1/agents`

**Query Parameters:**
- `status` (optional) - Filter by status: `active`, `inactive`
- `limit` (optional) - Results per page (default: 100)
- `offset` (optional) - Pagination offset (default: 0)

**Example:**
```bash
GET /api/v1/agents?status=active&limit=50&offset=0
```

**Response:**
```json
{
  "agents": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "server-prod-01",
      "hostname": "prod01.example.com",
      "ip_address": "192.168.1.10",
      "os": "Ubuntu",
      "os_version": "22.04",
      "agent_version": "0.3.0",
      "status": "active",
      "last_seen_at": "2026-01-30T23:23:29Z",
      "last_metrics_at": "2026-01-30T23:23:29Z",
      "created_at": "2026-01-20T10:00:00Z",
      "updated_at": "2026-01-30T23:20:00Z"
    }
  ],
  "total": 142,
  "limit": 50,
  "offset": 0
}
```

### Get Agent by ID

Retrieve details for a specific agent.

**Endpoint:** `GET /api/v1/agents/:id`

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "server-prod-01",
  "hostname": "prod01.example.com",
  "ip_address": "192.168.1.10",
  "os": "Ubuntu",
  "os_version": "22.04",
  "agent_version": "0.3.0",
  "status": "active",
  "labels": {},
  "last_seen_at": "2026-01-30T23:23:29Z",
  "created_at": "2026-01-20T10:00:00Z",
  "updated_at": "2026-01-30T23:20:00Z"
}
```

### Create Agent

Register a new agent.

**Endpoint:** `POST /api/v1/agents`

**Request:**
```json
{
  "name": "server-prod-02",
  "hostname": "prod02.example.com",
  "ip_address": "192.168.1.11",
  "os": "Ubuntu",
  "os_version": "22.04",
  "agent_version": "0.3.0"
}
```

**Response:** `201 Created`
```json
{
  "id": "650e8400-e29b-41d4-a716-446655440001",
  "name": "server-prod-02",
  "status": "active",
  ...
}
```

### Update Agent

Update agent information.

**Endpoint:** `PUT /api/v1/agents/:id`

**Request:**
```json
{
  "name": "server-prod-02-updated",
  "status": "inactive"
}
```

**Response:** Updated agent object

### Delete Agent

Remove an agent.

**Endpoint:** `DELETE /api/v1/agents/:id`

**Response:** `204 No Content`

### Agent Statistics

Get agent statistics.

**Endpoint:** `GET /api/v1/agents/stats`

**Response:**
```json
{
  "total": 142,
  "active": 138,
  "inactive": 4,
  "online": 135,
  "offline": 7
}
```

---

## WebSocket - Real-Time Metrics

### Connect to Metrics Stream

Establish a WebSocket connection to receive real-time metrics for an agent.

**Endpoint:** `WS /ws/metrics/:agent_id`

**Example:**
```javascript
const ws = new WebSocket('ws://localhost:8080/ws/metrics/server-001');

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Metrics:', message);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('Connection closed');
};
```

**Message Format:**
```json
{
  "type": "metrics",
  "agent_id": "server-001",
  "timestamp": "2026-01-30T23:23:29Z",
  "data": {
    "cpu.usage_percent": {
      "value": 15.2,
      "timestamp": "2026-01-30T23:23:29Z"
    },
    "memory.usage_percent": {
      "value": 45.7,
      "timestamp": "2026-01-30T23:23:29Z"
    },
    "cpu.load_avg_1": {
      "value": 1.02,
      "timestamp": "2026-01-30T23:23:29Z"
    }
  }
}
```

**Features:**
- Metrics streamed every 2 seconds
- Automatic reconnection support
- Ping/Pong heartbeat (54s interval)
- Latest metrics from past 30 seconds
- Up to 100 metrics per message

**Filter Updates** (Client → Server):
```json
{
  "type": "filter",
  "metric_types": ["cpu", "memory"],
  "metric_names": ["usage_percent"]
}
```

---

## Changelog

### Version 0.3.0 (2026-01-31)
- **New:** WebSocket real-time metrics streaming
- **New:** Agents management CRUD endpoints (7 routes)
- **New:** Agent statistics endpoint
- **New:** JWT authentication (optional)
- **New:** Auth endpoints (login, refresh, logout)
- TimescaleDB continuous aggregates (4 views)
- Compression policies (7-day threshold)
- Retention policies (30d raw, 90d/365d aggregates)
- API extended to 44+ handlers

### Version 0.2.0 (2026-01-30)
- Alerts API (9 endpoints)
- Email notifications (SMTP)
- Slack/Webhook notifications
- Production deployment tooling
- Grafana dashboards (3)

### Version 0.1.0 (2026-01-30)
- Initial API implementation
- Health check endpoint
- Agents list endpoint
- Metrics query endpoints (latest, range, disk, network, process)
- TimescaleDB integration
- RFC3339 time range support
