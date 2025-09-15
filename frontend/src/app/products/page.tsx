'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Loader2, RefreshCw, Trash2, Search, List, Package, BarChart3, Home, Star, Plus, AlertTriangle, TestTube } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useToast } from '@/hooks/use-toast'
import { productAPI, type TrackedProduct, type AnomalyEvent as APIAnomalyEvent } from '@/lib/product-api'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Cookies from 'js-cookie'

// 表单验证schema - 移除frequency（固定为daily）
const addTrackingSchema = z.object({
  asin: z.string().regex(/^[B][0-9A-Z]{9}$/, 'ASIN必须是10位字符，以B开头'),
  alias: z.string().optional(),
  category: z.string().optional(),
  price_threshold: z.number().min(0).max(100).default(10),
  bsr_threshold: z.number().min(0).max(100).default(30),
  // frequency removed - fixed at daily per questions.md
})

type AddTrackingForm = z.infer<typeof addTrackingSchema>

export default function ProductsPage() {
  const [tracked, setTracked] = useState<TrackedProduct[]>([])
  const [anomalyEvents, setAnomalyEvents] = useState<APIAnomalyEvent[]>([])
  const [loading, setLoading] = useState(true)
  const [loadingEvents, setLoadingEvents] = useState(false)
  const [refreshingStates, setRefreshingStates] = useState<{[key: string]: boolean}>({})
  const [activeTab, setActiveTab] = useState('tracked')
  const [submitting, setSubmitting] = useState(false)
  const [selectedProduct, setSelectedProduct] = useState<TrackedProduct | null>(null)
  const [historyData, setHistoryData] = useState<any>(null)
  const [loadingHistory, setLoadingHistory] = useState(false)
  const [mockPriceDialogOpen, setMockPriceDialogOpen] = useState(false)
  const [selectedTrackedId, setSelectedTrackedId] = useState<string>('')
  const [mockPrice, setMockPrice] = useState<string>('')
  const [addingMockPrice, setAddingMockPrice] = useState(false)
  const router = useRouter()
  const { toast } = useToast()

  // 表单处理
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<AddTrackingForm>({
    resolver: zodResolver(addTrackingSchema),
    defaultValues: {
      price_threshold: 10,
      bsr_threshold: 30,
      // frequency removed - fixed at daily
    }
  })


  const menuItems = [
    { id: 'tracked', label: '已追踪产品', icon: List },
    { id: 'alerts', label: '异常警报', icon: AlertTriangle },
    { id: 'add', label: '添加产品', icon: Package },
    { id: 'analytics', label: '数据分析', icon: BarChart3 },
  ]

  useEffect(() => {
    const token = Cookies.get('access_token')
    if (!token) {
      router.push('/auth/login')
      return
    }

    if (activeTab === 'tracked') {
      loadTracked()
    } else if (activeTab === 'alerts') {
      loadAnomalyEvents()
    }
  }, [router, activeTab])

  const loadTracked = async () => {
    try {
      const response = await productAPI.getTracked()
      setTracked(response.tracked || [])
    } catch (error) {
      console.error('Failed to load tracked:', error)
      toast({
        title: "加载失败",
        description: "无法加载追踪记录列表",
        variant: "destructive"
      })
    } finally {
      setLoading(false)
    }
  }

  const loadAnomalyEvents = async () => {
    setLoadingEvents(true)
    try {
      const response = await productAPI.getAnomalyEvents({
        page: 1,
        limit: 50
      })
      setAnomalyEvents(response.events || [])
    } catch (error) {
      console.error('Failed to load change events:', error)
      toast({
        title: "加载异常事件失败",
        description: "无法加载异常变化事件",
        variant: "destructive"
      })
    } finally {
      setLoadingEvents(false)
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

      setTimeout(() => {
        loadTracked()
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
      await loadTracked()
    } catch (error) {
      toast({
        title: "操作失败",
        description: "停止追踪失败",
        variant: "destructive"
      })
    }
  }

  const openMockPriceDialog = (trackedId: string) => {
    setSelectedTrackedId(trackedId)
    setMockPrice('')
    setMockPriceDialogOpen(true)
  }

  const addMockPriceHistory = async () => {
    if (!mockPrice || !selectedTrackedId) return

    setAddingMockPrice(true)
    try {
      await productAPI.addMockPriceHistory(selectedTrackedId, {
        price: parseFloat(mockPrice),
        currency: 'USD'
      })

      toast({
        title: "测试价格已添加",
        description: `已添加测试价格 $${mockPrice}，现在可以执行刷新来模拟异常检测`,
      })

      setMockPriceDialogOpen(false)
      setMockPrice('')
      setSelectedTrackedId('')
    } catch (error: any) {
      toast({
        title: "添加失败",
        description: error.response?.data?.message || "添加测试价格失败",
        variant: "destructive"
      })
    } finally {
      setAddingMockPrice(false)
    }
  }

  const onSubmit = async (data: AddTrackingForm) => {
    setSubmitting(true)
    try {
      await productAPI.addTracking({
        asin: data.asin,
        alias: data.alias,
        category: data.category,
        tracking_settings: {
          price_change_threshold: data.price_threshold,
          bsr_change_threshold: data.bsr_threshold,
        }
      })

      toast({
        title: "添加成功",
        description: `产品 ${data.asin} 已添加到追踪列表`,
      })

      reset()
      setActiveTab('tracked')
      await loadTracked()
    } catch (error: any) {
      toast({
        title: "添加失败",
        description: error.response?.data?.error?.message || "添加产品追踪失败",
        variant: "destructive"
      })
    } finally {
      setSubmitting(false)
    }
  }

  const viewProductHistory = async (product: TrackedProduct, metric: string) => {
    setSelectedProduct(product)
    setLoadingHistory(true)

    try {
      const historyResponse = await productAPI.getProductHistory(product.id, {
        metric: metric,
        period: '30d'
      })

      setHistoryData(historyResponse)
      // 移除成功提示弹窗，避免打扰用户
    } catch (error) {
      toast({
        title: "加载失败",
        description: error instanceof Error ? error.message : "无法加载历史数据",
        variant: "destructive"
      })
    } finally {
      setLoadingHistory(false)
    }
  }

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-100 text-red-800 border-red-200'
      case 'warning': return 'bg-orange-100 text-orange-800 border-orange-200'
      default: return 'bg-gray-100 text-gray-800 border-gray-200'
    }
  }

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical': return '🚨'
      case 'warning': return '⚠️'
      default: return 'ℹ️'
    }
  }

  const getEventTypeLabel = (eventType: string) => {
    switch (eventType) {
      case 'price_change': return '价格变动'
      case 'bsr_change': return 'BSR变动'
      case 'rating_change': return '评分变动'
      case 'review_count_change': return '评论数变动'
      case 'buybox_change': return 'Buy Box变动'
      default: return eventType
    }
  }

  const renderContent = () => {
    switch (activeTab) {
      case 'alerts':
        return (
          <div>
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-2xl font-bold">异常警报</h2>
                <p className="text-muted-foreground">查看产品价格、BSR等数据的异常变化警报</p>
              </div>
              <Button onClick={loadAnomalyEvents} variant="outline" disabled={loadingEvents}>
                {loadingEvents ? (
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                ) : (
                  <RefreshCw className="w-4 h-4 mr-2" />
                )}
                刷新警报
              </Button>
            </div>

            {loadingEvents ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="w-8 h-8 animate-spin" />
              </div>
            ) : anomalyEvents.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center">
                  <AlertTriangle className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground mb-4">暂无异常警报</p>
                  <p className="text-sm text-muted-foreground">
                    当产品价格变动 {'>'}10% 或 BSR变动 {'>'}30% 时，系统会自动生成警报
                  </p>
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardHeader>
                  <CardTitle>异常事件列表 ({anomalyEvents.length})</CardTitle>
                  <CardDescription>
                    按严重程度排序，显示最近的异常变化事件
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>严重程度</TableHead>
                        <TableHead>事件类型</TableHead>
                        <TableHead>产品信息</TableHead>
                        <TableHead>ASIN</TableHead>
                        <TableHead>变化详情</TableHead>
                        <TableHead>变化幅度</TableHead>
                        <TableHead>触发时间</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {anomalyEvents.map((event) => (
                        <TableRow key={event.id} className="hover:bg-gray-50">
                          <TableCell>
                            <Badge className={`${getSeverityColor(event.severity)}`}>
                              {getSeverityIcon(event.severity)} {event.severity.toUpperCase()}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <Badge variant="outline">
                              {getEventTypeLabel(event.event_type)}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <div>
                              <div className="font-medium text-sm truncate max-w-xs">
                                {event.product_title || event.asin}
                              </div>
                            </div>
                          </TableCell>
                          <TableCell className="font-mono text-sm">{event.asin}</TableCell>
                          <TableCell>
                            <div className="text-sm">
                              {event.old_value && event.new_value && (
                                <div>
                                  <span className="text-red-600">
                                    {event.event_type === 'price_change' ? '$' : '#'}{event.old_value.toFixed(2)}
                                  </span>
                                  <span className="mx-1">→</span>
                                  <span className="text-green-600">
                                    {event.event_type === 'price_change' ? '$' : '#'}{event.new_value.toFixed(2)}
                                  </span>
                                </div>
                              )}
                            </div>
                          </TableCell>
                          <TableCell>
                            {event.change_percentage && (
                              <span className={`font-bold ${event.change_percentage > 0 ? 'text-red-600' : 'text-green-600'}`}>
                                {event.change_percentage > 0 ? '+' : ''}{event.change_percentage.toFixed(1)}%
                              </span>
                            )}
                          </TableCell>
                          <TableCell className="text-sm text-muted-foreground">
                            {new Date(event.created_at).toLocaleString()}
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

      case 'tracked':
        return (
          <div>
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-2xl font-bold">已追踪产品</h2>
                <p className="text-muted-foreground">管理和刷新已追踪的 Amazon 产品数据</p>
              </div>
              <Button onClick={() => setActiveTab('add')} variant="outline">
                <Plus className="w-4 h-4 mr-2" />
                添加新产品
              </Button>
            </div>

            {loading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="w-8 h-8 animate-spin" />
              </div>
            ) : tracked.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center">
                  <p className="text-muted-foreground mb-4">还没有追踪任何产品</p>
                  <Button onClick={() => setActiveTab('add')}>
                    添加产品追踪
                  </Button>
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardHeader>
                  <CardTitle>追踪产品列表 ({tracked.length})</CardTitle>
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
                        <TableHead>Buy Box价格</TableHead>
                        <TableHead>评分</TableHead>
                        <TableHead>BSR</TableHead>
                        <TableHead>状态</TableHead>
                        <TableHead>最后更新</TableHead>
                        <TableHead>操作</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {tracked.map((product) => (
                        <TableRow key={product.id}>
                          <TableCell className="font-mono text-sm">{product.asin}</TableCell>
                          <TableCell>
                            <div>
                              <div className="font-medium">{product.title || product.alias || product.asin}</div>
                              {product.alias && product.title && (
                                <div className="text-sm text-muted-foreground">{product.alias}</div>
                              )}
                              {/* 显示 bullet points 预览 */}
                              {product.bullet_points && product.bullet_points.length > 0 && (
                                <Dialog>
                                  <DialogTrigger asChild>
                                    <Button variant="link" className="h-auto p-0 text-xs text-blue-600 mt-1">
                                      查看产品特性 ({product.bullet_points.length})
                                    </Button>
                                  </DialogTrigger>
                                  <DialogContent className="max-w-2xl">
                                    <DialogHeader>
                                      <DialogTitle>{product.title || product.asin} - 产品特性</DialogTitle>
                                      <DialogDescription>
                                        Amazon 产品的主要特性和卖点
                                      </DialogDescription>
                                    </DialogHeader>
                                    <div className="mt-4">
                                      <ul className="space-y-2">
                                        {product.bullet_points.map((point, index) => (
                                          <li key={index} className="flex items-start gap-2">
                                            <span className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></span>
                                            <span className="text-sm leading-relaxed">{point}</span>
                                          </li>
                                        ))}
                                      </ul>
                                    </div>
                                  </DialogContent>
                                </Dialog>
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
                            {product.buy_box_price && product.buy_box_price > 0 ? (
                              <div className="font-medium text-blue-600">
                                {product.currency} {product.buy_box_price.toFixed(2)}
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
                                  ({product.review_count?.toLocaleString() || 0})
                                </span>
                              </div>
                            ) : product.review_count ? (
                              <div className="flex items-center gap-1">
                                <span className="text-sm text-muted-foreground">暂无评分</span>
                                <span className="text-sm text-muted-foreground">
                                  ({product.review_count.toLocaleString()} 条评论)
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
                                title="刷新数据"
                              >
                                {refreshingStates[product.id] ? (
                                  <Loader2 className="w-4 h-4 animate-spin" />
                                ) : (
                                  <RefreshCw className="w-4 h-4" />
                                )}
                              </Button>
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => openMockPriceDialog(product.id)}
                                className="text-orange-600 border-orange-200 hover:bg-orange-50"
                                title="添加测试价格（用于异常检测测试）"
                              >
                                <TestTube className="w-4 h-4" />
                              </Button>
                              <Button
                                size="sm"
                                variant="destructive"
                                onClick={() => stopTracking(product.id, product.asin)}
                                title="停止追踪"
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

      case 'add':
        return (
          <div>
            <div className="mb-6">
              <h2 className="text-2xl font-bold mb-2">添加产品追踪</h2>
              <p className="text-muted-foreground">输入Amazon产品ASIN快速添加到追踪系统</p>
            </div>

            <Card className="max-w-2xl">
              <CardHeader>
                <CardTitle>手工添加ASIN</CardTitle>
                <CardDescription>
                  如果你已知Amazon产品的ASIN，可以直接添加到追踪系统
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div className="space-y-2">
                      <Label htmlFor="asin">ASIN *</Label>
                      <Input
                        id="asin"
                        placeholder="B08N5WRWNW"
                        {...register('asin')}
                        className={errors.asin ? 'border-red-500' : ''}
                      />
                      {errors.asin && (
                        <p className="text-sm text-red-500">{errors.asin.message}</p>
                      )}
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="alias">别名 (可选)</Label>
                      <Input
                        id="alias"
                        placeholder="产品别名"
                        {...register('alias')}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="category">类别 (可选)</Label>
                      <Input
                        id="category"
                        placeholder="Electronics"
                        {...register('category')}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="update_info">更新频率</Label>
                      <div className="flex h-10 w-full rounded-md border border-input bg-gray-50 px-3 py-2 text-sm text-muted-foreground items-center">
                        每日一次（固定）
                      </div>
                      <p className="text-xs text-muted-foreground">
                        根据requirements，产品数据每日自动更新
                      </p>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="price_threshold">价格变动阈值 (%)</Label>
                      <Input
                        id="price_threshold"
                        type="number"
                        min="0"
                        max="100"
                        {...register('price_threshold', { valueAsNumber: true })}
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="bsr_threshold">BSR变动阈值 (%)</Label>
                      <Input
                        id="bsr_threshold"
                        type="number"
                        min="0"
                        max="100"
                        {...register('bsr_threshold', { valueAsNumber: true })}
                      />
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <Button type="submit" disabled={submitting} className="flex-1">
                      {submitting ? (
                        <>
                          <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                          添加中...
                        </>
                      ) : (
                        <>
                          <Plus className="w-4 h-4 mr-2" />
                          添加到追踪
                        </>
                      )}
                    </Button>
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => reset()}
                      disabled={submitting}
                    >
                      重置
                    </Button>
                  </div>
                </form>
              </CardContent>
            </Card>
          </div>
        )


      case 'analytics':
        return (
          <div>
            <h2 className="text-2xl font-bold mb-6">产品历史数据分析</h2>

            {tracked.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center">
                  <p className="text-muted-foreground mb-4">暂无追踪产品，无法显示历史数据</p>
                  <Button onClick={() => setActiveTab('add')}>
                    添加产品追踪
                  </Button>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-6">
                {/* 产品选择器 */}
                <Card>
                  <CardHeader>
                    <CardTitle>选择要分析的产品</CardTitle>
                    <CardDescription>
                      查看产品的价格、BSR、评分等历史变化趋势
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <Table>
                      <TableHeader>
                        <TableRow>
                          <TableHead>产品信息</TableHead>
                          <TableHead>ASIN</TableHead>
                          <TableHead>当前价格</TableHead>
                          <TableHead>Buy Box价格</TableHead>
                          <TableHead>评分</TableHead>
                          <TableHead>BSR排名</TableHead>
                          <TableHead>状态</TableHead>
                          <TableHead>操作</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {tracked.map((product) => (
                          <TableRow key={product.id} className="hover:bg-gray-50">
                            <TableCell>
                              <div className="flex items-center gap-3">
                                {product.images && product.images[0] && (
                                  <img
                                    src={product.images[0]}
                                    alt={product.title}
                                    className="w-10 h-10 object-cover rounded border"
                                  />
                                )}
                                <div className="flex-1 min-w-0">
                                  <p className="font-medium text-sm truncate max-w-xs">{product.title || product.alias || product.asin}</p>
                                  {product.brand && (
                                    <Badge variant="outline" className="text-xs mt-1">{product.brand}</Badge>
                                  )}
                                  {/* 显示 bullet points 链接 */}
                                  {product.bullet_points && product.bullet_points.length > 0 && (
                                    <Dialog>
                                      <DialogTrigger asChild>
                                        <Button variant="link" className="h-auto p-0 text-xs text-blue-600 mt-1">
                                          产品特性 ({product.bullet_points.length})
                                        </Button>
                                      </DialogTrigger>
                                      <DialogContent className="max-w-2xl">
                                        <DialogHeader>
                                          <DialogTitle>{product.title || product.asin} - 产品特性</DialogTitle>
                                          <DialogDescription>
                                            Amazon 产品的主要特性和卖点
                                          </DialogDescription>
                                        </DialogHeader>
                                        <div className="mt-4">
                                          <ul className="space-y-2">
                                            {product.bullet_points.map((point, index) => (
                                              <li key={index} className="flex items-start gap-2">
                                                <span className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></span>
                                                <span className="text-sm leading-relaxed">{point}</span>
                                              </li>
                                            ))}
                                          </ul>
                                        </div>
                                      </DialogContent>
                                    </Dialog>
                                  )}
                                </div>
                              </div>
                            </TableCell>
                            <TableCell className="font-mono text-sm">{product.asin}</TableCell>
                            <TableCell>
                              {product.current_price > 0 ? (
                                <span className="font-bold text-green-600">
                                  {product.currency} {product.current_price.toFixed(2)}
                                </span>
                              ) : (
                                <span className="text-muted-foreground">N/A</span>
                              )}
                            </TableCell>
                            <TableCell>
                              {product.buy_box_price && product.buy_box_price > 0 ? (
                                <span className="font-bold text-blue-600">
                                  {product.currency} {product.buy_box_price.toFixed(2)}
                                </span>
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
                                    ({product.review_count?.toLocaleString() || 0})
                                  </span>
                                </div>
                              ) : product.review_count ? (
                                <div className="flex items-center gap-1">
                                  <span className="text-sm text-muted-foreground">暂无评分</span>
                                  <span className="text-sm text-muted-foreground">
                                    ({product.review_count.toLocaleString()} 条评论)
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
                            <TableCell>
                              <div className="flex flex-wrap gap-1">
                                {/* 价格历史 */}
                                <Dialog>
                                  <DialogTrigger asChild>
                                    <Button
                                      size="sm"
                                      variant="outline"
                                      onClick={() => viewProductHistory(product, 'price')}
                                      disabled={loadingHistory}
                                    >
                                      {loadingHistory && selectedProduct?.id === product.id ? (
                                        <Loader2 className="w-3 h-3 animate-spin" />
                                      ) : (
                                        '价格历史'
                                      )}
                                    </Button>
                                  </DialogTrigger>
                                  <DialogContent className="max-w-4xl">
                                    <DialogHeader>
                                      <DialogTitle>{product.asin} - 价格历史</DialogTitle>
                                      <DialogDescription>
                                        查看产品价格变化趋势和历史数据
                                      </DialogDescription>
                                    </DialogHeader>
                                    {historyData && selectedProduct?.id === product.id && historyData.metric === 'price' && (
                                      <div className="mt-4">
                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                                          <div>
                                            <h4 className="font-medium mb-2">数据概览</h4>
                                            <div className="text-sm space-y-1">
                                              <div className="flex justify-between">
                                                <span>数据点数:</span>
                                                <span>{historyData.data?.length || 0}</span>
                                              </div>
                                              <div className="flex justify-between">
                                                <span>最新值:</span>
                                                <span className="font-medium">
                                                  ${historyData.data?.[historyData.data.length - 1]?.value || 'N/A'}
                                                </span>
                                              </div>
                                            </div>
                                          </div>
                                          <div>
                                            <h4 className="font-medium mb-2">最近记录</h4>
                                            <div className="text-sm space-y-1 max-h-32 overflow-y-auto">
                                              {historyData.data?.slice(-5).reverse().map((item: any, index: number) => (
                                                <div key={index} className="flex justify-between py-1 border-b border-gray-100">
                                                  <span className="text-muted-foreground">{item.date}</span>
                                                  <span className="font-medium">${item.value}</span>
                                                </div>
                                              ))}
                                            </div>
                                          </div>
                                        </div>
                                      </div>
                                    )}
                                  </DialogContent>
                                </Dialog>

                                {/* BSR历史 */}
                                <Dialog>
                                  <DialogTrigger asChild>
                                    <Button
                                      size="sm"
                                      variant="outline"
                                      onClick={() => viewProductHistory(product, 'bsr')}
                                      disabled={loadingHistory}
                                    >
                                      BSR历史
                                    </Button>
                                  </DialogTrigger>
                                  <DialogContent className="max-w-4xl">
                                    <DialogHeader>
                                      <DialogTitle>{product.asin} - BSR历史</DialogTitle>
                                      <DialogDescription>
                                        查看产品BSR排名变化趋势和历史数据
                                      </DialogDescription>
                                    </DialogHeader>
                                    {historyData && selectedProduct?.id === product.id && historyData.metric === 'bsr' && (
                                      <div className="mt-4">
                                        <div className="text-sm space-y-1">
                                          {historyData.data?.slice(-10).reverse().map((item: any, index: number) => (
                                            <div key={index} className="flex justify-between py-1 border-b border-gray-100">
                                              <span className="text-muted-foreground">{item.date}</span>
                                              <span className="font-medium">#{item.value}</span>
                                            </div>
                                          ))}
                                        </div>
                                      </div>
                                    )}
                                  </DialogContent>
                                </Dialog>

                                {/* 评分历史 */}
                                <Dialog>
                                  <DialogTrigger asChild>
                                    <Button
                                      size="sm"
                                      variant="outline"
                                      onClick={() => viewProductHistory(product, 'rating')}
                                      disabled={loadingHistory}
                                    >
                                      评分历史
                                    </Button>
                                  </DialogTrigger>
                                  <DialogContent className="max-w-4xl">
                                    <DialogHeader>
                                      <DialogTitle>{product.asin} - 评分历史</DialogTitle>
                                      <DialogDescription>
                                        查看产品评分变化趋势和历史数据
                                      </DialogDescription>
                                    </DialogHeader>
                                    {historyData && selectedProduct?.id === product.id && historyData.metric === 'rating' && (
                                      <div className="mt-4">
                                        <div className="text-sm space-y-1">
                                          {historyData.data?.slice(-10).reverse().map((item: any, index: number) => (
                                            <div key={index} className="flex justify-between py-1 border-b border-gray-100">
                                              <span className="text-muted-foreground">{item.date}</span>
                                              <span className="font-medium flex items-center">
                                                <Star className="w-3 h-3 fill-yellow-400 text-yellow-400 mr-1" />
                                                {item.value}
                                              </span>
                                            </div>
                                          ))}
                                        </div>
                                      </div>
                                    )}
                                  </DialogContent>
                                </Dialog>

                                {/* 评论数历史 */}
                                <Dialog>
                                  <DialogTrigger asChild>
                                    <Button
                                      size="sm"
                                      variant="outline"
                                      onClick={() => viewProductHistory(product, 'review_count')}
                                      disabled={loadingHistory}
                                    >
                                      评论数历史
                                    </Button>
                                  </DialogTrigger>
                                  <DialogContent className="max-w-4xl">
                                    <DialogHeader>
                                      <DialogTitle>{product.asin} - 评论数历史</DialogTitle>
                                      <DialogDescription>
                                        查看产品评论数变化趋势和历史数据
                                      </DialogDescription>
                                    </DialogHeader>
                                    {historyData && selectedProduct?.id === product.id && historyData.metric === 'review_count' && (
                                      <div className="mt-4">
                                        <div className="text-sm space-y-1">
                                          {historyData.data?.slice(-10).reverse().map((item: any, index: number) => (
                                            <div key={index} className="flex justify-between py-1 border-b border-gray-100">
                                              <span className="text-muted-foreground">{item.date}</span>
                                              <span className="font-medium">{item.value.toLocaleString()} 条评论</span>
                                            </div>
                                          ))}
                                        </div>
                                      </div>
                                    )}
                                  </DialogContent>
                                </Dialog>

                                {/* Buy Box价格历史 */}
                                <Dialog>
                                  <DialogTrigger asChild>
                                    <Button
                                      size="sm"
                                      variant="outline"
                                      onClick={() => viewProductHistory(product, 'buybox')}
                                      disabled={loadingHistory}
                                    >
                                      Buy Box历史
                                    </Button>
                                  </DialogTrigger>
                                  <DialogContent className="max-w-4xl">
                                    <DialogHeader>
                                      <DialogTitle>{product.asin} - Buy Box价格历史</DialogTitle>
                                      <DialogDescription>
                                        查看Buy Box价格变化趋势和历史数据
                                      </DialogDescription>
                                    </DialogHeader>
                                    {historyData && selectedProduct?.id === product.id && historyData.metric === 'buybox' && (
                                      <div className="mt-4">
                                        <div className="text-sm space-y-1">
                                          {historyData.data?.slice(-10).reverse().map((item: any, index: number) => (
                                            <div key={index} className="flex justify-between py-1 border-b border-gray-100">
                                              <span className="text-muted-foreground">{item.date}</span>
                                              <span className="font-medium">${item.value}</span>
                                            </div>
                                          ))}
                                        </div>
                                      </div>
                                    )}
                                  </DialogContent>
                                </Dialog>
                              </div>
                            </TableCell>
                          </TableRow>
                        ))}
                      </TableBody>
                    </Table>
                  </CardContent>
                </Card>

                {/* 快速统计 */}
                <Card>
                  <CardHeader>
                    <CardTitle>追踪概览</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                      <div className="text-center">
                        <div className="text-2xl font-bold text-blue-600">{tracked.length}</div>
                        <div className="text-sm text-muted-foreground">追踪产品数</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-green-600">
                          {tracked.filter(p => p.status === 'active').length}
                        </div>
                        <div className="text-sm text-muted-foreground">活跃产品</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-orange-600">
                          {tracked.filter(p => p.current_price > 0).length}
                        </div>
                        <div className="text-sm text-muted-foreground">有价格数据</div>
                      </div>
                      <div className="text-center">
                        <div className="text-2xl font-bold text-purple-600">
                          {tracked.filter(p => p.rating && p.rating > 0).length}
                        </div>
                        <div className="text-sm text-muted-foreground">有评分数据</div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* 最新价格变化 */}
                <Card>
                  <CardHeader>
                    <CardTitle>最新价格更新</CardTitle>
                    <CardDescription>
                      显示最近更新的产品价格信息
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      {tracked.filter(p => p.current_price > 0).slice(0, 5).map((product) => (
                        <div key={product.id} className="flex justify-between items-center p-3 bg-gray-50 rounded-lg">
                          <div>
                            <p className="font-medium text-sm">{product.title || product.asin}</p>
                            <p className="text-xs text-muted-foreground">
                              最后更新: {product.last_updated ? new Date(product.last_updated).toLocaleString() : 'N/A'}
                            </p>
                          </div>
                          <div className="text-right">
                            <p className="font-bold text-green-600">
                              {product.currency} {product.current_price.toFixed(2)}
                            </p>
                            {product.rating ? (
                              <p className="text-xs text-muted-foreground">
                                ⭐ {product.rating} ({product.review_count?.toLocaleString() || 0})
                              </p>
                            ) : product.review_count ? (
                              <p className="text-xs text-muted-foreground">
                                暂无评分 ({product.review_count.toLocaleString()} 条评论)
                              </p>
                            ) : null}
                          </div>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>

              </div>
            )}
          </div>
        )

      default:
        return null
    }
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* 左侧边栏 */}
      <div className="w-64 bg-white border-r border-gray-200 flex flex-col">
        <div className="p-6 border-b border-gray-200">
          <h1 className="text-xl font-bold">产品管理中心</h1>
          <p className="text-sm text-muted-foreground">Amazon 产品追踪系统</p>
        </div>

        <nav className="flex-1 p-4">
          <ul className="space-y-2">
            {menuItems.map((item) => {
              const Icon = item.icon
              return (
                <li key={item.id}>
                  <button
                    onClick={() => setActiveTab(item.id)}
                    className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg text-left transition-colors ${
                      activeTab === item.id
                        ? 'bg-blue-100 text-blue-700 border border-blue-200'
                        : 'hover:bg-gray-100 text-gray-700'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    {item.label}
                  </button>
                </li>
              )
            })}
          </ul>
        </nav>

        <div className="p-4 border-t border-gray-200">
          <Button
            onClick={() => router.push('/dashboard')}
            variant="outline"
            className="w-full"
          >
            <Home className="w-4 h-4 mr-2" />
            返回仪表板
          </Button>
        </div>
      </div>

      {/* 主内容区域 */}
      <div className="flex-1 overflow-auto">
        <div className="p-8">
          {renderContent()}
        </div>
      </div>

      {/* 测试价格对话框 */}
      <Dialog open={mockPriceDialogOpen} onOpenChange={setMockPriceDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>添加测试价格</DialogTitle>
            <DialogDescription>
              为产品添加一个测试价格历史记录，用于模拟异常检测场景。
              建议设置与当前价格差异较大的值（超过10%变化）。
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="mock_price">测试价格 (USD)</Label>
              <Input
                id="mock_price"
                type="number"
                step="0.01"
                placeholder="例如: 99.99"
                value={mockPrice}
                onChange={(e) => setMockPrice(e.target.value)}
              />
              <p className="text-xs text-muted-foreground">
                价格变动超过阈值时会触发异常检测。建议输入与当前价格相差10%以上的价格。
              </p>
            </div>
            <div className="flex gap-3">
              <Button
                onClick={addMockPriceHistory}
                disabled={addingMockPrice || !mockPrice}
                className="flex-1"
              >
                {addingMockPrice ? (
                  <>
                    <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                    添加中...
                  </>
                ) : (
                  <>
                    <TestTube className="w-4 h-4 mr-2" />
                    添加测试价格
                  </>
                )}
              </Button>
              <Button
                variant="outline"
                onClick={() => setMockPriceDialogOpen(false)}
                disabled={addingMockPrice}
              >
                取消
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}