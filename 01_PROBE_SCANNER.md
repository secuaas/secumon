# SecuMon-Probe - Sonde Scanner Externe

## Objectif

Binaire Go autonome capable d'effectuer des tests réseau externes sur des cibles définies centralement. Déployable n'importe où (Internet public, LAN client) avec auto-provisioning WireGuard.

## Spécifications Techniques

### Caractéristiques
- **Langage**: Go 1.22+
- **Taille binaire**: < 15MB
- **RAM**: < 50MB en fonctionnement
- **CPU**: < 5% en moyenne
- **Plateformes**: Linux (amd64, arm64), Windows, macOS

### Fonctionnalités de Scan

#### 1. Tests de Connectivité
```go
type ConnectivityTest struct {
    Type        string        // "icmp", "tcp", "udp"
    Target      string        // IP ou domaine
    Port        int           // Pour TCP/UDP
    Timeout     time.Duration
    Count       int           // Nombre de paquets (ping)
}

type ConnectivityResult struct {
    Latency     LatencyStats  // min, max, avg, jitter
    PacketLoss  float64       // Pourcentage
    Reachable   bool
    TTL         int
    Timestamp   time.Time
}
```

#### 2. Traceroute
```go
type TracerouteResult struct {
    Hops        []TracerouteHop
    Destination string
    Reached     bool
    TotalTime   time.Duration
}

type TracerouteHop struct {
    Number  int
    Address string
    RTT     []time.Duration // 3 mesures
    ASN     string          // Optionnel
}
```

#### 3. Scan de Ports
```go
type PortScanConfig struct {
    Target      string
    Ports       []int         // Liste spécifique
    PortRange   string        // "1-1024" ou "common"
    Protocol    string        // "tcp", "udp"
    Technique   string        // "syn", "connect", "udp"
    Timeout     time.Duration
    Concurrent  int           // Parallélisme
}

type PortScanResult struct {
    OpenPorts    []PortInfo
    ClosedPorts  []int
    FilteredPorts []int
    ScanDuration time.Duration
}

type PortInfo struct {
    Port        int
    Protocol    string
    State       string        // "open", "closed", "filtered"
    Service     string        // Détection de service
    Banner      string        // Grab de bannière
    Version     string        // Version détectée
}
```

#### 4. Validation SSL/TLS
```go
type SSLCheckConfig struct {
    Target          string
    Port            int
    CheckChain      bool
    CheckRevocation bool
    SNI             string
}

type SSLCheckResult struct {
    Valid           bool
    Issuer          string
    Subject         string
    NotBefore       time.Time
    NotAfter        time.Time
    DaysUntilExpiry int
    Chain           []CertInfo
    Protocols       []string      // TLS 1.2, 1.3, etc.
    CipherSuites    []string
    OCSP            OCSPStatus
    Vulnerabilities []string      // Heartbleed, POODLE, etc.
    Grade           string        // A+, A, B, C, D, F
}
```

