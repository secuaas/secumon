# SecuMon-Web - Interface Web

## Objectif

Application web SPA pour la gestion et visualisation de la plateforme de monitoring. Authentification MFA standard + SSO JumpCloud pour super admin.

## Stack Technologique

- **Framework**: Vue 3 + Composition API
- **Build**: Vite
- **UI**: Tailwind CSS + HeadlessUI
- **Charts**: Apache ECharts
- **State**: Pinia
- **Router**: Vue Router
- **HTTP**: Axios
- **Forms**: VeeValidate + Zod
- **Dates**: Day.js
- **Icons**: Heroicons

## Structure du Projet

```
secumon-web/
├── public/
│   ├── favicon.ico
│   └── logo.svg
├── src/
│   ├── main.ts
│   ├── App.vue
│   ├── assets/
│   │   └── styles/
│   │       └── main.css
│   ├── components/
│   │   ├── common/
│   │   │   ├── AppHeader.vue
│   │   │   ├── AppSidebar.vue
│   │   │   ├── AppBreadcrumb.vue
│   │   │   ├── DataTable.vue
│   │   │   ├── Modal.vue
│   │   │   ├── Toast.vue
│   │   │   ├── LoadingSpinner.vue
│   │   │   ├── StatusBadge.vue
│   │   │   └── SearchInput.vue
│   │   ├── charts/
│   │   │   ├── TimeSeriesChart.vue
│   │   │   ├── GaugeChart.vue
│   │   │   ├── PieChart.vue
│   │   │   └── HeatmapChart.vue
│   │   ├── agents/
│   │   │   ├── AgentCard.vue
│   │   │   ├── AgentStatusIndicator.vue
│   │   │   ├── AgentMetricsOverview.vue
│   │   │   └── AgentInstallModal.vue
│   │   ├── probes/
│   │   │   ├── ProbeCard.vue
│   │   │   └── ProbeConfigModal.vue
│   │   ├── targets/
│   │   │   ├── TargetCard.vue
│   │   │   ├── TargetTestConfig.vue
│   │   │   └── SNMPCredentialForm.vue
│   │   ├── alerts/
│   │   │   ├── AlertCard.vue
│   │   │   ├── AlertRuleForm.vue
│   │   │   └── NotificationChannelForm.vue
│   │   └── dashboard/
│   │       ├── StatsCard.vue
│   │       ├── AlertsWidget.vue
│   │       ├── AgentsMapWidget.vue
│   │       └── MetricsOverviewWidget.vue
│   ├── views/
│   │   ├── auth/
│   │   │   ├── LoginView.vue
│   │   │   ├── MFASetupView.vue
│   │   │   └── SSOCallbackView.vue
│   │   ├── dashboard/
│   │   │   └── DashboardView.vue
│   │   ├── agents/
│   │   │   ├── AgentsListView.vue
│   │   │   └── AgentDetailView.vue
│   │   ├── probes/
│   │   │   ├── ProbesListView.vue
│   │   │   └── ProbeDetailView.vue
│   │   ├── targets/
│   │   │   ├── TargetsListView.vue
│   │   │   └── TargetDetailView.vue
│   │   ├── alerts/
│   │   │   ├── AlertsView.vue
│   │   │   └── AlertRulesView.vue
│   │   ├── logs/
│   │   │   └── LogsExplorerView.vue
│   │   ├── reports/
│   │   │   └── ReportsView.vue
│   │   ├── settings/
│   │   │   ├── SettingsView.vue
│   │   │   ├── ProfileView.vue
│   │   │   ├── NotificationsView.vue
│   │   │   └── APIKeysView.vue
│   │   └── admin/
│   │       ├── TenantsView.vue
│   │       └── UsersView.vue
│   ├── stores/
│   │   ├── auth.ts
│   │   ├── agents.ts
│   │   ├── probes.ts
│   │   ├── targets.ts
│   │   ├── alerts.ts
│   │   ├── metrics.ts
│   │   └── notifications.ts
│   ├── composables/
│   │   ├── useAuth.ts
│   │   ├── useApi.ts
│   │   ├── useMetrics.ts
│   │   ├── useWebSocket.ts
│   │   └── useNotifications.ts
│   ├── services/
│   │   ├── api.ts
│   │   ├── auth.ts
│   │   ├── agents.ts
│   │   ├── probes.ts
│   │   ├── targets.ts
│   │   ├── alerts.ts
│   │   ├── metrics.ts
│   │   └── logs.ts
│   ├── router/
│   │   ├── index.ts
│   │   └── guards.ts
│   ├── types/
│   │   ├── api.ts
│   │   ├── agent.ts
│   │   ├── probe.ts
│   │   ├── target.ts
│   │   ├── alert.ts
│   │   └── user.ts
│   └── utils/
│       ├── formatters.ts
│       ├── validators.ts
│       └── constants.ts
├── index.html
├── vite.config.ts
├── tailwind.config.js
├── postcss.config.js
├── tsconfig.json
├── package.json
└── README.md
```

## Configuration

