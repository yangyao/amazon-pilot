import api from './api'

// Product API types
export interface TrackingSettings {
  price_change_threshold?: number
  bsr_change_threshold?: number
  update_frequency?: string
}

export interface AddTrackingRequest {
  asin: string
  alias?: string
  category?: string
  tracking_settings?: TrackingSettings
}

export interface AddTrackingResponse {
  product_id: string
  asin: string
  status: string
  next_update: string
}

export interface TrackedProduct {
  id: string
  product_id: string
  asin: string
  title: string
  alias?: string
  brand?: string
  current_price: number
  currency: string
  bsr: number
  rating: number
  review_count: number
  buy_box_price?: number
  images?: string[]
  last_updated: string
  status: string
}

export interface GetTrackedResponse {
  tracked: TrackedProduct[]
  pagination: {
    page: number
    limit: number
    total: number
    total_pages: number
  }
}

export interface SearchProductsRequest {
  category: string
  max_results?: number
}

export interface SearchProductsResponse {
  success: boolean
  products_count: number
  message: string
  products?: ApifyProductData[]
}

export interface ApifyProductData {
  asin: string
  title: string
  brand?: string
  category?: string
  price: number
  currency: string
  rating?: number
  review_count?: number
  bsr?: number
  bsr_category?: string
  images?: string[]
  description?: string
  bullet_points?: string[]
  availability?: string
  prime?: boolean
  seller?: string
  scraped_at: string
}

// Change Events types
export interface AnomalyEvent {
  id: string
  product_id: string
  asin: string
  event_type: string
  old_value?: number
  new_value?: number
  change_percentage?: number
  threshold?: number
  severity: string
  created_at: string
  product_title?: string
}

export interface GetAnomalyEventsRequest {
  page?: number
  limit?: number
  event_type?: string
  severity?: string
  asin?: string
}

export interface GetAnomalyEventsResponse {
  events: AnomalyEvent[]
  pagination: {
    page: number
    limit: number
    total: number
    total_pages: number
  }
}

// Product API functions
export const productAPI = {
  // 添加产品追踪
  addTracking: (data: AddTrackingRequest): Promise<AddTrackingResponse> =>
    api.post('/product/products/track', data).then(res => res.data),

  // 获取追踪产品列表
  getTracked: (params?: {
    page?: number
    limit?: number
    category?: string
    status?: string
  }): Promise<GetTrackedResponse> =>
    api.get('/product/products/tracked', { params }).then(res => res.data),

  // 停止追踪产品
  stopTracking: (productId: string): Promise<{ message: string }> =>
    api.delete(`/product/products/${productId}/track`).then(res => res.data),

  // 获取产品详情
  getDetails: (productId: string) =>
    api.get(`/product/products/${productId}`).then(res => res.data),

  // 获取产品历史数据
  getHistory: (productId: string, params?: {
    metric?: string
    period?: string
  }) =>
    api.get(`/product/products/${productId}/history`, { params }).then(res => res.data),

  // 搜索产品按类目
  searchProducts: (data: SearchProductsRequest): Promise<SearchProductsResponse> =>
    api.post('/product/search-products', data).then(res => res.data),

  // 刷新产品数据
  refreshData: (productId: string) =>
    api.post(`/product/products/${productId}/refresh`).then(res => res.data),

  // 获取产品历史数据
  getProductHistory: (productId: string, params?: {
    metric?: string  // price, bsr, rating
    period?: string  // 7d, 30d, 90d
  }) =>
    api.get(`/product/products/${productId}/history`, { params }).then(res => res.data),

  // 获取异常变化事件
  getAnomalyEvents: (params?: GetAnomalyEventsRequest): Promise<GetAnomalyEventsResponse> =>
    api.get('/product/products/anomaly-events', { params }).then(res => res.data),
}