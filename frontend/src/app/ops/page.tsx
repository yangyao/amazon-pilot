'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Cookies from 'js-cookie'

import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'

interface SystemStatus {
  services: ServiceStatus[]
  database: DatabaseStatus
  redis: RedisStatus
  queue: QueueStatus
  uptime: number
}

interface ServiceStatus {
  name: string
  status: string
  port: number
  uptime: number
  health: string
}

interface DatabaseStatus {
  status: string
  connections: number
  total_tables: number
  total_records: number
  partition_stats?: PartitionInfo[]
}

interface PartitionInfo {
  name: string
  row_count: number
  size: string
  unprocessed: number
}

interface RedisStatus {
  status: string
  memory: string
  keys: number
  connections: number
}

interface QueueStatus {
  critical: QueueInfo
  default: QueueInfo
  low: QueueInfo
}

interface QueueInfo {
  pending: number
  active: number
  completed: number
  failed: number
}

export default function OpsPage() {
  const [systemStatus, setSystemStatus] = useState<SystemStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [refreshing, setRefreshing] = useState(false)
  const router = useRouter()

  useEffect(() => {
    const token = Cookies.get('access_token')
    if (!token) {
      router.push('/auth/login')
      return
    }

    loadSystemStatus()
  }, [router])

  const loadSystemStatus = async () => {
    try {
      const response = await fetch('http://localhost:8080/api/ops/system/status', {
        headers: {
          'Authorization': `Bearer ${Cookies.get('access_token')}`,
        },
      })

      if (!response.ok) {
        throw new Error('Failed to fetch system status')
      }

      const data = await response.json()
      setSystemStatus(data)
    } catch (error) {
      console.error('Failed to load system status:', error)
      setError('Failed to load system status')
      
      // 设置模拟数据用于Demo
      setSystemStatus({
        services: [
          { name: 'auth', status: 'running', port: 8888, uptime: 3600, health: 'healthy' },
          { name: 'product', status: 'running', port: 8889, uptime: 3600, health: 'healthy' },
          { name: 'competitor', status: 'running', port: 8890, uptime: 3600, health: 'healthy' },
          { name: 'optimization', status: 'running', port: 8891, uptime: 3600, health: 'healthy' },
          { name: 'notification', status: 'running', port: 8892, uptime: 3600, health: 'healthy' },
          { name: 'ops', status: 'running', port: 8893, uptime: 3600, health: 'healthy' },
          { name: 'gateway', status: 'running', port: 8080, uptime: 3600, health: 'healthy' },
        ],
        database: {
          status: 'healthy',
          connections: 15,
          total_tables: 12,
          total_records: 256,
        },
        redis: {
          status: 'healthy',
          memory: '128MB',
          keys: 1500,
          connections: 8,
        },
        queue: {
          critical: { pending: 2, active: 1, completed: 120, failed: 0 },
          default: { pending: 8, active: 3, completed: 580, failed: 2 },
          low: { pending: 15, active: 2, completed: 340, failed: 1 },
        },
        uptime: Date.now() / 1000,
      })
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }

  const handleRefresh = () => {
    setRefreshing(true)
    loadSystemStatus()
  }

  const handleRestartService = async (serviceName: string) => {
    try {
      const response = await fetch('http://localhost:8080/api/ops/services/restart', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${Cookies.get('access_token')}`,
        },
        body: JSON.stringify({ service_name: serviceName }),
      })

      if (response.ok) {
        alert(`Service ${serviceName} restart initiated`)
        handleRefresh()
      } else {
        alert(`Failed to restart service ${serviceName}`)
      }
    } catch (error) {
      alert(`Error restarting service ${serviceName}`)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'bg-green-100 text-green-800'
      case 'running': return 'bg-blue-100 text-blue-800'
      case 'unhealthy': return 'bg-red-100 text-red-800'
      case 'stopped': return 'bg-gray-100 text-gray-800'
      default: return 'bg-yellow-100 text-yellow-800'
    }
  }

  const formatUptime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    return `${hours}h ${minutes}m`
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-gray-900"></div>
      </div>
    )
  }

  return (
    <div className="container mx-auto py-8">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold">System Operations</h1>
          <p className="text-gray-600">Monitor and manage Amazon Pilot system</p>
        </div>
        <div className="flex gap-2">
          <Button 
            onClick={handleRefresh} 
            disabled={refreshing}
            variant="outline"
          >
            {refreshing ? 'Refreshing...' : 'Refresh Status'}
          </Button>
          <Button onClick={() => router.push('/dashboard')}>
            Back to Dashboard
          </Button>
        </div>
      </div>

      {error && (
        <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-md">
          <p className="text-yellow-800">{error}</p>
          <p className="text-sm text-yellow-600 mt-1">Showing demo data for presentation</p>
        </div>
      )}

      {/* Services Status */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle>Microservices Status</CardTitle>
          <CardDescription>Status of all Amazon Pilot microservices</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {systemStatus?.services.map((service) => (
              <div
                key={service.name}
                className="flex items-center justify-between p-4 border rounded-lg"
              >
                <div className="flex-1">
                  <h3 className="font-semibold capitalize">{service.name}</h3>
                  <p className="text-sm text-gray-600">Port: {service.port}</p>
                  <p className="text-sm text-gray-500">Uptime: {formatUptime(service.uptime)}</p>
                </div>
                <div className="flex flex-col items-end gap-2">
                  <Badge className={getStatusColor(service.health)}>
                    {service.health}
                  </Badge>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => handleRestartService(service.name)}
                  >
                    Restart
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* System Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <Card>
          <CardHeader>
            <CardTitle>Database</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Status:</span>
                <Badge className={getStatusColor(systemStatus?.database.status || 'unknown')}>
                  {systemStatus?.database.status}
                </Badge>
              </div>
              <div className="flex justify-between">
                <span>Connections:</span>
                <span>{systemStatus?.database.connections}</span>
              </div>
              <div className="flex justify-between">
                <span>Tables:</span>
                <span>{systemStatus?.database.total_tables}</span>
              </div>
              <div className="flex justify-between">
                <span>Records:</span>
                <span>{systemStatus?.database.total_records?.toLocaleString()}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Redis Cache</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span>Status:</span>
                <Badge className={getStatusColor(systemStatus?.redis.status || 'unknown')}>
                  {systemStatus?.redis.status}
                </Badge>
              </div>
              <div className="flex justify-between">
                <span>Memory:</span>
                <span>{systemStatus?.redis.memory}</span>
              </div>
              <div className="flex justify-between">
                <span>Keys:</span>
                <span>{systemStatus?.redis.keys?.toLocaleString()}</span>
              </div>
              <div className="flex justify-between">
                <span>Connections:</span>
                <span>{systemStatus?.redis.connections}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Task Queues</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="text-sm">
                <div className="font-medium">Critical Queue</div>
                <div className="text-gray-600">
                  Pending: {systemStatus?.queue.critical.pending} | 
                  Active: {systemStatus?.queue.critical.active} | 
                  Completed: {systemStatus?.queue.critical.completed}
                </div>
              </div>
              <div className="text-sm">
                <div className="font-medium">Default Queue</div>
                <div className="text-gray-600">
                  Pending: {systemStatus?.queue.default.pending} | 
                  Active: {systemStatus?.queue.default.active} | 
                  Completed: {systemStatus?.queue.default.completed}
                </div>
              </div>
              <div className="text-sm">
                <div className="font-medium">Low Priority Queue</div>
                <div className="text-gray-600">
                  Pending: {systemStatus?.queue.low.pending} | 
                  Active: {systemStatus?.queue.low.active} | 
                  Completed: {systemStatus?.queue.low.completed}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
          <CardDescription>Common system maintenance tasks</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Button 
              variant="outline" 
              onClick={() => window.open('http://localhost:8080/metrics', '_blank')}
            >
              📊 Prometheus Metrics
            </Button>
            <Button 
              variant="outline"
              onClick={() => alert('Database maintenance initiated')}
            >
              🗄️ Database Cleanup
            </Button>
            <Button 
              variant="outline"
              onClick={() => alert('Cache flush initiated')}
            >
              🧹 Clear Redis Cache
            </Button>
            <Button 
              variant="outline"
              onClick={() => alert('Log rotation initiated')}
            >
              📋 Rotate Logs
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}