### vite.config.ts
```typescript
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  build: {
    target: 'esnext',
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia', 'axios'],
          charts: ['echarts'],
        },
      },
    },
  },
})
```

### tailwind.config.js
```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#f0f9ff',
          100: '#e0f2fe',
          500: '#0ea5e9',
          600: '#0284c7',
          700: '#0369a1',
        },
        danger: {
          50: '#fef2f2',
          500: '#ef4444',
          600: '#dc2626',
        },
        warning: {
          50: '#fffbeb',
          500: '#f59e0b',
          600: '#d97706',
        },
        success: {
          50: '#f0fdf4',
          500: '#22c55e',
          600: '#16a34a',
        },
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}
```

## Types

### types/agent.ts
```typescript
export interface Agent {
  id: string
  tenantId: string
  name: string
  hostname: string
  ipAddresses: string[]
  os: string
  osVersion: string
  arch: string
  version: string
  status: AgentStatus
  lastSeen: string
  config: AgentConfig
  tags: string[]
  createdAt: string
  updatedAt: string
}

export type AgentStatus = 'online' | 'offline' | 'warning' | 'pending'

export interface AgentConfig {
  metricsInterval: number
  logsEnabled: boolean
  probeEnabled: boolean
}

export interface AgentMetrics {
  timestamp: string
  cpu: CPUMetrics
  memory: MemoryMetrics
  disks: DiskMetrics[]
  networks: NetworkMetrics[]
}

export interface CPUMetrics {
  usagePercent: number
  userPercent: number
  systemPercent: number
  iowaitPercent: number
  loadAvg1: number
  loadAvg5: number
  loadAvg15: number
}

export interface MemoryMetrics {
  totalBytes: number
  usedBytes: number
  availableBytes: number
  cachedBytes: number
  swapUsed: number
  usagePercent: number
}

export interface DiskMetrics {
  device: string
  mountpoint: string
  fsType: string
  totalBytes: number
  usedBytes: number
  usagePercent: number
  readBytes: number
  writeBytes: number
}

export interface NetworkMetrics {
  interface: string
  status: string
  rxBytes: number
  txBytes: number
  rxErrors: number
  txErrors: number
}
```

### types/target.ts
```typescript
export interface Target {
  id: string
  tenantId: string
  name: string
  address: string
  type: TargetType
  enabled: boolean
  probeIds: string[]
  tests: TestConfig[]
  tags: string[]
  createdAt: string
  updatedAt: string
}

export type TargetType = 'server' | 'network' | 'website' | 'service'

export interface TestConfig {
  type: TestType
  interval: string
  timeout?: string
  enabled: boolean
  config: Record<string, any>
  alertOnChange?: boolean
}

export type TestType = 
  | 'icmp'
  | 'tcp'
  | 'udp'
  | 'port_scan'
  | 'ssl'
  | 'http'
  | 'dns'
  | 'snmp'
  | 'traceroute'

export interface ScanResult {
  timestamp: string
  probeId: string
  targetId: string
  testType: TestType
  success: boolean
  error?: string
  latencyMs?: number
  packetLoss?: number
  resultData: Record<string, any>
  alerts: Alert[]
}
```

### types/alert.ts
```typescript
export interface Alert {
  id: string
  tenantId: string
  ruleId?: string
  agentId?: string
  probeId?: string
  targetId?: string
  severity: AlertSeverity
  status: AlertStatus
  message: string
  value?: number
  threshold?: number
  firedAt: string
  resolvedAt?: string
  acknowledgedAt?: string
  acknowledgedBy?: string
  labels: Record<string, string>
  annotations: Record<string, string>
}

export type AlertSeverity = 'critical' | 'warning' | 'info'
export type AlertStatus = 'firing' | 'resolved' | 'acknowledged'

export interface AlertRule {
  id: string
  tenantId: string
  name: string
  description?: string
  enabled: boolean
  severity: AlertSeverity
  type: AlertRuleType
  conditions: AlertCondition[]
  forDuration?: string
  labels: Record<string, string>
  annotations: Record<string, string>
  notificationChannels: string[]
  createdAt: string
  updatedAt: string
}

export type AlertRuleType = 'threshold' | 'change' | 'anomaly' | 'absence'

export interface AlertCondition {
  metric: string
  operator: 'gt' | 'lt' | 'eq' | 'ne' | 'gte' | 'lte' | 'change'
  value: number
  labels?: Record<string, string>
}

export interface NotificationChannel {
  id: string
  tenantId: string
  name: string
  type: NotificationType
  config: Record<string, any>
  enabled: boolean
  createdAt: string
}

export type NotificationType = 'email' | 'slack' | 'webhook' | 'sms' | 'teams'
```

## Services API

