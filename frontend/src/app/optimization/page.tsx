'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Cookies from 'js-cookie'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'

const createOptimizationSchema = z.object({
  title: z.string().min(1, 'Title is required'),
  description: z.string().optional(),
  product_id: z.string().min(1, 'Product ID is required'),
  optimization_type: z.enum(['listing', 'pricing', 'keywords', 'images']).default('listing'),
  priority: z.enum(['low', 'medium', 'high']).default('medium'),
})

type CreateOptimizationForm = z.infer<typeof createOptimizationSchema>

interface OptimizationTask {
  id: string
  title: string
  description?: string
  product_asin: string
  optimization_type: string
  priority: string
  status: string
  ai_suggestions?: string[]
  impact_score?: number
  estimated_hours?: number
  created_at: string
  updated_at?: string
}

interface OptimizationStats {
  total_tasks: number
  pending_tasks: number
  completed_tasks: number
  average_impact_score: number
}

export default function OptimizationPage() {
  const [optimizationTasks, setOptimizationTasks] = useState<OptimizationTask[]>([])
  const [stats, setStats] = useState<OptimizationStats>({
    total_tasks: 0,
    pending_tasks: 0,
    completed_tasks: 0,
    average_impact_score: 0
  })
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')
  const router = useRouter()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<CreateOptimizationForm>({
    resolver: zodResolver(createOptimizationSchema),
  })

  useEffect(() => {
    const token = Cookies.get('access_token')
    if (!token) {
      router.push('/auth/login')
      return
    }

    loadOptimizationData()
  }, [router])

  const loadOptimizationData = async () => {
    try {
      // TODO: 实现optimization API调用
      // const [tasksResponse, statsResponse] = await Promise.all([
      //   optimizationAPI.listTasks(),
      //   optimizationAPI.getStats()
      // ])
      // setOptimizationTasks(tasksResponse.tasks)
      // setStats(statsResponse.stats)
      
      setOptimizationTasks([]) // 暂时为空
      setStats({
        total_tasks: 0,
        pending_tasks: 0,
        completed_tasks: 0,
        average_impact_score: 0
      })
    } catch (error) {
      console.error('Failed to load optimization data:', error)
      setError('Failed to load optimization data')
    } finally {
      setLoading(false)
    }
  }

  const onSubmit = async (data: CreateOptimizationForm) => {
    setSubmitting(true)
    setError('')

    try {
      // TODO: 实现optimization API调用
      // await optimizationAPI.createTask(data)
      console.log('Create optimization task:', data)
      
      // 重新加载数据
      await loadOptimizationData()
      reset()
    } catch (err: any) {
      console.error('Failed to create optimization task:', err)
      setError('Failed to create optimization task')
    } finally {
      setSubmitting(false)
    }
  }

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'high': return 'bg-red-100 text-red-800'
      case 'medium': return 'bg-yellow-100 text-yellow-800'
      case 'low': return 'bg-green-100 text-green-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed': return 'bg-green-100 text-green-800'
      case 'in_progress': return 'bg-blue-100 text-blue-800'
      case 'pending': return 'bg-gray-100 text-gray-800'
      default: return 'bg-gray-100 text-gray-800'
    }
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
          <h1 className="text-3xl font-bold">AI Optimization</h1>
          <p className="text-gray-600">AI-powered suggestions to optimize your product listings</p>
        </div>
        <Button onClick={() => router.push('/dashboard')}>
          Back to Dashboard
        </Button>
      </div>

      {/* Optimization Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <Card>
          <CardContent className="p-6">
            <div className="text-2xl font-bold">{stats.total_tasks}</div>
            <p className="text-xs text-muted-foreground">Total Tasks</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="text-2xl font-bold">{stats.pending_tasks}</div>
            <p className="text-xs text-muted-foreground">Pending Tasks</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="text-2xl font-bold">{stats.completed_tasks}</div>
            <p className="text-xs text-muted-foreground">Completed Tasks</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="text-2xl font-bold">{stats.average_impact_score.toFixed(1)}</div>
            <p className="text-xs text-muted-foreground">Avg Impact Score</p>
          </CardContent>
        </Card>
      </div>

      {/* Create Optimization Task Form */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle>Create Optimization Task</CardTitle>
          <CardDescription>
            Request AI-powered optimization suggestions for your products
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <Input
                  {...register('title')}
                  placeholder="Optimization Task Title"
                  disabled={submitting}
                />
                {errors.title && (
                  <p className="text-sm text-red-500 mt-1">{errors.title.message}</p>
                )}
              </div>
              
              <div>
                <Input
                  {...register('product_id')}
                  placeholder="Product ID (from tracked products)"
                  disabled={submitting}
                />
                {errors.product_id && (
                  <p className="text-sm text-red-500 mt-1">{errors.product_id.message}</p>
                )}
              </div>
            </div>

            <div>
              <Textarea
                {...register('description')}
                placeholder="Description (optional)"
                disabled={submitting}
                rows={3}
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <select
                  {...register('optimization_type')}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  disabled={submitting}
                >
                  <option value="listing">Listing Optimization</option>
                  <option value="pricing">Pricing Strategy</option>
                  <option value="keywords">Keyword Optimization</option>
                  <option value="images">Image Optimization</option>
                </select>
              </div>

              <div>
                <select
                  {...register('priority')}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  disabled={submitting}
                >
                  <option value="low">Low Priority</option>
                  <option value="medium">Medium Priority</option>
                  <option value="high">High Priority</option>
                </select>
              </div>
            </div>

            {error && (
              <div className="text-sm text-red-500 bg-red-50 p-3 rounded-md">
                {error}
              </div>
            )}

            <Button type="submit" disabled={submitting}>
              {submitting ? 'Creating...' : 'Create Optimization Task'}
            </Button>
          </form>
        </CardContent>
      </Card>

      {/* Optimization Tasks List */}
      <Card>
        <CardHeader>
          <CardTitle>Optimization Tasks ({optimizationTasks.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {optimizationTasks.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-gray-500 mb-4">
                No optimization tasks created yet.
              </p>
              <p className="text-sm text-gray-400">
                Create your first optimization task to get AI-powered suggestions.
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {optimizationTasks.map((task) => (
                <div
                  key={task.id}
                  className="flex items-start justify-between p-4 border rounded-lg"
                >
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <h3 className="font-semibold">{task.title}</h3>
                      <Badge className={getPriorityColor(task.priority)}>
                        {task.priority}
                      </Badge>
                      <Badge className={getStatusColor(task.status)}>
                        {task.status}
                      </Badge>
                    </div>
                    
                    <p className="text-sm text-gray-600 mb-2">
                      {task.description || 'No description'}
                    </p>
                    
                    <div className="flex items-center gap-4 text-sm text-gray-500 mb-3">
                      <span>Product: {task.product_asin}</span>
                      <span>Type: {task.optimization_type}</span>
                      {task.impact_score && (
                        <span>Impact Score: {task.impact_score}/10</span>
                      )}
                      {task.estimated_hours && (
                        <span>Est. Time: {task.estimated_hours}h</span>
                      )}
                    </div>

                    {task.ai_suggestions && task.ai_suggestions.length > 0 && (
                      <div className="mb-3">
                        <p className="text-sm font-medium text-gray-700 mb-1">AI Suggestions:</p>
                        <ul className="text-sm text-gray-600 space-y-1">
                          {task.ai_suggestions.map((suggestion, index) => (
                            <li key={index} className="flex items-start">
                              <span className="mr-2">•</span>
                              <span>{suggestion}</span>
                            </li>
                          ))}
                        </ul>
                      </div>
                    )}
                    
                    <p className="text-xs text-gray-400">
                      Created: {new Date(task.created_at).toLocaleDateString()}
                      {task.updated_at && (
                        <> • Updated: {new Date(task.updated_at).toLocaleDateString()}</>
                      )}
                    </p>
                  </div>
                  
                  <div className="flex items-center space-x-2">
                    <Button variant="outline" size="sm">
                      View Details
                    </Button>
                    {task.status === 'pending' && (
                      <Button size="sm">
                        Start Task
                      </Button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}