'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Loader2, Plus, Search, List, BarChart3, Home, Users, Target, TrendingUp, Clock, Play } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { useToast } from '@/hooks/use-toast'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import Cookies from 'js-cookie'
import { competitorAPI, type CreateAnalysisRequest, type AnalysisGroup, type GetAnalysisResultsResponse } from '@/lib/competitor-api'
import { productAPI } from '@/lib/product-api'

// 表单验证
const createAnalysisSchema = z.object({
  name: z.string().min(1, '分析组名称不能为空'),
  description: z.string().optional(),
  main_product_id: z.string().min(1, '请选择主产品'),
  competitor_product_ids: z.array(z.string()).min(1, '至少添加一个竞品').max(5, '最多添加5个竞品'),
})

type CreateAnalysisForm = z.infer<typeof createAnalysisSchema>

// 清晰的数据类型定义
interface Tracked {
  id: string              // tracked_products.id
  product_id: string      // products.id (用于竞品分析)
  asin: string
  title: string
  current_price: number
  currency: string
  rating: number
  review_count: number
  bsr: number
  status: string
}

// 使用从API文件导入的类型
type AnalysisResult = GetAnalysisResultsResponse

export default function CompetitorsPage() {
  const [tracked, setTracked] = useState<Tracked[]>([])
  const [analysisGroups, setAnalysisGroups] = useState<AnalysisGroup[]>([])
  const [selectedAnalysis, setSelectedAnalysis] = useState<AnalysisResult | null>(null)
  const [loading, setLoading] = useState(true)
  const [creating, setCreating] = useState(false)
  const [generating, setGenerating] = useState<{[key: string]: boolean}>({})
  const [generatingAsync, setGeneratingAsync] = useState<{[key: string]: boolean}>({})
  const [reportStatus, setReportStatus] = useState<{[key: string]: any}>({})
  const [activeTab, setActiveTab] = useState('groups')
  const router = useRouter()
  const { toast } = useToast()

  // 表单处理
  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors },
  } = useForm<CreateAnalysisForm>({
    resolver: zodResolver(createAnalysisSchema),
    defaultValues: {
      competitor_product_ids: [],
    }
  })

  const selectedCompetitors = watch('competitor_product_ids') || []

  const menuItems = [
    { id: 'groups', label: '分析组', icon: List },
    { id: 'create', label: '创建分析', icon: Plus },
    { id: 'reports', label: '分析报告', icon: BarChart3 },
    { id: 'insights', label: '竞争洞察', icon: TrendingUp },
  ]

  useEffect(() => {
    console.log('CompetitorsPage useEffect triggered, activeTab:', activeTab)
    const token = Cookies.get('access_token')
    if (!token) {
      router.push('/auth/login')
      return
    }

    loadTracked()
    if (activeTab === 'groups') {
      console.log('Calling loadAnalysisGroups because activeTab is groups')
      loadAnalysisGroups()
    }
  }, [router, activeTab])

  const loadTracked = async () => {
    try {
      const response = await productAPI.getTracked()
      setTracked(response.tracked || [])
    } catch (error) {
      console.error('Failed to load tracked:', error)
    }
  }

  const loadAnalysisGroups = async () => {
    console.log('Loading analysis groups...')
    try {
      const response = await competitorAPI.listAnalysisGroups()
      console.log('Analysis groups response:', response)
      setAnalysisGroups(response.groups || [])
    } catch (error) {
      console.error('Failed to load analysis groups:', error)
    } finally {
      setLoading(false)
    }
  }

  const onSubmit = async (data: CreateAnalysisForm) => {
    setCreating(true)
    try {
      await competitorAPI.createAnalysisGroup({
        name: data.name,
        description: data.description,
        main_product_id: data.main_product_id,
        competitor_product_ids: data.competitor_product_ids,
        analysis_metrics: ['price', 'bsr', 'rating', 'features'],
      })
        toast({
          title: "创建成功",
          description: `竞品分析组 "${data.name}" 已创建`,
        })

        reset()
        setActiveTab('groups')
        await loadAnalysisGroups()
    } catch (error: any) {
      toast({
        title: "创建失败",
        description: error.message || "创建竞品分析组失败",
        variant: "destructive"
      })
    } finally {
      setCreating(false)
    }
  }

  const toggleCompetitor = (productId: string) => {
    const current = selectedCompetitors
    if (current.includes(productId)) {
      setValue('competitor_product_ids', current.filter(id => id !== productId))
    } else if (current.length < 5) {
      setValue('competitor_product_ids', [...current, productId])
    } else {
      toast({
        title: "超出限制",
        description: "最多只能添加5个竞品",
        variant: "destructive"
      })
    }
  }

  const generateReport = async (analysisId: string, groupName: string, force: boolean = false) => {
    setGenerating(prev => ({ ...prev, [analysisId]: true }))

    try {
      const data = await competitorAPI.generateReport(analysisId, { force })
      toast({
        title: force ? "报告重新生成中" : "报告生成中",
        description: `"${groupName}" 的竞争定位报告正在${force ? '重新' : ''}生成中，将自动更新状态`,
      })

      // 开始轮询报告状态（每5秒检查一次，最多2分钟）
      let attempts = 0
      const maxAttempts = 24 // 2分钟
      const pollInterval = setInterval(async () => {
        attempts++
        try {
          const result = await competitorAPI.getAnalysisResults(analysisId)
          if (result.status === 'completed') {
            clearInterval(pollInterval)
            toast({
              title: "报告生成完成",
              description: `"${groupName}" 的竞争定位报告已${force ? '重新' : ''}生成完成`,
            })
            // 刷新分析组列表
            if (activeTab === 'groups') {
              await loadAnalysisGroups()
            }
          } else if (result.status === 'failed' || attempts >= maxAttempts) {
            clearInterval(pollInterval)
            toast({
              title: "报告生成失败",
              description: result.status === 'failed' ? "LLM报告生成过程中出现错误" : "报告生成超时",
              variant: "destructive"
            })
          }
        } catch (error) {
          console.error('Poll error:', error)
        }

        if (attempts >= maxAttempts) {
          clearInterval(pollInterval)
        }
      }, 5000)

    } catch (error: any) {
      toast({
        title: "生成失败",
        description: error.response?.data?.error?.message || error.message || "生成竞争定位报告失败",
        variant: "destructive"
      })
    } finally {
      setGenerating(prev => ({ ...prev, [analysisId]: false }))
    }
  }

  // 异步生成报告
  const generateReportAsync = async (analysisId: string, groupName: string, force: boolean = false) => {
    setGeneratingAsync(prev => ({ ...prev, [analysisId]: true }))

    try {
      const data = await competitorAPI.generateReportAsync(analysisId, { force })
      toast({
        title: force ? "异步重新生成任务已提交" : "异步任务已提交",
        description: `"${groupName}" 的竞争定位报告${force ? '重新' : ''}生成任务已提交到后台队列`,
      })

      // 立即开始轮询任务状态
      pollReportStatus(analysisId, data.task_id, groupName, force)

    } catch (error: any) {
      toast({
        title: "提交失败",
        description: error.response?.data?.error?.message || error.message || "提交异步生成任务失败",
        variant: "destructive"
      })
      setGeneratingAsync(prev => ({ ...prev, [analysisId]: false }))
    }
  }

  // 轮询报告状态
  const pollReportStatus = (analysisId: string, taskId: string, groupName: string, force: boolean = false) => {
    const pollInterval = setInterval(async () => {
      try {
        const status = await competitorAPI.getReportStatus(analysisId, taskId)
        setReportStatus(prev => ({ ...prev, [analysisId]: status }))

        if (status.status === 'completed') {
          clearInterval(pollInterval)
          setGeneratingAsync(prev => ({ ...prev, [analysisId]: false }))
          toast({
            title: "报告生成完成",
            description: `"${groupName}" 的竞争定位报告已异步${force ? '重新' : ''}生成完成`,
          })
          // 刷新分析组列表
          if (activeTab === 'groups') {
            await loadAnalysisGroups()
          }
        } else if (status.status === 'failed') {
          clearInterval(pollInterval)
          setGeneratingAsync(prev => ({ ...prev, [analysisId]: false }))
          toast({
            title: "报告生成失败",
            description: status.error_message || "异步报告生成失败",
            variant: "destructive"
          })
        }
      } catch (error) {
        console.error('Poll report status error:', error)
      }
    }, 5000) // 每5秒轮询一次

    // 5分钟后停止轮询
    setTimeout(() => {
      clearInterval(pollInterval)
      setGeneratingAsync(prev => ({ ...prev, [analysisId]: false }))
    }, 300000)
  }

  const viewAnalysisResults = async (analysisId: string) => {
    try {
      const data = await competitorAPI.getAnalysisResults(analysisId)
      setSelectedAnalysis(data)
      setActiveTab('reports')
    } catch (error: any) {
      toast({
        title: "获取失败",
        description: error.message || "获取分析结果失败",
        variant: "destructive"
      })
    }
  }

  const renderContent = () => {
    switch (activeTab) {
      case 'groups':
        return (
          <div>
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-2xl font-bold">竞品分析组</h2>
                <p className="text-muted-foreground">管理您的竞品分析组和比较分析</p>
              </div>
              <Button onClick={() => setActiveTab('create')} variant="outline">
                <Plus className="w-4 h-4 mr-2" />
                创建新分析
              </Button>
            </div>

            {loading ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="w-8 h-8 animate-spin" />
              </div>
            ) : analysisGroups.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center">
                  <Users className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground mb-4">还没有创建任何竞品分析组</p>
                  <Button onClick={() => setActiveTab('create')}>
                    开始创建分析组
                  </Button>
                </CardContent>
              </Card>
            ) : (
              <Card>
                <CardHeader>
                  <CardTitle>分析组列表 ({analysisGroups.length})</CardTitle>
                  <CardDescription>
                    每个分析组包含1个主产品和最多5个竞品的对比分析
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>分析组名称</TableHead>
                        <TableHead>主产品ASIN</TableHead>
                        <TableHead>竞品数量</TableHead>
                        <TableHead>状态</TableHead>
                        <TableHead>最后分析</TableHead>
                        <TableHead>操作</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {analysisGroups.map((group) => (
                        <TableRow key={group.id}>
                          <TableCell className="font-medium">{group.name}</TableCell>
                          <TableCell className="font-mono text-sm">{group.main_product_asin}</TableCell>
                          <TableCell>
                            <Badge variant="secondary">{group.competitor_count} 个竞品</Badge>
                          </TableCell>
                          <TableCell>
                            <Badge variant={group.status === 'active' ? 'default' : 'secondary'}>
                              {group.status === 'active' ? '活跃' : '暂停'}
                            </Badge>
                          </TableCell>
                          <TableCell className="text-sm text-muted-foreground">
                            {group.last_analysis ? new Date(group.last_analysis).toLocaleDateString() : '从未'}
                          </TableCell>
                          <TableCell>
                            <div className="flex gap-1">
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => viewAnalysisResults(group.id)}
                                title="查看分析结果"
                              >
                                <BarChart3 className="w-4 h-4" />
                              </Button>
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => generateReport(group.id, group.name, !!group.last_analysis)}
                                disabled={generating[group.id] || generatingAsync[group.id]}
                                title={group.last_analysis ? "同步重新生成报告" : "同步生成报告"}
                              >
                                {generating[group.id] ? (
                                  <Loader2 className="w-4 h-4 animate-spin" />
                                ) : (
                                  <Play className="w-4 h-4" />
                                )}
                              </Button>
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => generateReportAsync(group.id, group.name, !!group.last_analysis)}
                                disabled={generating[group.id] || generatingAsync[group.id]}
                                title={group.last_analysis ? "异步重新生成报告" : "异步生成报告"}
                              >
                                {generatingAsync[group.id] ? (
                                  <Loader2 className="w-4 h-4 animate-spin text-blue-600" />
                                ) : (
                                  <Clock className="w-4 h-4 text-blue-600" />
                                )}
                              </Button>
                            </div>
                            {reportStatus[group.id] && (
                              <div className="mt-1 text-xs text-muted-foreground">
                                {reportStatus[group.id].status === 'queued' && "⏳ 队列等待"}
                                {reportStatus[group.id].status === 'processing' && "🔄 生成中"}
                                {reportStatus[group.id].progress && ` (${reportStatus[group.id].progress}%)`}
                              </div>
                            )}
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

      case 'create':
        return (
          <div>
            <div className="mb-6">
              <h2 className="text-2xl font-bold mb-2">创建竞品分析组</h2>
              <p className="text-muted-foreground">选择主产品进行竞品对比分析</p>
            </div>

            <Card className="max-w-2xl">
              <CardHeader>
                <CardTitle>新建分析组</CardTitle>
                <CardDescription>
                  从已追踪记录中选择主产品，然后添加竞品进行对比分析
                </CardDescription>
              </CardHeader>
              <CardContent>
                <form onSubmit={handleSubmit(onSubmit)} className="space-y-6">
                  <div className="space-y-2">
                    <Label htmlFor="name">分析组名称 *</Label>
                    <Input
                      id="name"
                      placeholder="输入分析组名称"
                      {...register('name')}
                      className={errors.name ? 'border-red-500' : ''}
                    />
                    {errors.name && (
                      <p className="text-sm text-red-500">{errors.name.message}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="main_product_id">主产品 *</Label>
                    <select
                      id="main_product_id"
                      {...register('main_product_id')}
                      className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background"
                    >
                      <option value="">选择主产品</option>
                      {tracked.map((item) => (
                        <option key={item.id} value={item.product_id}>
                          {item.asin} - {item.title || 'N/A'}
                        </option>
                      ))}
                    </select>
                    {errors.main_product_id && (
                      <p className="text-sm text-red-500">{errors.main_product_id.message}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="description">描述 (可选)</Label>
                    <Input
                      id="description"
                      placeholder="分析组描述"
                      {...register('description')}
                    />
                  </div>

                  <div className="space-y-4">
                    <div className="flex items-center justify-between">
                      <Label>选择竞品 ({selectedCompetitors.length}/5)</Label>
                      <Badge variant="outline">从已追踪选择</Badge>
                    </div>

                    <div className="border rounded-lg p-4 max-h-64 overflow-y-auto">
                      {tracked.length === 0 ? (
                        <p className="text-muted-foreground text-center py-4">
                          暂无已追踪记录，请先到产品管理页面添加追踪
                        </p>
                      ) : (
                        <div className="space-y-2">
                          {tracked.map((item) => (
                            <div
                              key={item.id}
                              className={`flex items-center justify-between p-3 border rounded-lg cursor-pointer transition-colors ${
                                selectedCompetitors.includes(item.product_id)
                                  ? 'bg-blue-50 border-blue-200'
                                  : 'hover:bg-gray-50'
                              }`}
                              onClick={() => toggleCompetitor(item.product_id)}
                            >
                              <div>
                                <div className="font-medium">{item.asin}</div>
                                <div className="text-sm text-muted-foreground">
                                  {item.title || 'N/A'} - ${item.current_price}
                                </div>
                              </div>
                              <div className="flex items-center gap-2">
                                <Badge variant="outline">
                                  BSR #{item.bsr?.toLocaleString() || 'N/A'}
                                </Badge>
                                {selectedCompetitors.includes(item.product_id) && (
                                  <Badge variant="default">已选择</Badge>
                                )}
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                    {errors.competitor_product_ids && (
                      <p className="text-sm text-red-500">{errors.competitor_product_ids.message}</p>
                    )}
                  </div>

                  <div className="p-4 bg-blue-50 rounded-lg">
                    <div className="flex items-center justify-between mb-2">
                      <h4 className="font-medium text-blue-800">分析设置</h4>
                      <Badge variant="outline" className="text-blue-700 border-blue-300">
                        固定配置
                      </Badge>
                    </div>
                    <ul className="text-sm text-blue-700 space-y-1">
                      <li>• 更新频率: 每日一次（固定）</li>
                      <li>• 分析维度: 价格差异、BSR排名差距、评分优劣势、产品特色对比</li>
                      <li>• 竞品数量: 3-5个竞品（从已追踪选择）</li>
                      <li>• 报告生成: LLM自动生成竞争定位报告</li>
                    </ul>
                  </div>

                  <div className="flex gap-3">
                    <Button type="submit" disabled={creating} className="flex-1">
                      {creating ? (
                        <>
                          <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                          创建中...
                        </>
                      ) : (
                        <>
                          <Target className="w-4 h-4 mr-2" />
                          创建分析组
                        </>
                      )}
                    </Button>
                    <Button
                      type="button"
                      variant="outline"
                      onClick={() => reset()}
                      disabled={creating}
                    >
                      重置
                    </Button>
                  </div>
                </form>
              </CardContent>
            </Card>
          </div>
        )

      case 'reports':
        return (
          <div>
            <div className="flex justify-between items-center mb-6">
              <div>
                <h2 className="text-2xl font-bold">分析报告</h2>
                <p className="text-muted-foreground">查看LLM生成的竞争定位报告和市场洞察</p>
              </div>
              {selectedAnalysis && (
                <Button onClick={() => { setSelectedAnalysis(null); setActiveTab('groups') }} variant="outline">
                  返回分析组
                </Button>
              )}
            </div>

            {!selectedAnalysis ? (
              <Card>
                <CardContent className="py-8 text-center">
                  <BarChart3 className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground mb-4">请从分析组列表中选择一个分析组查看报告</p>
                  <Button onClick={() => setActiveTab('groups')}>
                    返回分析组列表
                  </Button>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-6">
                {/* 分析组概览 */}
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center justify-between">
                      <span>{selectedAnalysis.name}</span>
                      <Badge variant={selectedAnalysis.status === 'completed' ? 'default' : selectedAnalysis.status === 'processing' ? 'secondary' : 'destructive'}>
                        {selectedAnalysis.status === 'completed' ? '已完成' :
                         selectedAnalysis.status === 'processing' ? '生成中' :
                         selectedAnalysis.status === 'failed' ? '生成失败' :
                         selectedAnalysis.status === 'no_report' ? '未生成报告' : selectedAnalysis.status}
                      </Badge>
                    </CardTitle>
                    <CardDescription>
                      {selectedAnalysis.description || '竞品对比分析'}
                    </CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      <div>
                        <h4 className="font-medium mb-2">主产品</h4>
                        <div className="text-sm space-y-1">
                          <div>ASIN: {selectedAnalysis.main_product?.asin}</div>
                          <div>标题: {selectedAnalysis.main_product?.title || 'N/A'}</div>
                        </div>
                      </div>
                      <div>
                        <h4 className="font-medium mb-2">竞品数量</h4>
                        <div className="text-2xl font-bold text-blue-600">
                          {selectedAnalysis.competitors?.length || 0}
                        </div>
                      </div>
                      <div>
                        <h4 className="font-medium mb-2">最后更新</h4>
                        <div className="text-sm text-muted-foreground">
                          {selectedAnalysis.last_updated ? new Date(selectedAnalysis.last_updated).toLocaleString() : 'N/A'}
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* 竞品列表 */}
                <Card>
                  <CardHeader>
                    <CardTitle>竞品产品列表</CardTitle>
                  </CardHeader>
                  <CardContent>
                    {selectedAnalysis.competitors && selectedAnalysis.competitors.length > 0 ? (
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {selectedAnalysis.competitors.map((competitor: any, index: number) => (
                          <div key={competitor.id} className="border rounded-lg p-4">
                            <div className="font-medium">竞品 {index + 1}</div>
                            <div className="text-sm text-muted-foreground mt-1">
                              <div>ASIN: {competitor.asin}</div>
                              <div>标题: {competitor.title || 'N/A'}</div>
                              <div>品牌: {competitor.brand || 'N/A'}</div>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <p className="text-muted-foreground text-center py-4">暂无竞品数据</p>
                    )}
                  </CardContent>
                </Card>

                {/* LLM分析报告 */}
                {selectedAnalysis.status === 'completed' && selectedAnalysis.recommendations ? (
                  <Card>
                    <CardHeader>
                      <CardTitle className="flex items-center justify-between">
                        <span>LLM竞争定位报告</span>
                        <div className="flex gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => generateReport(selectedAnalysis.id, selectedAnalysis.name, true)}
                            disabled={generating[selectedAnalysis.id] || generatingAsync[selectedAnalysis.id]}
                            title="同步重新生成报告"
                          >
                            {generating[selectedAnalysis.id] ? (
                              <Loader2 className="w-4 h-4 animate-spin" />
                            ) : (
                              <Play className="w-4 h-4" />
                            )}
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => generateReportAsync(selectedAnalysis.id, selectedAnalysis.name, true)}
                            disabled={generating[selectedAnalysis.id] || generatingAsync[selectedAnalysis.id]}
                            title="异步重新生成报告"
                          >
                            {generatingAsync[selectedAnalysis.id] ? (
                              <Loader2 className="w-4 h-4 animate-spin text-blue-600" />
                            ) : (
                              <Clock className="w-4 h-4 text-blue-600" />
                            )}
                          </Button>
                        </div>
                      </CardTitle>
                      <CardDescription>
                        由GPT-4生成的竞争分析和优化建议 •
                        <span className="text-xs text-blue-600 ml-1">点击右上角按钮可重新生成</span>
                      </CardDescription>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-4">
                        {selectedAnalysis.recommendations.map((rec: any, index: number) => (
                          <div key={index} className="border-l-4 border-blue-500 pl-4">
                            <div className="font-medium">{rec.title}</div>
                            <div className="text-sm text-muted-foreground mt-1">{rec.description}</div>
                            <div className="flex gap-2 mt-2">
                              <Badge variant="outline">{rec.type}</Badge>
                              <Badge variant={rec.priority === 'high' ? 'destructive' : rec.priority === 'medium' ? 'secondary' : 'outline'}>
                                {rec.priority}
                              </Badge>
                            </div>
                          </div>
                        ))}
                      </div>
                      {/* 显示重新生成状态 */}
                      {(generating[selectedAnalysis.id] || generatingAsync[selectedAnalysis.id] || reportStatus[selectedAnalysis.id]) && (
                        <div className="mt-6 p-4 bg-gray-50 rounded-lg">
                          <div className="flex items-center gap-3">
                            {(generating[selectedAnalysis.id] || generatingAsync[selectedAnalysis.id]) && (
                              <Loader2 className="w-5 h-5 animate-spin text-blue-600" />
                            )}
                            <div className="flex-1">
                              {generating[selectedAnalysis.id] && (
                                <div className="text-sm font-medium text-blue-800">正在同步生成新报告...</div>
                              )}
                              {generatingAsync[selectedAnalysis.id] && reportStatus[selectedAnalysis.id] && (
                                <div className="text-sm font-medium text-blue-800">
                                  异步生成中: {reportStatus[selectedAnalysis.id].message}
                                  {reportStatus[selectedAnalysis.id].progress && ` (${reportStatus[selectedAnalysis.id].progress}%)`}
                                </div>
                              )}
                              {generatingAsync[selectedAnalysis.id] && !reportStatus[selectedAnalysis.id] && (
                                <div className="text-sm font-medium text-blue-800">异步任务已提交到后台队列...</div>
                              )}
                            </div>
                          </div>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                ) : selectedAnalysis.status === 'processing' ? (
                  <Card>
                    <CardContent className="py-8 text-center">
                      <Loader2 className="w-12 h-12 mx-auto mb-4 animate-spin text-blue-600" />
                      <p className="text-muted-foreground mb-4">LLM正在生成竞争定位报告...</p>
                      <p className="text-sm text-muted-foreground">
                        GPT-4正在分析价格差异、BSR排名差距、评分优劣势等多维度数据
                      </p>
                    </CardContent>
                  </Card>
                ) : selectedAnalysis.status === 'failed' ? (
                  <Card>
                    <CardContent className="py-8 text-center">
                      <div className="text-red-500 mb-4">
                        <TrendingUp className="w-12 h-12 mx-auto mb-2" />
                        <p className="font-medium">报告生成失败</p>
                      </div>
                      <p className="text-muted-foreground mb-4">
                        LLM报告生成过程中出现错误，请重新尝试生成
                      </p>
                      <div className="flex gap-2 justify-center">
                        <Button
                          onClick={() => generateReport(selectedAnalysis.id, selectedAnalysis.name, true)}
                          disabled={generating[selectedAnalysis.id] || generatingAsync[selectedAnalysis.id]}
                          variant="outline"
                        >
                          {generating[selectedAnalysis.id] ? (
                            <>
                              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                              重新生成中...
                            </>
                          ) : (
                            <>
                              <Play className="w-4 h-4 mr-2" />
                              同步重新生成
                            </>
                          )}
                        </Button>
                        <Button
                          onClick={() => generateReportAsync(selectedAnalysis.id, selectedAnalysis.name, true)}
                          disabled={generating[selectedAnalysis.id] || generatingAsync[selectedAnalysis.id]}
                          variant="outline"
                        >
                          {generatingAsync[selectedAnalysis.id] ? (
                            <>
                              <Loader2 className="w-4 h-4 mr-2 animate-spin text-blue-600" />
                              异步生成中...
                            </>
                          ) : (
                            <>
                              <Clock className="w-4 h-4 mr-2 text-blue-600" />
                              异步重新生成
                            </>
                          )}
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ) : (
                  <Card>
                    <CardContent className="py-8 text-center">
                      <BarChart3 className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                      <p className="text-muted-foreground mb-4">暂无分析报告</p>
                      <div className="flex gap-2 justify-center">
                        <Button
                          onClick={() => generateReport(selectedAnalysis.id, selectedAnalysis.name)}
                          disabled={generating[selectedAnalysis.id] || generatingAsync[selectedAnalysis.id]}
                        >
                          {generating[selectedAnalysis.id] ? (
                            <>
                              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                              生成中...
                            </>
                          ) : (
                            <>
                              <Play className="w-4 h-4 mr-2" />
                              立即生成报告
                            </>
                          )}
                        </Button>
                        <Button
                          onClick={() => generateReportAsync(selectedAnalysis.id, selectedAnalysis.name)}
                          disabled={generating[selectedAnalysis.id] || generatingAsync[selectedAnalysis.id]}
                          variant="outline"
                        >
                          {generatingAsync[selectedAnalysis.id] ? (
                            <>
                              <Loader2 className="w-4 h-4 mr-2 animate-spin text-blue-600" />
                              异步生成中...
                            </>
                          ) : (
                            <>
                              <Clock className="w-4 h-4 mr-2 text-blue-600" />
                              异步生成报告
                            </>
                          )}
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                )}
              </div>
            )}
          </div>
        )

      case 'insights':
        return (
          <div>
            <h2 className="text-2xl font-bold mb-6">竞争洞察</h2>
            <Card>
              <CardContent className="py-8 text-center">
                <TrendingUp className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                <p className="text-muted-foreground mb-4">竞争洞察功能开发中</p>
                <p className="text-sm text-muted-foreground">
                  将显示市场趋势分析、竞争态势变化、优化建议等深度洞察
                </p>
              </CardContent>
            </Card>
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
          <h1 className="text-xl font-bold">竞品分析中心</h1>
          <p className="text-sm text-muted-foreground">Amazon 竞品对比分析</p>
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
    </div>
  )
}