### services/api.ts
```typescript
import axios, { AxiosInstance, AxiosError } from 'axios'
import { useAuthStore } from '@/stores/auth'
import router from '@/router'

const api: AxiosInstance = axios.create({
  baseURL: '/api/v1',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const authStore = useAuthStore()
    
    if (authStore.token) {
      config.headers.Authorization = `Bearer ${authStore.token}`
    }
    
    if (authStore.tenantId) {
      config.headers['X-Tenant-ID'] = authStore.tenantId
    }
    
    return config
  },
  (error) => Promise.reject(error)
)

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const authStore = useAuthStore()
    
    if (error.response?.status === 401) {
      // Try to refresh token
      try {
        await authStore.refreshToken()
        // Retry the request
        return api.request(error.config!)
      } catch {
        authStore.logout()
        router.push('/login')
      }
    }
    
    return Promise.reject(error)
  }
)

export default api
```

### services/agents.ts
```typescript
import api from './api'
import type { Agent, AgentMetrics } from '@/types/agent'

export const agentsService = {
  async list(params?: {
    status?: string
    tags?: string[]
    search?: string
    page?: number
    limit?: number
  }) {
    const { data } = await api.get<{
      agents: Agent[]
      total: number
      page: number
      limit: number
    }>('/agents', { params })
    return data
  },

  async get(id: string) {
    const { data } = await api.get<Agent>(`/agents/${id}`)
    return data
  },

  async create(agent: Partial<Agent>) {
    const { data } = await api.post<Agent>('/agents', agent)
    return data
  },

  async update(id: string, agent: Partial<Agent>) {
    const { data } = await api.put<Agent>(`/agents/${id}`, agent)
    return data
  },

  async delete(id: string) {
    await api.delete(`/agents/${id}`)
  },

  async getMetrics(
    id: string,
    params: {
      from: string
      to: string
      resolution?: string
    }
  ) {
    const { data } = await api.get<AgentMetrics[]>(
      `/agents/${id}/metrics`,
      { params }
    )
    return data
  },

  async getLogs(
    id: string,
    params: {
      from?: string
      to?: string
      level?: string
      search?: string
      limit?: number
    }
  ) {
    const { data } = await api.get(`/agents/${id}/logs`, { params })
    return data
  },

  async getInstallScript(os: string, arch: string) {
    const { data } = await api.get<{ script: string }>(
      '/agents/install-script',
      { params: { os, arch } }
    )
    return data.script
  },
}
```

### services/metrics.ts
```typescript
import api from './api'

export interface MetricQuery {
  metric: string
  agentId?: string
  targetId?: string
  labels?: Record<string, string>
  from: string
  to: string
  resolution?: string
  aggregation?: 'avg' | 'max' | 'min' | 'sum'
}

export interface MetricDataPoint {
  timestamp: string
  value: number
}

export interface MetricSeries {
  metric: string
  labels: Record<string, string>
  dataPoints: MetricDataPoint[]
}

export const metricsService = {
  async query(queries: MetricQuery[]) {
    const { data } = await api.post<MetricSeries[]>('/metrics/query', {
      queries,
    })
    return data
  },

  async getAgentOverview(agentId: string, timeRange: string) {
    const { data } = await api.get(`/metrics/agent/${agentId}/overview`, {
      params: { range: timeRange },
    })
    return data
  },

  async getTargetLatency(targetId: string, timeRange: string) {
    const { data } = await api.get(`/metrics/target/${targetId}/latency`, {
      params: { range: timeRange },
    })
    return data
  },
}
```

## Stores (Pinia)

### stores/auth.ts
```typescript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '@/services/api'
import router from '@/router'

interface User {
  id: string
  email: string
  name: string
  role: string
  tenantId: string
  tenantName: string
  mfaEnabled: boolean
}

interface LoginCredentials {
  email: string
  password: string
}

interface MFAVerification {
  code: string
  tempToken: string
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const token = ref<string | null>(localStorage.getItem('token'))
  const refreshTokenValue = ref<string | null>(localStorage.getItem('refreshToken'))
  const mfaPending = ref(false)
  const mfaTempToken = ref<string | null>(null)

  const isAuthenticated = computed(() => !!token.value && !!user.value)
  const isSuperAdmin = computed(() => user.value?.role === 'super_admin')
  const tenantId = computed(() => user.value?.tenantId)

  async function login(credentials: LoginCredentials) {
    const { data } = await api.post('/auth/login', credentials)

    if (data.requireMFA) {
      mfaPending.value = true
      mfaTempToken.value = data.tempToken
      return { requireMFA: true }
    }

    setTokens(data.token, data.refreshToken)
    user.value = data.user
    return { requireMFA: false }
  }

  async function verifyMFA(verification: MFAVerification) {
    const { data } = await api.post('/auth/mfa/verify', verification)
    
    setTokens(data.token, data.refreshToken)
    user.value = data.user
    mfaPending.value = false
    mfaTempToken.value = null
  }

  async function loginWithJumpCloud() {
    // Redirect to JumpCloud SSO
    window.location.href = '/api/v1/auth/sso/jumpcloud'
  }

  async function handleSSOCallback(code: string) {
    const { data } = await api.get('/auth/sso/jumpcloud/callback', {
      params: { code },
    })
    
    setTokens(data.token, data.refreshToken)
    user.value = data.user
  }

  async function refreshToken() {
    if (!refreshTokenValue.value) {
      throw new Error('No refresh token')
    }

    const { data } = await api.post('/auth/refresh', {
      refreshToken: refreshTokenValue.value,
    })

    setTokens(data.token, data.refreshToken)
  }

  async function fetchUser() {
    const { data } = await api.get('/auth/me')
    user.value = data
  }

  function setTokens(accessToken: string, refresh: string) {
    token.value = accessToken
    refreshTokenValue.value = refresh
    localStorage.setItem('token', accessToken)
    localStorage.setItem('refreshToken', refresh)
  }

  function logout() {
    token.value = null
    refreshTokenValue.value = null
    user.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('refreshToken')
    router.push('/login')
  }

  return {
    user,
    token,
    isAuthenticated,
    isSuperAdmin,
    tenantId,
    mfaPending,
    mfaTempToken,
    login,
    verifyMFA,
    loginWithJumpCloud,
    handleSSOCallback,
    refreshToken,
    fetchUser,
    logout,
  }
})
```

