import api from './api'

// 竞品分析API类型定义
export interface CreateAnalysisRequest {
  name: string
  description?: string
  main_product_id: string
  competitor_product_ids: string[]
  analysis_metrics?: string[]
}

export interface CreateAnalysisResponse {
  id: string
  name: string
  main_product_id: string
  status: string
  created_at: string
}

export interface ListAnalysisGroupsRequest {
  page?: number
  limit?: number
  status?: string
}

export interface AnalysisGroup {
  id: string
  name: string
  description: string
  main_product_asin: string
  competitor_count: number
  status: string
  last_analysis: string
  created_at: string
}

export interface ListAnalysisGroupsResponse {
  groups: AnalysisGroup[]
  pagination: {
    page: number
    limit: number
    total: number
    total_pages: number
  }
}

export interface GetAnalysisResultsResponse {
  id: string
  name: string
  description: string
  main_product: {
    id: string
    asin: string
    title: string
    brand: string
    price: number
    bsr: number
    rating: number
    review_count: number
  }
  competitors: Array<{
    id: string
    asin: string
    title: string
    brand: string
    price: number
    bsr: number
    rating: number
    review_count: number
  }>
  recommendations: Array<{
    type: string
    priority: string
    title: string
    description: string
    impact: string
  }>
  status: string
  last_updated: string
}

export interface GenerateReportRequest {
  force?: boolean
}

export interface GenerateReportResponse {
  report_id: string
  status: string
  message: string
  started_at: string
}

// 异步生成报告请求和响应
export interface GenerateReportAsyncRequest {
  force?: boolean
}

export interface GenerateReportAsyncResponse {
  task_id: string
  status: string
  message: string
  started_at: string
}

// 获取报告状态响应
export interface GetReportStatusResponse {
  task_id?: string
  report_id?: string
  status: string
  progress?: number
  message?: string
  error_message?: string
  started_at?: string
  completed_at?: string
}

// 竞品分析API函数
export const competitorAPI = {
  // 创建分析组
  createAnalysisGroup: (data: CreateAnalysisRequest): Promise<CreateAnalysisResponse> =>
    api.post('/competitor/analysis', data).then(res => res.data),

  // 列出分析组
  listAnalysisGroups: (params?: ListAnalysisGroupsRequest): Promise<ListAnalysisGroupsResponse> =>
    api.get('/competitor/analysis', { params }).then(res => res.data),

  // 获取分析结果
  getAnalysisResults: (analysisId: string): Promise<GetAnalysisResultsResponse> =>
    api.get(`/competitor/analysis/${analysisId}`).then(res => res.data),

  // 生成LLM报告 (同步)
  generateReport: (analysisId: string, params?: GenerateReportRequest): Promise<GenerateReportResponse> =>
    api.post(`/competitor/analysis/${analysisId}/generate-report`, params || {}).then(res => res.data),

  // 生成LLM报告 (异步)
  generateReportAsync: (analysisId: string, params?: GenerateReportAsyncRequest): Promise<GenerateReportAsyncResponse> =>
    api.post(`/competitor/analysis/${analysisId}/generate-report-async`, params || {}).then(res => res.data),

  // 获取报告生成状态
  getReportStatus: (analysisId: string, taskId?: string): Promise<GetReportStatusResponse> =>
    api.get(`/competitor/analysis/${analysisId}/report-status`, { params: { task_id: taskId } }).then(res => res.data),

  // 添加竞品产品
  addCompetitor: (analysisId: string, data: { asin: string }): Promise<{ message: string }> =>
    api.post(`/competitor/analysis/${analysisId}/competitors`, data).then(res => res.data),
}