#### 5. SNMP Polling
```go
type SNMPConfig struct {
    Target      string
    Port        int           // Default 161
    Version     string        // "v1", "v2c", "v3"
    Community   string        // Pour v1/v2c
    V3Auth      SNMPv3Auth    // Pour v3
    OIDs        []string      // OIDs à interroger
    Preset      string        // "system", "network", "storage", "custom"
}

type SNMPv3Auth struct {
    Username    string
    AuthProto   string        // "MD5", "SHA", "SHA256"
    AuthPass    string
    PrivProto   string        // "DES", "AES", "AES256"
    PrivPass    string
}

// OIDs Prédéfinis par catégorie
var SNMPPresets = map[string][]OIDDefinition{
    "system": {
        {OID: "1.3.6.1.2.1.1.1.0", Name: "sysDescr", Type: "string"},
        {OID: "1.3.6.1.2.1.1.3.0", Name: "sysUpTime", Type: "timeticks"},
        {OID: "1.3.6.1.2.1.1.5.0", Name: "sysName", Type: "string"},
        {OID: "1.3.6.1.2.1.1.6.0", Name: "sysLocation", Type: "string"},
    },
    "network": {
        {OID: "1.3.6.1.2.1.2.2.1.10", Name: "ifInOctets", Type: "counter"},
        {OID: "1.3.6.1.2.1.2.2.1.16", Name: "ifOutOctets", Type: "counter"},
        {OID: "1.3.6.1.2.1.2.2.1.14", Name: "ifInErrors", Type: "counter"},
        {OID: "1.3.6.1.2.1.2.2.1.20", Name: "ifOutErrors", Type: "counter"},
        {OID: "1.3.6.1.2.1.2.2.1.8", Name: "ifOperStatus", Type: "integer"},
    },
    "storage": {
        {OID: "1.3.6.1.2.1.25.2.3.1.3", Name: "hrStorageDescr", Type: "string"},
        {OID: "1.3.6.1.2.1.25.2.3.1.5", Name: "hrStorageSize", Type: "integer"},
        {OID: "1.3.6.1.2.1.25.2.3.1.6", Name: "hrStorageUsed", Type: "integer"},
    },
    "cpu_memory": {
        {OID: "1.3.6.1.4.1.2021.11.9.0", Name: "ssCpuUser", Type: "integer"},
        {OID: "1.3.6.1.4.1.2021.11.10.0", Name: "ssCpuSystem", Type: "integer"},
        {OID: "1.3.6.1.4.1.2021.11.11.0", Name: "ssCpuIdle", Type: "integer"},
        {OID: "1.3.6.1.4.1.2021.4.5.0", Name: "memTotalReal", Type: "integer"},
        {OID: "1.3.6.1.4.1.2021.4.6.0", Name: "memAvailReal", Type: "integer"},
    },
    "fortigate": {
        {OID: "1.3.6.1.4.1.12356.101.4.1.3.0", Name: "fgSysCpuUsage", Type: "gauge"},
        {OID: "1.3.6.1.4.1.12356.101.4.1.4.0", Name: "fgSysMemUsage", Type: "gauge"},
        {OID: "1.3.6.1.4.1.12356.101.4.1.8.0", Name: "fgSysSesCount", Type: "gauge"},
        {OID: "1.3.6.1.4.1.12356.101.4.5.3.0", Name: "fgVdNumber", Type: "integer"},
    },
    "cisco": {
        {OID: "1.3.6.1.4.1.9.9.109.1.1.1.1.3", Name: "cpmCPUTotal5sec", Type: "gauge"},
        {OID: "1.3.6.1.4.1.9.9.109.1.1.1.1.4", Name: "cpmCPUTotal1min", Type: "gauge"},
        {OID: "1.3.6.1.4.1.9.9.48.1.1.1.5", Name: "ciscoMemoryPoolUsed", Type: "gauge"},
        {OID: "1.3.6.1.4.1.9.9.48.1.1.1.6", Name: "ciscoMemoryPoolFree", Type: "gauge"},
    },
    "synology": {
        {OID: "1.3.6.1.4.1.6574.1.2.0", Name: "systemStatus", Type: "integer"},
        {OID: "1.3.6.1.4.1.6574.1.5.1.0", Name: "cpuFanStatus", Type: "integer"},
        {OID: "1.3.6.1.4.1.6574.2.1.1.5", Name: "raidStatus", Type: "integer"},
        {OID: "1.3.6.1.4.1.6574.3.1.1.2", Name: "diskModel", Type: "string"},
    },
}
```

#### 6. HTTP(S) Check
```go
type HTTPCheckConfig struct {
    URL             string
    Method          string
    Headers         map[string]string
    Body            string
    ExpectedStatus  []int
    ExpectedBody    string        // Regex
    Timeout         time.Duration
    FollowRedirects bool
    ValidateSSL     bool
}

type HTTPCheckResult struct {
    StatusCode      int
    ResponseTime    time.Duration
    BodyMatch       bool
    Headers         map[string]string
    Size            int64
    RedirectChain   []string
    SSLInfo         *SSLCheckResult
}
```

#### 7. DNS Check
```go
type DNSCheckConfig struct {
    Domain      string
    RecordType  string        // A, AAAA, MX, TXT, CNAME, NS, SOA
    Nameserver  string        // Optionnel
    Expected    []string      // Valeurs attendues
}

type DNSCheckResult struct {
    Records     []DNSRecord
    QueryTime   time.Duration
    Authoritative bool
    Match       bool
}
```

## Structure du Projet

```
secumon-probe/
├── cmd/
│   └── probe/
│       └── main.go
├── internal/
│   ├── config/
│   │   ├── config.go         # Configuration locale
│   │   └── remote.go         # Sync config depuis collector
│   ├── scanner/
│   │   ├── connectivity.go   # Ping, TCP connect
│   │   ├── traceroute.go
│   │   ├── portscan.go
│   │   ├── ssl.go
│   │   ├── snmp.go
│   │   ├── http.go
│   │   └── dns.go
│   ├── scheduler/
│   │   ├── scheduler.go      # Orchestration des scans
│   │   └── cron.go           # Parsing expressions cron
│   ├── wireguard/
│   │   ├── manager.go        # Gestion tunnel WG
│   │   └── provision.go      # Auto-provisioning
│   ├── reporter/
│   │   ├── grpc.go           # Envoi résultats
│   │   └── buffer.go         # Buffer offline
│   └── alerts/
│       └── detector.go       # Détection changements
├── pkg/
│   └── types/
│       └── results.go        # Types partagés
├── proto/
│   └── probe.proto           # Définitions gRPC
├── configs/
│   └── probe.example.yaml
├── scripts/
│   ├── build.sh              # Cross-compilation
│   └── install.sh            # Script d'installation
├── Dockerfile
├── go.mod
└── README.md
```