### stores/agents.ts
```typescript
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { agentsService } from '@/services/agents'
import type { Agent, AgentMetrics } from '@/types/agent'

export const useAgentsStore = defineStore('agents', () => {
  const agents = ref<Agent[]>([])
  const currentAgent = ref<Agent | null>(null)
  const currentMetrics = ref<AgentMetrics[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  const onlineAgents = computed(() => 
    agents.value.filter(a => a.status === 'online')
  )

  const offlineAgents = computed(() =>
    agents.value.filter(a => a.status === 'offline')
  )

  const agentsByStatus = computed(() => ({
    online: agents.value.filter(a => a.status === 'online').length,
    offline: agents.value.filter(a => a.status === 'offline').length,
    warning: agents.value.filter(a => a.status === 'warning').length,
    pending: agents.value.filter(a => a.status === 'pending').length,
  }))

  async function fetchAgents(params?: {
    status?: string
    tags?: string[]
    search?: string
  }) {
    loading.value = true
    error.value = null
    
    try {
      const response = await agentsService.list(params)
      agents.value = response.agents
    } catch (e: any) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function fetchAgent(id: string) {
    loading.value = true
    error.value = null
    
    try {
      currentAgent.value = await agentsService.get(id)
    } catch (e: any) {
      error.value = e.message
    } finally {
      loading.value = false
    }
  }

  async function fetchAgentMetrics(
    id: string,
    from: string,
    to: string,
    resolution?: string
  ) {
    try {
      currentMetrics.value = await agentsService.getMetrics(id, {
        from,
        to,
        resolution,
      })
    } catch (e: any) {
      error.value = e.message
    }
  }

  async function createAgent(agent: Partial<Agent>) {
    const newAgent = await agentsService.create(agent)
    agents.value.push(newAgent)
    return newAgent
  }

  async function updateAgent(id: string, updates: Partial<Agent>) {
    const updated = await agentsService.update(id, updates)
    const index = agents.value.findIndex(a => a.id === id)
    if (index !== -1) {
      agents.value[index] = updated
    }
    if (currentAgent.value?.id === id) {
      currentAgent.value = updated
    }
    return updated
  }

  async function deleteAgent(id: string) {
    await agentsService.delete(id)
    agents.value = agents.value.filter(a => a.id !== id)
    if (currentAgent.value?.id === id) {
      currentAgent.value = null
    }
  }

  return {
    agents,
    currentAgent,
    currentMetrics,
    loading,
    error,
    onlineAgents,
    offlineAgents,
    agentsByStatus,
    fetchAgents,
    fetchAgent,
    fetchAgentMetrics,
    createAgent,
    updateAgent,
    deleteAgent,
  }
})
```

## Composables

### composables/useMetrics.ts
```typescript
import { ref, computed, watch } from 'vue'
import { metricsService, type MetricQuery, type MetricSeries } from '@/services/metrics'

export function useMetrics() {
  const data = ref<MetricSeries[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function query(queries: MetricQuery[]) {
    loading.value = true
    error.value = null
    
    try {
      data.value = await metricsService.query(queries)
    } catch (e: any) {
      error.value = e.message
      data.value = []
    } finally {
      loading.value = false
    }
  }

  function getSeriesForChart(metricName: string) {
    const series = data.value.find(s => s.metric === metricName)
    if (!series) return { labels: [], data: [] }
    
    return {
      labels: series.dataPoints.map(p => p.timestamp),
      data: series.dataPoints.map(p => p.value),
    }
  }

  return {
    data,
    loading,
    error,
    query,
    getSeriesForChart,
  }
}
```

