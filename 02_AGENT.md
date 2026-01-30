# SecuMon-Agent - Agent Serveur Léger

## Objectif

Binaire Go ultra-léger déployé sur les serveurs à monitorer. Collecte les métriques système, logs, et peut optionnellement fonctionner comme sonde de scan. Communication sécurisée via WireGuard auto-provisionné.

## Spécifications Techniques

### Caractéristiques Cibles
- **Langage**: Go 1.22+
- **Taille binaire**: < 10MB (après UPX)
- **RAM**: < 30MB en fonctionnement nominal
- **CPU**: < 1% en moyenne
- **Réseau**: < 1MB/heure (métriques compressées)
- **Plateformes**: Linux (amd64, arm64, arm), Windows Server, FreeBSD

### Modes de Fonctionnement
1. **Agent Only**: Monitoring système uniquement
2. **Agent + Probe**: Monitoring + scans réseau
3. **Minimal**: Métriques essentielles uniquement (ultra-léger)

## Collecte de Données

### 1. Métriques Système

#### CPU
```go
type CPUMetrics struct {
    Timestamp    time.Time
    UsagePercent float64           // Usage total
    UserPercent  float64           // User space
    SystemPercent float64          // Kernel
    IOWaitPercent float64          // I/O wait
    IdlePercent  float64
    LoadAvg1     float64           // Load average 1min
    LoadAvg5     float64           // Load average 5min
    LoadAvg15    float64           // Load average 15min
    CoreCount    int
    PerCore      []CoreMetrics     // Optionnel, par core
}

type CoreMetrics struct {
    CoreID       int
    UsagePercent float64
    Frequency    float64           // MHz
    Temperature  float64           // Celsius (si disponible)
}
```

#### Mémoire
```go
type MemoryMetrics struct {
    Timestamp     time.Time
    TotalBytes    uint64
    UsedBytes     uint64
    FreeBytes     uint64
    AvailableBytes uint64
    CachedBytes   uint64
    BuffersBytes  uint64
    SwapTotal     uint64
    SwapUsed      uint64
    SwapFree      uint64
    UsagePercent  float64
}
```

#### Disques
```go
type DiskMetrics struct {
    Timestamp    time.Time
    Filesystems  []FilesystemMetrics
    IOStats      []DiskIOMetrics
}

type FilesystemMetrics struct {
    Device       string
    Mountpoint   string
    FSType       string
    TotalBytes   uint64
    UsedBytes    uint64
    FreeBytes    uint64
    UsagePercent float64
    InodesTotal  uint64
    InodesUsed   uint64
    InodesFree   uint64
}

type DiskIOMetrics struct {
    Device       string
    ReadBytes    uint64            // Total depuis boot
    WriteBytes   uint64
    ReadOps      uint64
    WriteOps     uint64
    ReadLatency  float64           // ms moyenne
    WriteLatency float64
    IOInProgress int
    IOTime       uint64            // ms passé en I/O
}
```

#### Réseau
```go
type NetworkMetrics struct {
    Timestamp   time.Time
    Interfaces  []InterfaceMetrics
    Connections ConnectionStats
}

type InterfaceMetrics struct {
    Name        string
    MAC         string
    IPAddresses []string
    Status      string            // up, down
    Speed       int64             // Mbps
    RxBytes     uint64
    TxBytes     uint64
    RxPackets   uint64
    TxPackets   uint64
    RxErrors    uint64
    TxErrors    uint64
    RxDropped   uint64
    TxDropped   uint64
}

type ConnectionStats struct {
    TCPEstablished int
    TCPTimeWait    int
    TCPCloseWait   int
    TCPListen      int
    UDPOpen        int
}
```

### 2. Informations Système

#### OS et Hardware
```go
type SystemInfo struct {
    Hostname      string
    OS            string            // "linux", "windows", "freebsd"
    OSVersion     string            // "Ubuntu 22.04"
    KernelVersion string
    Architecture  string
    Uptime        time.Duration
    BootTime      time.Time
    Virtualization string           // "kvm", "vmware", "physical"
    CloudProvider string            // "ovh", "aws", "gcp"
    
    // Hardware
    CPUModel      string
    CPUCores      int
    CPUThreads    int
    RAMTotal      uint64
    
    // Identifiers
    MachineID     string
    ProductUUID   string
}
```

