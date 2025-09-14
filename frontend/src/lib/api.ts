import axios from 'axios'
import Cookies from 'js-cookie'

// 创建axios实例 - 通过API Gateway访问
const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_BASE_URL || '/api',
  timeout: 300000, // 5分钟超时，适合Apify搜索
  headers: {
    'Content-Type': 'application/json',
  },
})

// 请求拦截器 - 添加JWT token
api.interceptors.request.use(
  (config) => {
    const token = Cookies.get('access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 响应拦截器 - 处理错误
api.interceptors.response.use(
  (response) => {
    return response
  },
  (error) => {
    if (error.response?.status === 401) {
      // Token过期或无效，清除token并跳转到登录
      Cookies.remove('access_token')
      Cookies.remove('user_info')
      window.location.href = '/auth/login'
    }
    return Promise.reject(error)
  }
)

// API类型定义
export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  email: string
  password: string
  company_name?: string
  plan?: string
}

export interface User {
  id: string
  email: string
  company_name?: string
  plan: string
  is_active: boolean
  created_at: string
}

export interface UserSettings {
  notification_email: boolean
  notification_push: boolean
  timezone: string
  currency: string
  tracking_frequency: string
}

export interface LoginResponse {
  access_token: string
  token_type: string
  expires_in: number
  user: User
}

export interface RegisterResponse {
  message: string
  user_id: string
}

export interface ProfileResponse {
  user: User
  settings: UserSettings
}

export interface APIError {
  error: {
    code: string
    message: string
    details?: Array<{
      field: string
      message: string
    }>
    request_id: string
    retry_after?: number
  }
}

// Auth API
export const authAPI = {
  // 用户登录
  login: (data: LoginRequest): Promise<LoginResponse> =>
    api.post('/auth/login', data).then(res => res.data),

  // 用户注册
  register: (data: RegisterRequest): Promise<RegisterResponse> =>
    api.post('/auth/register', data).then(res => res.data),

  // 获取用户资料
  getProfile: (): Promise<ProfileResponse> =>
    api.get('/auth/users/profile').then(res => res.data),

  // 更新用户资料
  updateProfile: (data: any): Promise<{ message: string }> =>
    api.put('/auth/users/profile', data).then(res => res.data),

  // 用户登出
  logout: (): Promise<{ message: string }> =>
    api.post('/auth/logout').then(res => res.data),
}

// Health check API
export const healthAPI = {
  ping: () => api.get('/ping').then(res => res.data),
  health: () => api.get('/health').then(res => res.data),
}

export default api