## Configuration

### Fichier de Configuration Local
```yaml
# /etc/secumon/probe.yaml
probe:
  id: ""                      # Auto-généré si vide
  name: "probe-internet-01"
  location: "OVH-GRA"
  tags:
    - "internet"
    - "primary"

collector:
  endpoints:
    - "collector-1.secumon.internal:9443"
    - "collector-2.secumon.internal:9443"
  
wireguard:
  enabled: true
  config_path: "/etc/wireguard/secumon.conf"
  provisioning_url: "https://api.secumon.io/wg/provision"
  
auth:
  token_path: "/etc/secumon/token"
  
logging:
  level: "info"
  format: "json"
  output: "/var/log/secumon/probe.log"

scanner:
  default_timeout: 30s
  max_concurrent: 50
  
buffer:
  enabled: true
  path: "/var/lib/secumon/buffer"
  max_size: "100MB"
```

### Configuration des Cibles (via Collector)
```yaml
# Reçu depuis le collector
targets:
  - id: "target-001"
    name: "Firewall Client A"
    address: "203.0.113.1"
    tests:
      - type: "icmp"
        interval: "1m"
        timeout: "5s"
      - type: "port_scan"
        interval: "1h"
        ports: [22, 80, 443, 8443]
        alert_on_change: true
      - type: "ssl"
        interval: "6h"
        port: 443
        alert_days_before_expiry: 30
      - type: "snmp"
        interval: "5m"
        version: "v3"
        preset: "fortigate"
        credentials_ref: "snmp-client-a"
        
  - id: "target-002"
    name: "Web Server Client B"
    address: "www.clientb.com"
    tests:
      - type: "http"
        interval: "1m"
        url: "https://www.clientb.com/health"
        expected_status: [200]
        expected_body: "OK"
      - type: "ssl"
        interval: "6h"
```

## Protocol Buffers

```protobuf
// proto/probe.proto
syntax = "proto3";

package secumon.probe.v1;

option go_package = "github.com/secuaas/secumon-probe/proto";

import "google/protobuf/timestamp.proto";

// Service pour communication Probe -> Collector
service ProbeService {
  // Enregistrement et heartbeat
  rpc Register(RegisterRequest) returns (RegisterResponse);
  rpc Heartbeat(HeartbeatRequest) returns (HeartbeatResponse);
  
  // Récupération de la configuration
  rpc GetConfig(GetConfigRequest) returns (stream ConfigUpdate);
  
  // Envoi des résultats
  rpc SendResults(stream ScanResult) returns (SendResultsResponse);
  
  // Récupération des credentials (chiffrés)
  rpc GetCredentials(GetCredentialsRequest) returns (GetCredentialsResponse);
}

message RegisterRequest {
  string probe_id = 1;
  string name = 2;
  string version = 3;
  string location = 4;
  repeated string tags = 5;
  SystemInfo system_info = 6;
}

message SystemInfo {
  string os = 1;
  string arch = 2;
  string hostname = 3;
  repeated string ip_addresses = 4;
}

message RegisterResponse {
  string probe_id = 1;
  WireGuardConfig wireguard = 2;
  bytes config_signature = 3;
}

message WireGuardConfig {
  string private_key = 1;
  string public_key = 2;
  string endpoint = 3;
  string allowed_ips = 4;
  string address = 5;
  int32 persistent_keepalive = 6;
}

message ScanResult {
  string target_id = 1;
  string test_type = 2;
  google.protobuf.Timestamp timestamp = 3;
  bool success = 4;
  string error = 5;
  oneof result {
    ConnectivityResult connectivity = 10;
    TracerouteResult traceroute = 11;
    PortScanResult port_scan = 12;
    SSLResult ssl = 13;
    SNMPResult snmp = 14;
    HTTPResult http = 15;
    DNSResult dns = 16;
  }
  repeated Alert alerts = 20;
}

message Alert {
  string type = 1;           // "change", "threshold", "anomaly"
  string severity = 2;       // "critical", "warning", "info"
  string message = 3;
  string previous_value = 4;
  string current_value = 5;
}

message ConnectivityResult {
  double latency_min_ms = 1;
  double latency_max_ms = 2;
  double latency_avg_ms = 3;
  double jitter_ms = 4;
  double packet_loss_percent = 5;
  bool reachable = 6;
  int32 ttl = 7;
}

message PortScanResult {
  repeated PortInfo open_ports = 1;
  repeated int32 closed_ports = 2;
  repeated int32 filtered_ports = 3;
  int64 scan_duration_ms = 4;
}

message PortInfo {
  int32 port = 1;
  string protocol = 2;
  string state = 3;
  string service = 4;
  string banner = 5;
  string version = 6;
}

message SSLResult {
  bool valid = 1;
  string issuer = 2;
  string subject = 3;
  google.protobuf.Timestamp not_before = 4;
  google.protobuf.Timestamp not_after = 5;
  int32 days_until_expiry = 6;
  repeated string protocols = 7;
  repeated string cipher_suites = 8;
  string grade = 9;
  repeated string vulnerabilities = 10;
}

message SNMPResult {
  repeated SNMPValue values = 1;
  int64 query_time_ms = 2;
}

message SNMPValue {
  string oid = 1;
  string name = 2;
  string type = 3;
  string value = 4;
}

message HTTPResult {
  int32 status_code = 1;
  int64 response_time_ms = 2;
  int64 body_size = 3;
  bool body_match = 4;
  map<string, string> headers = 5;
  repeated string redirect_chain = 6;
}

message DNSResult {
  repeated DNSRecord records = 1;
  int64 query_time_ms = 2;
  bool authoritative = 3;
  bool match = 4;
}

message DNSRecord {
  string type = 1;
  string value = 2;
  int32 ttl = 3;
}
```