#### Applications Installées
```go
type InstalledPackage struct {
    Name        string
    Version     string
    InstallDate time.Time
    Source      string            // "apt", "yum", "snap", "chocolatey"
    Size        int64
}

type InstalledSoftware struct {
    Packages     []InstalledPackage
    LastUpdated  time.Time
    UpdatesAvail int               // Nombre de mises à jour disponibles
}
```

#### Services et Processus
```go
type Service struct {
    Name        string
    DisplayName string
    Status      string            // "running", "stopped", "failed"
    StartType   string            // "auto", "manual", "disabled"
    PID         int
    Memory      uint64
    CPU         float64
}

type Process struct {
    PID         int
    PPID        int
    Name        string
    Command     string
    User        string
    Status      string
    StartTime   time.Time
    CPUPercent  float64
    MemoryRSS   uint64
    MemoryVMS   uint64
    Threads     int
    OpenFiles   int
    Connections int
}
```

#### Ports Ouverts
```go
type OpenPort struct {
    Protocol    string            // "tcp", "udp"
    LocalAddr   string
    LocalPort   int
    RemoteAddr  string
    RemotePort  int
    State       string
    PID         int
    ProcessName string
}
```

### 3. Collecte de Logs

#### Configuration des Sources
```go
type LogSource struct {
    ID          string
    Name        string
    Type        string            // "file", "journald", "eventlog", "docker"
    Path        string            // Pour type "file"
    Unit        string            // Pour journald
    Container   string            // Pour docker
    Filters     []LogFilter
    Multiline   *MultilineConfig
    Parser      string            // "json", "syslog", "apache", "nginx", "custom"
    CustomRegex string            // Pour parser custom
}

type LogFilter struct {
    Field     string
    Operator  string              // "contains", "regex", "equals", "level_gte"
    Value     string
    Action    string              // "include", "exclude"
}

type MultilineConfig struct {
    Pattern     string            // Regex pour début de ligne
    Negate      bool
    MaxLines    int
    MaxTimeout  time.Duration
}
```

#### Structure des Logs
```go
type LogEntry struct {
    Timestamp   time.Time
    Source      string
    Level       string            // "debug", "info", "warn", "error", "fatal"
    Message     string
    Fields      map[string]string // Champs parsés
    Raw         string            // Message brut (optionnel)
    Hostname    string
    AgentID     string
}
```

#### Sources Préconfigurées
```yaml
log_presets:
  linux_system:
    - name: "syslog"
      type: "file"
      path: "/var/log/syslog"
      parser: "syslog"
    - name: "auth"
      type: "file"
      path: "/var/log/auth.log"
      parser: "syslog"
    - name: "kernel"
      type: "journald"
      unit: "kernel"
      
  nginx:
    - name: "nginx_access"
      type: "file"
      path: "/var/log/nginx/access.log"
      parser: "nginx_combined"
    - name: "nginx_error"
      type: "file"
      path: "/var/log/nginx/error.log"
      parser: "nginx_error"
      
  apache:
    - name: "apache_access"
      type: "file"
      path: "/var/log/apache2/access.log"
      parser: "apache_combined"
    - name: "apache_error"
      type: "file"
      path: "/var/log/apache2/error.log"
      
  docker:
    - name: "docker_containers"
      type: "docker"
      container: "*"
      parser: "json"
      
  windows_system:
    - name: "windows_system"
      type: "eventlog"
      path: "System"
    - name: "windows_security"
      type: "eventlog"
      path: "Security"
    - name: "windows_application"
      type: "eventlog"
      path: "Application"
```

## Structure du Projet