### composables/useWebSocket.ts
```typescript
import { ref, onMounted, onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'

interface WSMessage {
  type: string
  payload: any
}

export function useWebSocket() {
  const socket = ref<WebSocket | null>(null)
  const connected = ref(false)
  const messages = ref<WSMessage[]>([])
  const handlers = new Map<string, Set<(payload: any) => void>>()

  function connect() {
    const authStore = useAuthStore()
    const wsUrl = `${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}/api/v1/ws`
    
    socket.value = new WebSocket(`${wsUrl}?token=${authStore.token}`)
    
    socket.value.onopen = () => {
      connected.value = true
    }
    
    socket.value.onmessage = (event) => {
      const message: WSMessage = JSON.parse(event.data)
      messages.value.push(message)
      
      // Notify handlers
      const typeHandlers = handlers.get(message.type)
      if (typeHandlers) {
        typeHandlers.forEach(handler => handler(message.payload))
      }
    }
    
    socket.value.onclose = () => {
      connected.value = false
      // Reconnect after 5 seconds
      setTimeout(connect, 5000)
    }
    
    socket.value.onerror = (error) => {
      console.error('WebSocket error:', error)
    }
  }

  function subscribe(type: string, handler: (payload: any) => void) {
    if (!handlers.has(type)) {
      handlers.set(type, new Set())
    }
    handlers.get(type)!.add(handler)
    
    return () => {
      handlers.get(type)?.delete(handler)
    }
  }

  function send(type: string, payload: any) {
    if (socket.value?.readyState === WebSocket.OPEN) {
      socket.value.send(JSON.stringify({ type, payload }))
    }
  }

  function disconnect() {
    socket.value?.close()
  }

  onMounted(connect)
  onUnmounted(disconnect)

  return {
    connected,
    messages,
    subscribe,
    send,
    disconnect,
  }
}
```

## Components

### components/charts/TimeSeriesChart.vue
```vue
<template>
  <div ref="chartRef" :style="{ width: '100%', height: height }"></div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import * as echarts from 'echarts/core'
import { LineChart } from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  GridComponent,
  LegendComponent,
  DataZoomComponent,
} from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'

echarts.use([
  LineChart,
  TitleComponent,
  TooltipComponent,
  GridComponent,
  LegendComponent,
  DataZoomComponent,
  CanvasRenderer,
])

interface Props {
  title?: string
  series: {
    name: string
    data: [string, number][]
    color?: string
  }[]
  height?: string
  yAxisUnit?: string
  showDataZoom?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  height: '300px',
  showDataZoom: true,
})

const chartRef = ref<HTMLDivElement>()
let chart: echarts.ECharts | null = null

function initChart() {
  if (!chartRef.value) return
  
  chart = echarts.init(chartRef.value)
  
  const option: echarts.EChartsOption = {
    title: props.title ? { text: props.title, left: 'center' } : undefined,
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross',
      },
    },
    legend: {
      bottom: props.showDataZoom ? 40 : 10,
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: props.showDataZoom ? '15%' : '15%',
      containLabel: true,
    },
    xAxis: {
      type: 'time',
      boundaryGap: false,
    },
    yAxis: {
      type: 'value',
      axisLabel: {
        formatter: props.yAxisUnit ? `{value} ${props.yAxisUnit}` : '{value}',
      },
    },
    dataZoom: props.showDataZoom
      ? [
          {
            type: 'inside',
            start: 0,
            end: 100,
          },
          {
            start: 0,
            end: 100,
          },
        ]
      : undefined,
    series: props.series.map((s) => ({
      name: s.name,
      type: 'line',
      smooth: true,
      data: s.data,
      itemStyle: s.color ? { color: s.color } : undefined,
      areaStyle: {
        opacity: 0.1,
      },
    })),
  }
  
  chart.setOption(option)
}

function updateChart() {
  if (!chart) return
  
  chart.setOption({
    series: props.series.map((s) => ({
      name: s.name,
      data: s.data,
    })),
  })
}

function handleResize() {
  chart?.resize()
}

watch(() => props.series, updateChart, { deep: true })

onMounted(() => {
  initChart()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  chart?.dispose()
  window.removeEventListener('resize', handleResize)
})
</script>
```