## Implémentation Clé

### Scheduler (Orchestration des Scans)
```go
// internal/scheduler/scheduler.go
package scheduler

import (
    "context"
    "sync"
    "time"
    
    "github.com/secuaas/secumon-probe/internal/scanner"
)

type Scheduler struct {
    targets    map[string]*Target
    scanners   *scanner.Pool
    reporter   Reporter
    mu         sync.RWMutex
    ctx        context.Context
    cancel     context.CancelFunc
}

type Target struct {
    ID       string
    Tests    []TestConfig
    timers   map[string]*time.Timer
}

type TestConfig struct {
    Type     string
    Interval time.Duration
    Config   interface{}
}

func (s *Scheduler) Start() {
    s.ctx, s.cancel = context.WithCancel(context.Background())
    
    for _, target := range s.targets {
        for _, test := range target.Tests {
            s.scheduleTest(target.ID, test)
        }
    }
}

func (s *Scheduler) scheduleTest(targetID string, test TestConfig) {
    ticker := time.NewTicker(test.Interval)
    
    go func() {
        // Exécution immédiate
        s.executeTest(targetID, test)
        
        for {
            select {
            case <-ticker.C:
                s.executeTest(targetID, test)
            case <-s.ctx.Done():
                ticker.Stop()
                return
            }
        }
    }()
}

func (s *Scheduler) executeTest(targetID string, test TestConfig) {
    result, err := s.scanners.Execute(test.Type, test.Config)
    
    scanResult := &ScanResult{
        TargetID:  targetID,
        TestType:  test.Type,
        Timestamp: time.Now(),
        Success:   err == nil,
    }
    
    if err != nil {
        scanResult.Error = err.Error()
    } else {
        scanResult.Result = result
        scanResult.Alerts = s.detectChanges(targetID, test.Type, result)
    }
    
    s.reporter.Send(scanResult)
}
```