```
secumon-agent/
├── cmd/
│   └── agent/
│       └── main.go
├── internal/
│   ├── config/
│   │   ├── config.go
│   │   └── remote.go
│   ├── collector/
│   │   ├── collector.go      # Orchestration collecte
│   │   ├── cpu.go
│   │   ├── memory.go
│   │   ├── disk.go
│   │   ├── network.go
│   │   ├── process.go
│   │   ├── service.go
│   │   ├── ports.go
│   │   └── packages.go
│   ├── logs/
│   │   ├── tailer.go         # Lecture fichiers logs
│   │   ├── journald.go       # Linux journald
│   │   ├── eventlog.go       # Windows Event Log
│   │   ├── docker.go         # Docker logs
│   │   └── parser/
│   │       ├── syslog.go
│   │       ├── nginx.go
│   │       ├── apache.go
│   │       ├── json.go
│   │       └── custom.go
│   ├── probe/                # Mode sonde (optionnel)
│   │   └── scanner.go
│   ├── wireguard/
│   │   ├── manager.go
│   │   └── provision.go
│   ├── reporter/
│   │   ├── grpc.go
│   │   ├── batch.go          # Batching des métriques
│   │   └── compress.go       # Compression LZ4
│   └── selfmon/
│       └── metrics.go        # Auto-monitoring de l'agent
├── pkg/
│   ├── types/
│   │   └── metrics.go
│   └── sysinfo/
│       ├── linux.go
│       ├── windows.go
│       └── darwin.go
├── proto/
│   └── agent.proto
├── configs/
│   └── agent.example.yaml
├── scripts/
│   ├── build.sh
│   ├── install.sh
│   └── uninstall.sh
├── init/
│   ├── secumon-agent.service    # systemd
│   └── secumon-agent.xml        # Windows Service
├── Dockerfile
├── go.mod
└── README.md
```

## Configuration

### Fichier de Configuration
```yaml
# /etc/secumon/agent.yaml
agent:
  id: ""                          # Auto-généré si vide
  name: "server-web-01"
  tags:
    - "production"
    - "web"
    - "client-a"
  mode: "full"                    # "full", "minimal", "probe"

collector:
  endpoints:
    - "collector-1.secumon.internal:9443"
  failover:
    - "collector-2.secumon.internal:9443"

wireguard:
  enabled: true
  config_path: "/etc/wireguard/secumon.conf"
  auto_provision: true

auth:
  token_path: "/etc/secumon/token"

# Collecte des métriques
metrics:
  enabled: true
  interval: 60s                   # Intervalle de collecte
  
  cpu:
    enabled: true
    per_core: false               # Métriques par core
    
  memory:
    enabled: true
    
  disk:
    enabled: true
    include_mounts:
      - "/"
      - "/home"
      - "/var"
    exclude_fs_types:
      - "tmpfs"
      - "devtmpfs"
    io_stats: true
    
  network:
    enabled: true
    include_interfaces:
      - "eth*"
      - "ens*"
      - "enp*"
    exclude_interfaces:
      - "lo"
      - "docker*"
      - "veth*"
    connection_stats: true
    
  processes:
    enabled: true
    top_n: 10                     # Top N processus par CPU/MEM
    track_specific:
      - "nginx"
      - "mysql"
      - "postgresql"
      
  services:
    enabled: true
    track:
      - "nginx"
      - "mysql"
      - "docker"
      - "ssh"
      
  ports:
    enabled: true
    listen_only: true             # Seulement les ports en écoute
    
  packages:
    enabled: true
    interval: 24h                 # Scan moins fréquent
    check_updates: true

# Collecte des logs
logs:
  enabled: true
  presets:
    - "linux_system"
    - "nginx"
  custom:
    - name: "app_logs"
      type: "file"
      path: "/var/log/myapp/*.log"
      parser: "json"
      multiline:
        pattern: "^\\d{4}-\\d{2}-\\d{2}"
        max_lines: 100
  buffer:
    max_size: "50MB"
    flush_interval: 5s
  filters:
    - field: "level"
      operator: "level_gte"
      value: "info"
      action: "include"

# Mode Probe (optionnel)
probe:
  enabled: false
  # Voir configuration probe

# Auto-monitoring
self_monitoring:
  enabled: true
  report_interval: 5m

# Logging
logging:
  level: "info"
  format: "json"
  output: "/var/log/secumon/agent.log"
  max_size: "10MB"
  max_backups: 3

# Buffer offline
buffer:
  enabled: true
  path: "/var/lib/secumon/buffer"
  max_size: "200MB"
  max_age: 24h
```

