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
import { productAPI, type TrackedProduct } from '@/lib/product-api'

const addTrackingSchema = z.object({
  asin: z.string().regex(/^[B][0-9A-Z]{9}$/, 'ASIN must be 10 characters starting with B'),
  alias: z.string().optional(),
  category: z.string().optional(),
  price_threshold: z.number().min(0).max(100).default(10),
  bsr_threshold: z.number().min(0).max(100).default(30),
  frequency: z.enum(['hourly', 'daily', 'weekly']).default('daily'),
})

type AddTrackingForm = z.infer<typeof addTrackingSchema>

export default function ProductsPage() {
  const [products, setProducts] = useState<TrackedProduct[]>([])
  const [loading, setLoading] = useState(true)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')
  const router = useRouter()

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<AddTrackingForm>({
    resolver: zodResolver(addTrackingSchema),
  })

  useEffect(() => {
    const token = Cookies.get('access_token')
    if (!token) {
      router.push('/auth/login')
      return
    }

    loadProducts()
  }, [router])

  const loadProducts = async () => {
    try {
      const response = await productAPI.getTracked()
      setProducts(response.products || [])
    } catch (error) {
      console.error('Failed to load products:', error)
      setError('Failed to load products')
    } finally {
      setLoading(false)
    }
  }

  const onSubmit = async (data: AddTrackingForm) => {
    setSubmitting(true)
    setError('')

    try {
      await productAPI.addTracking({
        asin: data.asin.toUpperCase(),
        alias: data.alias,
        category: data.category,
        tracking_settings: {
          price_change_threshold: data.price_threshold,
          bsr_change_threshold: data.bsr_threshold,
          update_frequency: data.frequency,
        },
      })

      // 重新加载产品列表
      await loadProducts()
      reset()
    } catch (err: any) {
      console.error('Failed to add tracking:', err)
      
      if (err.response?.data?.error) {
        const errorData = err.response.data.error
        if (errorData.details && errorData.details.length > 0) {
          setError(`${errorData.message}: ${errorData.details.map((d: any) => d.message).join(', ')}`)
        } else {
          setError(errorData.message)
        }
      } else {
        setError('Failed to add product tracking')
      }
    } finally {
      setSubmitting(false)
    }
  }

  const handleStopTracking = async (productId: string) => {
    try {
      await productAPI.stopTracking(productId)
      await loadProducts()
    } catch (error) {
      console.error('Failed to stop tracking:', error)
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
          <h1 className="text-3xl font-bold">Product Tracking</h1>
          <p className="text-gray-600">Monitor your Amazon products</p>
        </div>
        <Button onClick={() => router.push('/dashboard')}>
          Back to Dashboard
        </Button>
      </div>

      {/* Add Product Form */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle>Add Product to Track</CardTitle>
          <CardDescription>
            Enter an Amazon ASIN to start tracking
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <Input
                  {...register('asin')}
                  placeholder="ASIN (e.g., B08N5WRWNW)"
                  disabled={submitting}
                />
                {errors.asin && (
                  <p className="text-sm text-red-500 mt-1">{errors.asin.message}</p>
                )}
              </div>
              
              <div>
                <Input
                  {...register('alias')}
                  placeholder="Alias (optional)"
                  disabled={submitting}
                />
              </div>
              
              <div>
                <Input
                  {...register('category')}
                  placeholder="Category (optional)"
                  disabled={submitting}
                />
              </div>
              
              <div>
                <select
                  {...register('frequency')}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                  disabled={submitting}
                >
                  <option value="daily">Daily Updates</option>
                  <option value="hourly">Hourly Updates</option>
                  <option value="weekly">Weekly Updates</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm font-medium">Price Change Threshold (%)</label>
                <Input
                  {...register('price_threshold', { valueAsNumber: true })}
                  type="number"
                  min="0"
                  max="100"
                  defaultValue="10"
                  disabled={submitting}
                />
              </div>
              
              <div>
                <label className="text-sm font-medium">BSR Change Threshold (%)</label>
                <Input
                  {...register('bsr_threshold', { valueAsNumber: true })}
                  type="number"
                  min="0"
                  max="100"
                  defaultValue="30"
                  disabled={submitting}
                />
              </div>
            </div>

            {error && (
              <div className="text-sm text-red-500 bg-red-50 p-3 rounded-md">
                {error}
              </div>
            )}

            <Button type="submit" disabled={submitting}>
              {submitting ? 'Adding...' : 'Add Product'}
            </Button>
          </form>
        </CardContent>
      </Card>

      {/* Products List */}
      <Card>
        <CardHeader>
          <CardTitle>Tracked Products ({products?.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {products?.length === 0 ? (
            <p className="text-gray-500 text-center py-8">
              No products tracked yet. Add your first product above.
            </p>
          ) : (
            <div className="space-y-4">
              {products.map((product) => (
                <div
                  key={product.id}
                  className="flex items-center justify-between p-4 border rounded-lg"
                >
                  <div className="flex-1">
                    <div className="flex items-center space-x-4">
                      <div>
                        <h3 className="font-semibold">
                          {product.alias || product.title || product.asin}
                        </h3>
                        <p className="text-sm text-gray-600">ASIN: {product.asin}</p>
                        <p className="text-sm text-gray-500">
                          Last updated: {new Date(product.last_updated).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                  </div>
                  
                  <div className="flex items-center space-x-2">
                    <span
                      className={`px-2 py-1 rounded-full text-xs ${
                        product.status === 'active'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}
                    >
                      {product.status}
                    </span>
                    
                    <Button
                      variant="destructive"
                      size="sm"
                      onClick={() => handleStopTracking(product.id)}
                    >
                      Stop Tracking
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