### Détection de Changements
```go
// internal/alerts/detector.go
package alerts

import (
    "sync"
)

type ChangeDetector struct {
    history map[string]interface{}
    mu      sync.RWMutex
}

func (d *ChangeDetector) Detect(targetID, testType string, current interface{}) []Alert {
    key := targetID + ":" + testType
    
    d.mu.RLock()
    previous, exists := d.history[key]
    d.mu.RUnlock()
    
    if !exists {
        d.mu.Lock()
        d.history[key] = current
        d.mu.Unlock()
        return nil
    }
    
    alerts := d.compare(testType, previous, current)
    
    d.mu.Lock()
    d.history[key] = current
    d.mu.Unlock()
    
    return alerts
}

func (d *ChangeDetector) compare(testType string, prev, curr interface{}) []Alert {
    switch testType {
    case "port_scan":
        return d.comparePortScan(prev.(*PortScanResult), curr.(*PortScanResult))
    case "ssl":
        return d.compareSSL(prev.(*SSLResult), curr.(*SSLResult))
    // ... autres types
    }
    return nil
}

func (d *ChangeDetector) comparePortScan(prev, curr *PortScanResult) []Alert {
    var alerts []Alert
    
    prevPorts := make(map[int]bool)
    for _, p := range prev.OpenPorts {
        prevPorts[p.Port] = true
    }
    
    currPorts := make(map[int]bool)
    for _, p := range curr.OpenPorts {
        currPorts[p.Port] = true
    }
    
    // Nouveaux ports ouverts
    for _, p := range curr.OpenPorts {
        if !prevPorts[p.Port] {
            alerts = append(alerts, Alert{
                Type:     "change",
                Severity: "warning",
                Message:  fmt.Sprintf("New open port detected: %d/%s (%s)", p.Port, p.Protocol, p.Service),
            })
        }
    }
    
    // Ports fermés
    for _, p := range prev.OpenPorts {
        if !currPorts[p.Port] {
            alerts = append(alerts, Alert{
                Type:     "change",
                Severity: "info",
                Message:  fmt.Sprintf("Port closed: %d/%s", p.Port, p.Protocol),
            })
        }
    }
    
    return alerts
}
```

## Build et Déploiement

### Script de Build Multi-Plateforme
```bash
#!/bin/bash
# scripts/build.sh

VERSION=$(git describe --tags --always)
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS="-s -w -X main.Version=${VERSION} -X main.BuildTime=${BUILD_TIME}"

platforms=(
    "linux/amd64"
    "linux/arm64"
    "linux/arm"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
)

for platform in "${platforms[@]}"; do
    GOOS=${platform%/*}
    GOARCH=${platform#*/}
    output="dist/secumon-probe-${GOOS}-${GOARCH}"
    
    if [ "$GOOS" = "windows" ]; then
        output="${output}.exe"
    fi
    
    echo "Building for ${GOOS}/${GOARCH}..."
    CGO_ENABLED=0 GOOS=$GOOS GOARCH=$GOARCH go build \
        -ldflags="${LDFLAGS}" \
        -o "$output" \
        ./cmd/probe/
        
    # Compression UPX pour réduire la taille
    if command -v upx &> /dev/null && [ "$GOOS" != "darwin" ]; then
        upx --best "$output"
    fi
done
```

### Dockerfile
```dockerfile
FROM golang:1.22-alpine AS builder

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /secumon-probe ./cmd/probe/

FROM alpine:3.19

RUN apk add --no-cache ca-certificates wireguard-tools

COPY --from=builder /secumon-probe /usr/local/bin/

ENTRYPOINT ["/usr/local/bin/secumon-probe"]
```

## Tests

### Tests Unitaires
```go
// internal/scanner/ssl_test.go
package scanner

import (
    "testing"
    "time"
)

func TestSSLCheck(t *testing.T) {
    tests := []struct {
        name     string
        target   string
        port     int
        wantErr  bool
        minGrade string
    }{
        {"google.com", "google.com", 443, false, "A"},
        {"expired.badssl.com", "expired.badssl.com", 443, false, "F"},
        {"self-signed.badssl.com", "self-signed.badssl.com", 443, false, "F"},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result, err := CheckSSL(SSLCheckConfig{
                Target: tt.target,
                Port:   tt.port,
            })
            
            if (err != nil) != tt.wantErr {
                t.Errorf("CheckSSL() error = %v, wantErr %v", err, tt.wantErr)
            }
            
            // Vérifications...
        })
    }
}
```

## Commandes CLI

```bash
# Installation
curl -sSL https://install.secumon.io/probe | sudo bash

# Configuration initiale
secumon-probe init --collector https://collector.secumon.io --token <TOKEN>

# Démarrage en mode service
secumon-probe service install
secumon-probe service start

# Test manuel
secumon-probe scan --target 192.168.1.1 --type ping
secumon-probe scan --target example.com --type ssl
secumon-probe scan --target 10.0.0.1 --type snmp --preset fortigate

# Debug
secumon-probe debug --verbose
```

## Métriques Internes

La probe expose ses propres métriques pour le monitoring:

```go
type ProbeMetrics struct {
    ScansTotal       int64         // Total de scans effectués
    ScansSuccess     int64         // Scans réussis
    ScansError       int64         // Scans en erreur
    ScanDuration     Histogram     // Distribution des durées
    BufferSize       int64         // Taille du buffer offline
    LastHeartbeat    time.Time     // Dernier heartbeat
    ConfigVersion    string        // Version de la config
}
```