## Protocol Buffers

```protobuf
// proto/agent.proto
syntax = "proto3";

package secumon.agent.v1;

option go_package = "github.com/secuaas/secumon-agent/proto";

import "google/protobuf/timestamp.proto";

service AgentService {
  // Enregistrement et heartbeat
  rpc Register(RegisterRequest) returns (RegisterResponse);
  rpc Heartbeat(HeartbeatRequest) returns (HeartbeatResponse);
  
  // Configuration
  rpc GetConfig(GetConfigRequest) returns (stream ConfigUpdate);
  
  // Envoi des données
  rpc SendMetrics(stream MetricsBatch) returns (SendResponse);
  rpc SendLogs(stream LogBatch) returns (SendResponse);
  rpc SendInventory(InventoryReport) returns (SendResponse);
  
  // Commandes (depuis collector)
  rpc ExecuteCommand(CommandRequest) returns (CommandResponse);
}

message MetricsBatch {
  string agent_id = 1;
  google.protobuf.Timestamp timestamp = 2;
  bytes compressed_data = 3;       // LZ4 compressed
  string compression = 4;          // "lz4", "zstd", "none"
  int32 metrics_count = 5;
}

message SystemMetrics {
  CPUMetrics cpu = 1;
  MemoryMetrics memory = 2;
  repeated DiskMetrics disks = 3;
  repeated NetworkMetrics networks = 4;
  repeated ProcessMetrics top_processes = 5;
  repeated ServiceStatus services = 6;
  repeated OpenPort open_ports = 7;
}

message CPUMetrics {
  double usage_percent = 1;
  double user_percent = 2;
  double system_percent = 3;
  double iowait_percent = 4;
  double load_avg_1 = 5;
  double load_avg_5 = 6;
  double load_avg_15 = 7;
}

message MemoryMetrics {
  uint64 total_bytes = 1;
  uint64 used_bytes = 2;
  uint64 available_bytes = 3;
  uint64 cached_bytes = 4;
  uint64 swap_total = 5;
  uint64 swap_used = 6;
  double usage_percent = 7;
}

message DiskMetrics {
  string device = 1;
  string mountpoint = 2;
  string fs_type = 3;
  uint64 total_bytes = 4;
  uint64 used_bytes = 5;
  double usage_percent = 6;
  uint64 read_bytes = 7;
  uint64 write_bytes = 8;
  double read_latency_ms = 9;
  double write_latency_ms = 10;
}

message NetworkMetrics {
  string interface = 1;
  string status = 2;
  uint64 rx_bytes = 3;
  uint64 tx_bytes = 4;
  uint64 rx_errors = 5;
  uint64 tx_errors = 6;
}

message ProcessMetrics {
  int32 pid = 1;
  string name = 2;
  string user = 3;
  double cpu_percent = 4;
  uint64 memory_rss = 5;
  int32 threads = 6;
}

message ServiceStatus {
  string name = 1;
  string status = 2;
  int32 pid = 3;
}

message OpenPort {
  string protocol = 1;
  int32 port = 2;
  string address = 3;
  int32 pid = 4;
  string process_name = 5;
}

message LogBatch {
  string agent_id = 1;
  repeated LogEntry entries = 2;
  bytes compressed_data = 3;
  string compression = 4;
}

message LogEntry {
  google.protobuf.Timestamp timestamp = 1;
  string source = 2;
  string level = 3;
  string message = 4;
  map<string, string> fields = 5;
}

message InventoryReport {
  string agent_id = 1;
  google.protobuf.Timestamp timestamp = 2;
  SystemInfo system_info = 3;
  repeated InstalledPackage packages = 4;
  int32 updates_available = 5;
}

message SystemInfo {
  string hostname = 1;
  string os = 2;
  string os_version = 3;
  string kernel = 4;
  string arch = 5;
  int64 uptime_seconds = 6;
  string cpu_model = 7;
  int32 cpu_cores = 8;
  uint64 ram_total = 9;
  string virtualization = 10;
  string cloud_provider = 11;
  string machine_id = 12;
}

message InstalledPackage {
  string name = 1;
  string version = 2;
  string source = 3;
}
```

