'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Cookies from 'js-cookie'

import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

const createAnalysisSchema = z.object({
  name: z.string().min(1, 'Analysis name is required'),
  description: z.string().optional(),
  main_product_id: z.string().min(1, 'Main product ID is required'),
  update_frequency: z.enum(['daily', 'weekly']).default('daily'),
})

type CreateAnalysisForm = z.infer<typeof createAnalysisSchema>

interface AnalysisGroup {
  id: string
  name: string
  description?: string
  main_product_asin: string
  competitor_count: number
  status: string
  last_analysis?: string
  created_at: string
}

export default function CompetitorsPage() {
  const [analysisGroups, setAnalysisGroups] = useState<AnalysisGroup[]>([])
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')
  const router = useRouter()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<CreateAnalysisForm>({
    resolver: zodResolver(createAnalysisSchema),
  })

  useEffect(() => {
    const token = Cookies.get('access_token')
    if (!token) {
      router.push('/auth/login')
      return
    }

    loadAnalysisGroups()
  }, [router])

  const loadAnalysisGroups = async () => {
    try {
      // TODO: 实现competitor API调用
      // const response = await competitorAPI.listGroups()
      // setAnalysisGroups(response.groups)
      setAnalysisGroups([]) // 暂时为空
    } catch (error) {
      console.error('Failed to load analysis groups:', error)
      setError('Failed to load analysis groups')
    } finally {
      setLoading(false)
    }
  }

  const onSubmit = async (data: CreateAnalysisForm) => {
    setSubmitting(true)
    setError('')

    try {
      // TODO: 实现competitor API调用
      // await competitorAPI.createAnalysisGroup(data)
      console.log('Create analysis group:', data)
      
      // 重新加载列表
      await loadAnalysisGroups()
      reset()
    } catch (err: any) {
      console.error('Failed to create analysis group:', err)
      setError('Failed to create analysis group')
    } finally {
      setSubmitting(false)
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
          <h1 className="text-3xl font-bold">Competitor Analysis</h1>
          <p className="text-gray-600">Analyze your competitors and market trends</p>
        </div>
        <Button onClick={() => router.push('/dashboard')}>
          Back to Dashboard
        </Button>
      </div>

      {/* Create Analysis Group Form */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle>Create Analysis Group</CardTitle>
          <CardDescription>
            Start analyzing your competitors by creating an analysis group
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <Input
                  {...register('name')}
                  placeholder="Analysis Group Name"
                  disabled={submitting}
                />
                {errors.name && (
                  <p className="text-sm text-red-500 mt-1">{errors.name.message}</p>
                )}
              </div>
              
              <div>
                <Input
                  {...register('main_product_id')}
                  placeholder="Main Product ID (from tracked products)"
                  disabled={submitting}
                />
                {errors.main_product_id && (
                  <p className="text-sm text-red-500 mt-1">{errors.main_product_id.message}</p>
                )}
              </div>
            </div>

            <div>
              <Input
                {...register('description')}
                placeholder="Description (optional)"
                disabled={submitting}
              />
            </div>

            <div>
              <select
                {...register('update_frequency')}
                className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                disabled={submitting}
              >
                <option value="daily">Daily Analysis</option>
                <option value="weekly">Weekly Analysis</option>
              </select>
            </div>

            {error && (
              <div className="text-sm text-red-500 bg-red-50 p-3 rounded-md">
                {error}
              </div>
            )}

            <Button type="submit" disabled={submitting}>
              {submitting ? 'Creating...' : 'Create Analysis Group'}
            </Button>
          </form>
        </CardContent>
      </Card>

      {/* Analysis Groups List */}
      <Card>
        <CardHeader>
          <CardTitle>Analysis Groups ({analysisGroups.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {analysisGroups.length === 0 ? (
            <div className="text-center py-8">
              <p className="text-gray-500 mb-4">
                No analysis groups created yet.
              </p>
              <p className="text-sm text-gray-400">
                Create your first analysis group to start comparing competitors.
              </p>
            </div>
          ) : (
            <div className="space-y-4">
              {analysisGroups.map((group) => (
                <div
                  key={group.id}
                  className="flex items-center justify-between p-4 border rounded-lg"
                >
                  <div className="flex-1">
                    <h3 className="font-semibold">{group.name}</h3>
                    <p className="text-sm text-gray-600">{group.description || 'No description'}</p>
                    <p className="text-sm text-gray-500">
                      Main Product: {group.main_product_asin} • 
                      Competitors: {group.competitor_count} • 
                      Status: {group.status}
                    </p>
                    <p className="text-xs text-gray-400">
                      Created: {new Date(group.created_at).toLocaleDateString()}
                      {group.last_analysis && (
                        <> • Last Analysis: {new Date(group.last_analysis).toLocaleDateString()}</>
                      )}
                    </p>
                  </div>
                  
                  <div className="flex items-center space-x-2">
                    <Button variant="outline" size="sm">
                      View Analysis
                    </Button>
                    <Button variant="outline" size="sm">
                      Add Competitors
                    </Button>
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