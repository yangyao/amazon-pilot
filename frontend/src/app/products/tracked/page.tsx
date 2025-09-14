'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Loader2, RefreshCw, Trash2, ArrowLeft, Star } from 'lucide-react'
import { useToast } from '@/hooks/use-toast'
import { productAPI, type TrackedProduct } from '@/lib/product-api'
import Cookies from 'js-cookie'

export default function TrackedProductsPage() {
  const [products, setProducts] = useState<TrackedProduct[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshingStates, setRefreshingStates] = useState<{[key: string]: boolean}>({})
  const router = useRouter()
  const { toast } = useToast()

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
      setProducts(response.tracked || [])
    } catch (error) {
      console.error('Failed to load products:', error)
      toast({
        title: "加载失败",
        description: "无法加载追踪产品列表",
        variant: "destructive"
      })
    } finally {
      setLoading(false)
    }
  }

  const refreshProduct = async (productId: string, asin: string) => {
    setRefreshingStates(prev => ({ ...prev, [productId]: true }))

    try {
      await productAPI.refreshData(productId)

      toast({
        title: "刷新任务已提交",
        description: `产品 ${asin} 的数据正在后台更新中`,
      })

      // 等待一会后重新加载
      setTimeout(() => {
        loadProducts()
      }, 3000)
    } catch (error) {
      toast({
        title: "刷新失败",
        description: error instanceof Error ? error.message : "刷新数据失败",
        variant: "destructive"
      })
    } finally {
      setRefreshingStates(prev => ({ ...prev, [productId]: false }))
    }
  }

  const stopTracking = async (productId: string, asin: string) => {
    try {
      await productAPI.stopTracking(productId)
      toast({
        title: "停止成功",
        description: `已停止追踪产品 ${asin}`,
      })
      await loadProducts()
    } catch (error) {
      toast({
        title: "操作失败",
        description: "停止追踪失败",
        variant: "destructive"
      })
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <Loader2 className="w-8 h-8 animate-spin" />
      </div>
    )
  }

  return (
    <div className="container mx-auto py-8">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold">已追踪产品</h1>
          <p className="text-gray-600">管理和刷新已追踪的 Amazon 产品数据</p>
        </div>
        <div className="flex gap-2">
          <Button onClick={() => router.push('/products/search')} variant="outline">
            搜索新产品
          </Button>
          <Button onClick={() => router.push('/products')}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            返回
          </Button>
        </div>
      </div>

      {products.length === 0 ? (
        <Card>
          <CardContent className="py-8 text-center">
            <p className="text-muted-foreground mb-4">还没有追踪任何产品</p>
            <Button onClick={() => router.push('/products/search')}>
              开始搜索产品
            </Button>
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardHeader>
            <CardTitle>追踪产品列表 ({products.length})</CardTitle>
            <CardDescription>
              点击"刷新数据"获取最新的产品信息
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ASIN</TableHead>
                  <TableHead>标题/别名</TableHead>
                  <TableHead>当前价格</TableHead>
                  <TableHead>评分</TableHead>
                  <TableHead>BSR</TableHead>
                  <TableHead>状态</TableHead>
                  <TableHead>最后更新</TableHead>
                  <TableHead>操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {products.map((product) => (
                  <TableRow key={product.id}>
                    <TableCell className="font-mono text-sm">{product.asin}</TableCell>
                    <TableCell>
                      <div>
                        <div className="font-medium">{product.title || product.alias || product.asin}</div>
                        {product.alias && product.title && (
                          <div className="text-sm text-muted-foreground">{product.alias}</div>
                        )}
                      </div>
                    </TableCell>
                    <TableCell>
                      {product.current_price > 0 ? (
                        <div className="font-medium text-green-600">
                          {product.currency} {product.current_price.toFixed(2)}
                        </div>
                      ) : (
                        <span className="text-muted-foreground">N/A</span>
                      )}
                    </TableCell>
                    <TableCell>
                      {product.rating ? (
                        <div className="flex items-center gap-1">
                          <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                          <span>{product.rating}</span>
                          <span className="text-sm text-muted-foreground">
                            ({product.review_count})
                          </span>
                        </div>
                      ) : (
                        <span className="text-muted-foreground">N/A</span>
                      )}
                    </TableCell>
                    <TableCell>
                      {product.bsr ? (
                        <span>#{product.bsr.toLocaleString()}</span>
                      ) : (
                        <span className="text-muted-foreground">N/A</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <Badge variant={product.status === 'active' ? 'default' : 'secondary'}>
                        {product.status === 'active' ? '活跃' : '暂停'}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      {product.last_updated ? new Date(product.last_updated).toLocaleDateString() : 'N/A'}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => refreshProduct(product.id, product.asin)}
                          disabled={refreshingStates[product.id]}
                        >
                          {refreshingStates[product.id] ? (
                            <Loader2 className="w-4 h-4 animate-spin" />
                          ) : (
                            <RefreshCw className="w-4 h-4" />
                          )}
                        </Button>
                        <Button
                          size="sm"
                          variant="destructive"
                          onClick={() => stopTracking(product.id, product.asin)}
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}
    </div>
  )
}