## Implémentation Clé

### Collecteur Principal
```go
// internal/collector/collector.go
package collector

import (
    "context"
    "sync"
    "time"
)

type Collector struct {
    config     *Config
    cpu        *CPUCollector
    memory     *MemoryCollector
    disk       *DiskCollector
    network    *NetworkCollector
    process    *ProcessCollector
    service    *ServiceCollector
    ports      *PortCollector
    
    metrics    chan *SystemMetrics
    ctx        context.Context
    cancel     context.CancelFunc
}

func NewCollector(cfg *Config) *Collector {
    return &Collector{
        config:  cfg,
        cpu:     NewCPUCollector(cfg.CPU),
        memory:  NewMemoryCollector(cfg.Memory),
        disk:    NewDiskCollector(cfg.Disk),
        network: NewNetworkCollector(cfg.Network),
        process: NewProcessCollector(cfg.Process),
        service: NewServiceCollector(cfg.Service),
        ports:   NewPortCollector(cfg.Ports),
        metrics: make(chan *SystemMetrics, 100),
    }
}

func (c *Collector) Start() {
    c.ctx, c.cancel = context.WithCancel(context.Background())
    
    ticker := time.NewTicker(c.config.Interval)
    defer ticker.Stop()
    
    // Collecte initiale
    c.collect()
    
    for {
        select {
        case <-ticker.C:
            c.collect()
        case <-c.ctx.Done():
            return
        }
    }
}

func (c *Collector) collect() {
    var wg sync.WaitGroup
    metrics := &SystemMetrics{}
    var mu sync.Mutex
    
    collectors := []struct {
        enabled bool
        fn      func() interface{}
        assign  func(interface{})
    }{
        {c.config.CPU.Enabled, func() interface{} { return c.cpu.Collect() },
         func(v interface{}) { metrics.CPU = v.(*CPUMetrics) }},
        {c.config.Memory.Enabled, func() interface{} { return c.memory.Collect() },
         func(v interface{}) { metrics.Memory = v.(*MemoryMetrics) }},
        // ... autres collecteurs
    }
    
    for _, col := range collectors {
        if col.enabled {
            wg.Add(1)
            go func(c struct{ enabled bool; fn func() interface{}; assign func(interface{}) }) {
                defer wg.Done()
                result := c.fn()
                mu.Lock()
                c.assign(result)
                mu.Unlock()
            }(col)
        }
    }
    
    wg.Wait()
    
    select {
    case c.metrics <- metrics:
    default:
        // Channel plein, on drop les métriques les plus anciennes
    }
}

func (c *Collector) Metrics() <-chan *SystemMetrics {
    return c.metrics
}
```

