'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Loader2, Search, Plus, Star, ArrowLeft } from 'lucide-react'
import { useToast } from '@/hooks/use-toast'
import { productAPI, type ApifyProductData } from '@/lib/product-api'

export default function SearchProductsPage() {
  const [searchResults, setSearchResults] = useState<ApifyProductData[]>([])
  const [searching, setSearching] = useState(false)
  const [trackingStates, setTrackingStates] = useState<{[key: string]: boolean}>({})
  const [selectedCategory, setSelectedCategory] = useState('electronics')
  const router = useRouter()
  const { toast } = useToast()

  // Demo建议的类别
  const demoCategories = [
    { value: 'electronics', label: '电子产品' },
    { value: 'wireless earbuds', label: '无线蓝牙耳机' },
    { value: 'yoga mats', label: '瑜伽垫' },
    { value: 'kitchen', label: '厨房用品' },
    { value: 'pet supplies', label: '宠物用品' }
  ]

  const searchProducts = async () => {
    setSearching(true)
    try {
      const response = await productAPI.searchProducts({
        category: selectedCategory,
        max_results: 10
      })

      if (response.success) {
        setSearchResults(response.products || [])
        toast({
          title: "搜索成功",
          description: `找到 ${response.products_count} 个 ${selectedCategory} 类目产品`
        })
      } else {
        throw new Error(response.message)
      }
    } catch (error) {
      console.error('Failed to search products:', error)
      toast({
        title: "搜索失败",
        description: error instanceof Error ? error.message : "搜索产品失败",
        variant: "destructive"
      })
    } finally {
      setSearching(false)
    }
  }

  const trackProduct = async (asin: string, title: string, category?: string) => {
    setTrackingStates(prev => ({ ...prev, [asin]: true }))

    try {
      await productAPI.addTracking({
        asin,
        alias: title || asin,
        category: category || selectedCategory,
        tracking_settings: {
          price_change_threshold: 10,
          bsr_change_threshold: 30,
          update_frequency: 'daily'
        }
      })

      toast({
        title: "添加成功",
        description: `产品 ${asin} 已添加到追踪列表`,
      })

      // 跳转到追踪列表页面
      router.push('/products')
    } catch (error) {
      toast({
        title: "添加失败",
        description: error instanceof Error ? error.message : "添加追踪失败",
        variant: "destructive"
      })
    } finally {
      setTrackingStates(prev => ({ ...prev, [asin]: false }))
    }
  }

  return (
    <div className="container mx-auto py-8">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold">搜索 Amazon 产品</h1>
          <p className="text-gray-600">按类目搜索 Amazon 最畅销产品并添加到追踪系统</p>
        </div>
        <Button onClick={() => router.push('/products')} variant="outline">
          <ArrowLeft className="w-4 h-4 mr-2" />
          返回产品列表
        </Button>
      </div>

      {/* 类目搜索区域 */}
      <Card className="mb-8">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Search className="w-5 h-5" />
            按类目搜索产品
          </CardTitle>
          <CardDescription>
            选择类目搜索 Amazon Best Sellers (基于 questions.md 建议的Demo类别)
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex gap-4">
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="flex h-10 w-full max-w-xs rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
            >
              {demoCategories.map((cat) => (
                <option key={cat.value} value={cat.value}>
                  {cat.label}
                </option>
              ))}
            </select>
            <Button
              onClick={searchProducts}
              disabled={searching}
              className="min-w-[140px]"
            >
              {searching ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  搜索中...
                </>
              ) : (
                <>
                  <Search className="w-4 h-4 mr-2" />
                  搜索产品
                </>
              )}
            </Button>
          </div>

          <div className="text-sm text-muted-foreground">
            <p><strong>注意:</strong> 搜索需要约30-60秒时间，请耐心等待</p>
            <p><strong>Demo类别:</strong> 根据 questions.md 建议选择同类别产品进行测试</p>
          </div>
        </CardContent>
      </Card>

      {/* 搜索结果表格 */}
      {searchResults.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              <span>搜索结果 ({searchResults.length})</span>
              <Badge variant="secondary">来自 Amazon Best Sellers</Badge>
            </CardTitle>
            <CardDescription>
              点击"加入跟踪"将产品添加到监控系统
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>ASIN</TableHead>
                  <TableHead>标题</TableHead>
                  <TableHead>品牌</TableHead>
                  <TableHead>价格</TableHead>
                  <TableHead>BSR</TableHead>
                  <TableHead>评分</TableHead>
                  <TableHead>操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {searchResults.map((product) => (
                  <TableRow key={product.asin}>
                    <TableCell className="font-mono text-sm">{product.asin}</TableCell>
                    <TableCell>{product.title || product.asin}</TableCell>
                    <TableCell>{product.brand || 'N/A'}</TableCell>
                    <TableCell>{product.price ? `$${product.price}` : 'N/A'}</TableCell>
                    <TableCell>{product.bsr || 'N/A'}</TableCell>
                    <TableCell>
                      {product.rating ? (
                        <div className="flex items-center">
                          <Star className="w-4 h-4 fill-yellow-400 text-yellow-400 mr-1" />
                          {product.rating}
                          <span className="text-sm text-muted-foreground ml-1">
                            ({product.review_count})
                          </span>
                        </div>
                      ) : 'N/A'}
                    </TableCell>
                    <TableCell>
                      <Button
                        size="sm"
                        onClick={() => trackProduct(product.asin, product.title, product.category)}
                        disabled={trackingStates[product.asin]}
                      >
                        {trackingStates[product.asin] ? (
                          <>
                            <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                            添加中...
                          </>
                        ) : (
                          <>
                            <Plus className="w-4 h-4 mr-2" />
                            加入跟踪
                          </>
                        )}
                      </Button>
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