### components/agents/AgentMetricsOverview.vue
```vue
<template>
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
    <!-- CPU Usage -->
    <div class="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-500 dark:text-gray-400">CPU</span>
        <StatusBadge :status="getCPUStatus(metrics?.cpu.usagePercent)" />
      </div>
      <div class="mt-2">
        <span class="text-2xl font-bold text-gray-900 dark:text-white">
          {{ formatPercent(metrics?.cpu.usagePercent) }}
        </span>
      </div>
      <div class="mt-2 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
        <div
          class="h-full transition-all duration-300"
          :class="getCPUBarColor(metrics?.cpu.usagePercent)"
          :style="{ width: `${metrics?.cpu.usagePercent || 0}%` }"
        ></div>
      </div>
      <div class="mt-2 text-xs text-gray-500 dark:text-gray-400">
        Load: {{ metrics?.cpu.loadAvg1.toFixed(2) }} / {{ metrics?.cpu.loadAvg5.toFixed(2) }} / {{ metrics?.cpu.loadAvg15.toFixed(2) }}
      </div>
    </div>

    <!-- Memory Usage -->
    <div class="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Memory</span>
        <StatusBadge :status="getMemoryStatus(metrics?.memory.usagePercent)" />
      </div>
      <div class="mt-2">
        <span class="text-2xl font-bold text-gray-900 dark:text-white">
          {{ formatPercent(metrics?.memory.usagePercent) }}
        </span>
        <span class="text-sm text-gray-500 dark:text-gray-400 ml-2">
          {{ formatBytes(metrics?.memory.usedBytes) }} / {{ formatBytes(metrics?.memory.totalBytes) }}
        </span>
      </div>
      <div class="mt-2 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
        <div
          class="h-full bg-blue-500 transition-all duration-300"
          :style="{ width: `${metrics?.memory.usagePercent || 0}%` }"
        ></div>
      </div>
    </div>

    <!-- Disk Usage (Root) -->
    <div class="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Disk (/)</span>
        <StatusBadge :status="getDiskStatus(rootDisk?.usagePercent)" />
      </div>
      <div class="mt-2">
        <span class="text-2xl font-bold text-gray-900 dark:text-white">
          {{ formatPercent(rootDisk?.usagePercent) }}
        </span>
        <span class="text-sm text-gray-500 dark:text-gray-400 ml-2">
          {{ formatBytes(rootDisk?.usedBytes) }} / {{ formatBytes(rootDisk?.totalBytes) }}
        </span>
      </div>
      <div class="mt-2 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
        <div
          class="h-full bg-purple-500 transition-all duration-300"
          :style="{ width: `${rootDisk?.usagePercent || 0}%` }"
        ></div>
      </div>
    </div>

    <!-- Network -->
    <div class="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
      <div class="flex items-center justify-between">
        <span class="text-sm font-medium text-gray-500 dark:text-gray-400">Network</span>
        <span class="text-xs text-gray-400">{{ primaryNetwork?.interface }}</span>
      </div>
      <div class="mt-2 flex justify-between">
        <div>
          <div class="text-xs text-gray-500 dark:text-gray-400">↓ RX</div>
          <div class="text-lg font-bold text-green-500">
            {{ formatBytesRate(primaryNetwork?.rxBytes) }}/s
          </div>
        </div>
        <div class="text-right">
          <div class="text-xs text-gray-500 dark:text-gray-400">↑ TX</div>
          <div class="text-lg font-bold text-blue-500">
            {{ formatBytesRate(primaryNetwork?.txBytes) }}/s
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import StatusBadge from '@/components/common/StatusBadge.vue'
import type { AgentMetrics } from '@/types/agent'

interface Props {
  metrics?: AgentMetrics
}

const props = defineProps<Props>()

const rootDisk = computed(() =>
  props.metrics?.disks.find(d => d.mountpoint === '/')
)

const primaryNetwork = computed(() =>
  props.metrics?.networks.find(n => n.interface.startsWith('eth') || n.interface.startsWith('ens'))
)

function formatPercent(value?: number): string {
  return value !== undefined ? `${value.toFixed(1)}%` : '-'
}

function formatBytes(bytes?: number): string {
  if (bytes === undefined) return '-'
  const units = ['B', 'KB', 'MB', 'GB', 'TB']
  let i = 0
  let value = bytes
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024
    i++
  }
  return `${value.toFixed(1)} ${units[i]}`
}

function formatBytesRate(bytes?: number): string {
  if (bytes === undefined) return '-'
  return formatBytes(bytes)
}

function getCPUStatus(value?: number): 'success' | 'warning' | 'danger' {
  if (value === undefined) return 'success'
  if (value >= 90) return 'danger'
  if (value >= 70) return 'warning'
  return 'success'
}

function getMemoryStatus(value?: number): 'success' | 'warning' | 'danger' {
  if (value === undefined) return 'success'
  if (value >= 90) return 'danger'
  if (value >= 80) return 'warning'
  return 'success'
}

function getDiskStatus(value?: number): 'success' | 'warning' | 'danger' {
  if (value === undefined) return 'success'
  if (value >= 90) return 'danger'
  if (value >= 80) return 'warning'
  return 'success'
}

function getCPUBarColor(value?: number): string {
  if (value === undefined) return 'bg-gray-400'
  if (value >= 90) return 'bg-red-500'
  if (value >= 70) return 'bg-yellow-500'
  return 'bg-green-500'
}
</script>
```

## Views