### Collecteur CPU (Linux)
```go
// internal/collector/cpu_linux.go
package collector

import (
    "bufio"
    "os"
    "strconv"
    "strings"
    "time"
)

type CPUCollector struct {
    config     CPUConfig
    prevStats  cpuStats
    prevTime   time.Time
}

type cpuStats struct {
    user    uint64
    nice    uint64
    system  uint64
    idle    uint64
    iowait  uint64
    irq     uint64
    softirq uint64
}

func (c *CPUCollector) Collect() *CPUMetrics {
    stats := c.readProcStat()
    now := time.Now()
    
    if c.prevTime.IsZero() {
        c.prevStats = stats
        c.prevTime = now
        return nil
    }
    
    elapsed := now.Sub(c.prevTime).Seconds()
    
    total := float64(stats.total() - c.prevStats.total())
    
    metrics := &CPUMetrics{
        Timestamp:     now,
        UserPercent:   float64(stats.user-c.prevStats.user) / total * 100,
        SystemPercent: float64(stats.system-c.prevStats.system) / total * 100,
        IOWaitPercent: float64(stats.iowait-c.prevStats.iowait) / total * 100,
        IdlePercent:   float64(stats.idle-c.prevStats.idle) / total * 100,
    }
    metrics.UsagePercent = 100 - metrics.IdlePercent
    
    // Load average
    metrics.LoadAvg1, metrics.LoadAvg5, metrics.LoadAvg15 = c.readLoadAvg()
    
    c.prevStats = stats
    c.prevTime = now
    
    return metrics
}

func (c *CPUCollector) readProcStat() cpuStats {
    file, _ := os.Open("/proc/stat")
    defer file.Close()
    
    scanner := bufio.NewScanner(file)
    scanner.Scan()
    line := scanner.Text()
    
    fields := strings.Fields(line)
    // cpu user nice system idle iowait irq softirq
    
    return cpuStats{
        user:    parseUint(fields[1]),
        nice:    parseUint(fields[2]),
        system:  parseUint(fields[3]),
        idle:    parseUint(fields[4]),
        iowait:  parseUint(fields[5]),
        irq:     parseUint(fields[6]),
        softirq: parseUint(fields[7]),
    }
}

func (c *cpuStats) total() uint64 {
    return c.user + c.nice + c.system + c.idle + c.iowait + c.irq + c.softirq
}
```

### Tailer de Logs
```go
// internal/logs/tailer.go
package logs

import (
    "bufio"
    "context"
    "io"
    "os"
    "path/filepath"
    "time"
    
    "github.com/fsnotify/fsnotify"
)

type Tailer struct {
    sources  []*LogSource
    entries  chan *LogEntry
    parsers  map[string]Parser
    ctx      context.Context
    cancel   context.CancelFunc
}

func (t *Tailer) Start() {
    t.ctx, t.cancel = context.WithCancel(context.Background())
    
    for _, source := range t.sources {
        switch source.Type {
        case "file":
            go t.tailFile(source)
        case "journald":
            go t.tailJournald(source)
        case "docker":
            go t.tailDocker(source)
        }
    }
}

func (t *Tailer) tailFile(source *LogSource) {
    // Glob pour les patterns comme /var/log/nginx/*.log
    matches, _ := filepath.Glob(source.Path)
    
    for _, path := range matches {
        go t.watchFile(source, path)
    }
    
    // Watch pour nouveaux fichiers
    watcher, _ := fsnotify.NewWatcher()
    defer watcher.Close()
    
    dir := filepath.Dir(source.Path)
    watcher.Add(dir)
    
    for {
        select {
        case event := <-watcher.Events:
            if event.Op&fsnotify.Create == fsnotify.Create {
                if matched, _ := filepath.Match(source.Path, event.Name); matched {
                    go t.watchFile(source, event.Name)
                }
            }
        case <-t.ctx.Done():
            return
        }
    }
}

func (t *Tailer) watchFile(source *LogSource, path string) {
    file, err := os.Open(path)
    if err != nil {
        return
    }
    defer file.Close()
    
    // Seek to end
    file.Seek(0, io.SeekEnd)
    
    parser := t.parsers[source.Parser]
    reader := bufio.NewReader(file)
    
    watcher, _ := fsnotify.NewWatcher()
    defer watcher.Close()
    watcher.Add(path)
    
    var multilineBuffer []string
    
    for {
        select {
        case <-watcher.Events:
            for {
                line, err := reader.ReadString('\n')
                if err != nil {
                    break
                }
                
                // Gestion multiline
                if source.Multiline != nil {
                    // ... logique multiline
                }
                
                entry, err := parser.Parse(line)
                if err != nil {
                    continue
                }
                
                entry.Source = source.Name
                
                // Appliquer les filtres
                if t.shouldInclude(source.Filters, entry) {
                    t.entries <- entry
                }
            }
        case <-t.ctx.Done():
            return
        }
    }
}
```

