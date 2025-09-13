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
  asin: string
  title?: string
  alias?: string
  current_price: number
  currency: string
  bsr?: number
  rating?: number
  review_count: number
  buy_box_price?: number
  last_updated: string
  status: string
}

export interface GetTrackedResponse {
  products: TrackedProduct[]
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
    api.post('/product/track', data).then(res => res.data),

  // 获取追踪产品列表
  getTracked: (params?: {
    page?: number
    limit?: number
    category?: string
    status?: string
  }): Promise<GetTrackedResponse> =>
    api.get('/product/tracked', { params }).then(res => res.data),

  // 停止追踪产品
  stopTracking: (productId: string): Promise<{ message: string }> =>
    api.delete(`/product/${productId}/track`).then(res => res.data),

  // 获取产品详情
  getDetails: (productId: string) =>
    api.get(`/product/${productId}`).then(res => res.data),

  // 获取产品历史数据
  getHistory: (productId: string, params?: {
    metric?: string
    period?: string
  }) =>
    api.get(`/product/${productId}/history`, { params }).then(res => res.data),
}