### views/auth/LoginView.vue
```vue
<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 py-12 px-4 sm:px-6 lg:px-8">
    <div class="max-w-md w-full space-y-8">
      <div>
        <img class="mx-auto h-12 w-auto" src="/logo.svg" alt="SecuMon">
        <h2 class="mt-6 text-center text-3xl font-extrabold text-gray-900 dark:text-white">
          Sign in to SecuMon
        </h2>
      </div>

      <!-- MFA Verification -->
      <form v-if="authStore.mfaPending" @submit.prevent="handleMFAVerify" class="mt-8 space-y-6">
        <div>
          <label for="mfa-code" class="sr-only">MFA Code</label>
          <input
            id="mfa-code"
            v-model="mfaCode"
            type="text"
            inputmode="numeric"
            pattern="[0-9]{6}"
            maxlength="6"
            required
            class="appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 placeholder-gray-500 dark:placeholder-gray-400 text-gray-900 dark:text-white dark:bg-gray-800 focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
            placeholder="Enter 6-digit code"
          >
        </div>
        <button
          type="submit"
          :disabled="loading"
          class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50"
        >
          Verify
        </button>
      </form>

      <!-- Login Form -->
      <form v-else @submit.prevent="handleLogin" class="mt-8 space-y-6">
        <div class="rounded-md shadow-sm -space-y-px">
          <div>
            <label for="email" class="sr-only">Email address</label>
            <input
              id="email"
              v-model="email"
              type="email"
              autocomplete="email"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 placeholder-gray-500 dark:placeholder-gray-400 text-gray-900 dark:text-white dark:bg-gray-800 rounded-t-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
              placeholder="Email address"
            >
          </div>
          <div>
            <label for="password" class="sr-only">Password</label>
            <input
              id="password"
              v-model="password"
              type="password"
              autocomplete="current-password"
              required
              class="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 placeholder-gray-500 dark:placeholder-gray-400 text-gray-900 dark:text-white dark:bg-gray-800 rounded-b-md focus:outline-none focus:ring-primary-500 focus:border-primary-500 sm:text-sm"
              placeholder="Password"
            >
          </div>
        </div>

        <div v-if="error" class="rounded-md bg-red-50 dark:bg-red-900/50 p-4">
          <p class="text-sm text-red-700 dark:text-red-200">{{ error }}</p>
        </div>

        <div>
          <button
            type="submit"
            :disabled="loading"
            class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50"
          >
            <LoadingSpinner v-if="loading" class="w-5 h-5 mr-2" />
            Sign in
          </button>
        </div>

        <div class="relative">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-gray-300 dark:border-gray-600"></div>
          </div>
          <div class="relative flex justify-center text-sm">
            <span class="px-2 bg-gray-50 dark:bg-gray-900 text-gray-500">Or continue with</span>
          </div>
        </div>

        <div>
          <button
            type="button"
            @click="handleJumpCloudSSO"
            class="w-full flex justify-center items-center py-2 px-4 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
          >
            <img src="/jumpcloud-logo.svg" class="w-5 h-5 mr-2" alt="">
            Sign in with JumpCloud
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import LoadingSpinner from '@/components/common/LoadingSpinner.vue'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const mfaCode = ref('')
const loading = ref(false)
const error = ref<string | null>(null)

async function handleLogin() {
  loading.value = true
  error.value = null

  try {
    const result = await authStore.login({ email: email.value, password: password.value })
    
    if (!result.requireMFA) {
      router.push('/dashboard')
    }
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Login failed'
  } finally {
    loading.value = false
  }
}

async function handleMFAVerify() {
  loading.value = true
  error.value = null

  try {
    await authStore.verifyMFA({
      code: mfaCode.value,
      tempToken: authStore.mfaTempToken!,
    })
    router.push('/dashboard')
  } catch (e: any) {
    error.value = e.response?.data?.error || 'Invalid code'
  } finally {
    loading.value = false
  }
}

function handleJumpCloudSSO() {
  authStore.loginWithJumpCloud()
}
</script>
```