### Compression et Batching
```go
// internal/reporter/batch.go
package reporter

import (
    "bytes"
    "time"
    
    "github.com/pierrec/lz4/v4"
    "google.golang.org/protobuf/proto"
)

type Batcher struct {
    metrics     []*SystemMetrics
    logs        []*LogEntry
    maxSize     int
    maxWait     time.Duration
    sendMetrics func([]byte) error
    sendLogs    func([]byte) error
}

func (b *Batcher) AddMetrics(m *SystemMetrics) {
    b.metrics = append(b.metrics, m)
    
    if len(b.metrics) >= b.maxSize {
        b.flushMetrics()
    }
}

func (b *Batcher) flushMetrics() error {
    if len(b.metrics) == 0 {
        return nil
    }
    
    batch := &MetricsBatch{
        AgentID:      agentID,
        Timestamp:    time.Now(),
        MetricsCount: int32(len(b.metrics)),
    }
    
    // Sérialiser
    data, _ := proto.Marshal(&SystemMetricsList{Metrics: b.metrics})
    
    // Compresser avec LZ4
    compressed := make([]byte, lz4.CompressBlockBound(len(data)))
    n, _ := lz4.CompressBlock(data, compressed, nil)
    
    batch.CompressedData = compressed[:n]
    batch.Compression = "lz4"
    
    b.metrics = b.metrics[:0]
    
    return b.sendMetrics(batch)
}
```

## Installation et Déploiement

### Script d'Installation Linux
```bash
#!/bin/bash
# scripts/install.sh

set -e

INSTALL_DIR="/opt/secumon"
CONFIG_DIR="/etc/secumon"
LOG_DIR="/var/log/secumon"
DATA_DIR="/var/lib/secumon"

# Détection architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
esac

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# Téléchargement
DOWNLOAD_URL="https://releases.secumon.io/agent/latest/secumon-agent-${OS}-${ARCH}"

echo "Installing SecuMon Agent..."

# Création des répertoires
mkdir -p $INSTALL_DIR $CONFIG_DIR $LOG_DIR $DATA_DIR

# Téléchargement du binaire
curl -sSL $DOWNLOAD_URL -o $INSTALL_DIR/secumon-agent
chmod +x $INSTALL_DIR/secumon-agent

# Lien symbolique
ln -sf $INSTALL_DIR/secumon-agent /usr/local/bin/secumon-agent

# Configuration par défaut
if [ ! -f $CONFIG_DIR/agent.yaml ]; then
    $INSTALL_DIR/secumon-agent config init > $CONFIG_DIR/agent.yaml
fi

# Service systemd
cat > /etc/systemd/system/secumon-agent.service << 'EOF'
[Unit]
Description=SecuMon Agent
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/opt/secumon/secumon-agent run --config /etc/secumon/agent.yaml
Restart=always
RestartSec=10
User=root
LimitNOFILE=65535

# Security hardening
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/secumon /var/lib/secumon /etc/wireguard

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable secumon-agent

echo "SecuMon Agent installed successfully!"
echo "Configure with: nano /etc/secumon/agent.yaml"
echo "Start with: systemctl start secumon-agent"
```

### Commandes CLI
```bash
# Installation
curl -sSL https://install.secumon.io/agent | sudo bash

# Configuration initiale
secumon-agent init --collector https://collector.secumon.io --token <TOKEN>

# Gestion du service
secumon-agent service install
secumon-agent service start
secumon-agent service status

# Test de connexion
secumon-agent test connection

# Afficher les métriques locales
secumon-agent debug metrics
secumon-agent debug logs --source syslog --tail 100

# Mode interactif (debug)
secumon-agent run --debug --no-send

# Mise à jour
secumon-agent update
```

## Auto-Monitoring

L'agent expose ses propres métriques:

```go
type AgentMetrics struct {
    Version         string
    Uptime          time.Duration
    MemoryUsed      uint64
    CPUPercent      float64
    MetricsSent     int64
    MetricsDropped  int64
    LogsSent        int64
    LogsDropped     int64
    BufferSize      int64
    LastSendTime    time.Time
    LastSendError   string
    WireGuardStatus string
    ConfigVersion   string
}
```