### views/dashboard/DashboardView.vue
```vue
<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <h1 class="text-2xl font-semibold text-gray-900 dark:text-white">Dashboard</h1>
      <div class="flex items-center space-x-4">
        <select
          v-model="timeRange"
          class="rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-800 text-sm"
        >
          <option value="1h">Last 1 hour</option>
          <option value="6h">Last 6 hours</option>
          <option value="24h">Last 24 hours</option>
          <option value="7d">Last 7 days</option>
          <option value="30d">Last 30 days</option>
        </select>
        <button
          @click="refresh"
          class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 shadow-sm text-sm font-medium rounded-md text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700"
        >
          <RefreshIcon class="h-4 w-4 mr-2" />
          Refresh
        </button>
      </div>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <StatsCard
        title="Agents"
        :value="agentsStore.agentsByStatus.online"
        :total="agentsStore.agents.length"
        :trend="{ value: 5, direction: 'up' }"
        icon="ServerIcon"
        color="green"
      />
      <StatsCard
        title="Probes"
        :value="probesStore.activeProbes.length"
        :total="probesStore.probes.length"
        icon="SearchIcon"
        color="blue"
      />
      <StatsCard
        title="Active Alerts"
        :value="alertsStore.firingAlerts.length"
        icon="BellIcon"
        :color="alertsStore.firingAlerts.length > 0 ? 'red' : 'green'"
      />
      <StatsCard
        title="Targets"
        :value="targetsStore.enabledTargets.length"
        :total="targetsStore.targets.length"
        icon="GlobeIcon"
        color="purple"
      />
    </div>

    <!-- Alerts Widget -->
    <AlertsWidget v-if="alertsStore.firingAlerts.length > 0" :alerts="alertsStore.firingAlerts" />

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- System Metrics Overview -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">
          System Metrics Overview
        </h3>
        <TimeSeriesChart
          :series="systemMetricsSeries"
          height="300px"
          yAxisUnit="%"
        />
      </div>

      <!-- Scan Results -->
      <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white mb-4">
          Scan Success Rate
        </h3>
        <TimeSeriesChart
          :series="scanSuccessRateSeries"
          height="300px"
          yAxisUnit="%"
        />
      </div>
    </div>

    <!-- Agents Status Grid -->
    <div class="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="text-lg font-medium text-gray-900 dark:text-white">
          Agents Status
        </h3>
        <RouterLink to="/agents" class="text-sm text-primary-600 hover:text-primary-500">
          View all →
        </RouterLink>
      </div>
      <div class="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
        <AgentCard
          v-for="agent in agentsStore.agents.slice(0, 12)"
          :key="agent.id"
          :agent="agent"
          compact
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAgentsStore } from '@/stores/agents'
import { useProbesStore } from '@/stores/probes'
import { useTargetsStore } from '@/stores/targets'
import { useAlertsStore } from '@/stores/alerts'
import { useMetrics } from '@/composables/useMetrics'
import StatsCard from '@/components/dashboard/StatsCard.vue'
import AlertsWidget from '@/components/dashboard/AlertsWidget.vue'
import TimeSeriesChart from '@/components/charts/TimeSeriesChart.vue'
import AgentCard from '@/components/agents/AgentCard.vue'
import { RefreshIcon } from '@heroicons/vue/outline'

const agentsStore = useAgentsStore()
const probesStore = useProbesStore()
const targetsStore = useTargetsStore()
const alertsStore = useAlertsStore()
const { data: metricsData, query: queryMetrics } = useMetrics()

const timeRange = ref('24h')

const systemMetricsSeries = computed(() => [
  {
    name: 'Avg CPU',
    data: [], // Populated from metricsData
    color: '#10B981',
  },
  {
    name: 'Avg Memory',
    data: [],
    color: '#3B82F6',
  },
])

const scanSuccessRateSeries = computed(() => [
  {
    name: 'Success Rate',
    data: [],
    color: '#8B5CF6',
  },
])

async function refresh() {
  await Promise.all([
    agentsStore.fetchAgents(),
    probesStore.fetchProbes(),
    targetsStore.fetchTargets(),
    alertsStore.fetchAlerts({ status: 'firing' }),
    loadMetrics(),
  ])
}

async function loadMetrics() {
  await queryMetrics([
    {
      metric: 'system_cpu_usage_avg',
      from: `-${timeRange.value}`,
      to: 'now',
      aggregation: 'avg',
    },
    {
      metric: 'system_memory_usage_avg',
      from: `-${timeRange.value}`,
      to: 'now',
      aggregation: 'avg',
    },
  ])
}

onMounted(refresh)
</script>
```

## Router

### router/index.ts
```typescript
import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/auth/LoginView.vue'),
      meta: { public: true },
    },
    {
      path: '/auth/sso/callback',
      name: 'sso-callback',
      component: () => import('@/views/auth/SSOCallbackView.vue'),
      meta: { public: true },
    },
    {
      path: '/',
      redirect: '/dashboard',
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: () => import('@/views/dashboard/DashboardView.vue'),
    },
    {
      path: '/agents',
      name: 'agents',
      component: () => import('@/views/agents/AgentsListView.vue'),
    },
    {
      path: '/agents/:id',
      name: 'agent-detail',
      component: () => import('@/views/agents/AgentDetailView.vue'),
    },
    {
      path: '/probes',
      name: 'probes',
      component: () => import('@/views/probes/ProbesListView.vue'),
    },
    {
      path: '/probes/:id',
      name: 'probe-detail',
      component: () => import('@/views/probes/ProbeDetailView.vue'),
    },
    {
      path: '/targets',
      name: 'targets',
      component: () => import('@/views/targets/TargetsListView.vue'),
    },
    {
      path: '/targets/:id',
      name: 'target-detail',
      component: () => import('@/views/targets/TargetDetailView.vue'),
    },
    {
      path: '/alerts',
      name: 'alerts',
      component: () => import('@/views/alerts/AlertsView.vue'),
    },
    {
      path: '/alerts/rules',
      name: 'alert-rules',
      component: () => import('@/views/alerts/AlertRulesView.vue'),
    },
    {
      path: '/logs',
      name: 'logs',
      component: () => import('@/views/logs/LogsExplorerView.vue'),
    },
    {
      path: '/reports',
      name: 'reports',
      component: () => import('@/views/reports/ReportsView.vue'),
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('@/views/settings/SettingsView.vue'),
    },
    {
      path: '/admin/tenants',
      name: 'admin-tenants',
      component: () => import('@/views/admin/TenantsView.vue'),
      meta: { superAdmin: true },
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()

  // Public routes
  if (to.meta.public) {
    return next()
  }

  // Check authentication
  if (!authStore.isAuthenticated) {
    if (authStore.token) {
      try {
        await authStore.fetchUser()
      } catch {
        return next('/login')
      }
    } else {
      return next('/login')
    }
  }

  // Check super admin routes
  if (to.meta.superAdmin && !authStore.isSuperAdmin) {
    return next('/dashboard')
  }

  next()
})

export default router
```

## Déploiement

### Dockerfile
```dockerfile
# Build stage
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### nginx.conf
```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api {
        proxy_pass http://secumon-api:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # WebSocket
    location /api/v1/ws {
        proxy_pass http://secumon-api:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```
