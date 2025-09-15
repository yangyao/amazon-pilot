# API 設計文件

## 概述

本文件定義 Amazon 賣家產品監控與優化工具的 RESTful API 規範，包含路由設計、請求/回應格式、錯誤處理和認證機制。

## API 架構原則

### 設計原則

1. **RESTful 風格**: 使用標準 HTTP 動詞和狀態碼
2. **版本控制**: URL 路徑包含版本號
3. **一致性**: 統一的資料格式和命名規範
4. **安全性**: JWT 認證和 HTTPS 傳輸
5. **可擴展性**: 支持分頁、過濾和排序

### API 基礎路徑

```
https://api-amazon-pilot.com/api/{service}/{resource}
```

### 服務劃分

- `/api/auth` - 認證服務
- `/api/product` - 產品追蹤服務
- `/api/competitor` - 競品分析服務
- `/api/optimization` - 優化建議服務
- `/api/notification` - 通知服務

## 認證與授權

### JWT Token 認證

**Token 結構**:
- Header: 包含 token 類型和簽名算法
- Payload: 用戶 ID、郵箱、角色、過期時間
- Signature: 使用私鑰簽名

**Token 使用**:
```
Authorization: Bearer {jwt_token}
```

**Token 生命週期**:
- Access Token: 24 小時
- Refresh Token: 7 天

### 權限管理

**角色定義**:
- `user`: 普通用戶
- `premium`: 高級用戶
- `admin`: 系統管理員

## 通用回應格式

### 成功回應

```json
{
  "success": true,
  "data": {},
  "message": "Operation successful",
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 錯誤回應

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Error description",
    "details": {}
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 分頁回應

```json
{
  "success": true,
  "data": [],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

## 服務 API 詳細設計

### 1. Authentication Service API

#### 用戶註冊
- **POST** `/api/auth/register`
- 請求: email, password, name
- 回應: user_id, email, created_at

#### 用戶登入
- **POST** `/api/auth/login`
- 請求: email, password
- 回應: access_token, refresh_token, user_info

#### Token 更新
- **POST** `/api/auth/refresh`
- 請求: refresh_token
- 回應: new_access_token, new_refresh_token

#### 獲取用戶資料
- **GET** `/api/auth/profile`
- 需要: JWT Token
- 回應: user_id, email, name, plan_type, created_at

#### 更新用戶資料
- **PUT** `/api/auth/profile`
- 請求: name, preferences
- 回應: updated_user_info

#### 修改密碼
- **POST** `/api/auth/change-password`
- 請求: old_password, new_password
- 回應: success_message

### 2. Product Tracking Service API

#### 添加產品追蹤
- **POST** `/api/product/products/track`
- 請求: asin, threshold_settings
- 回應: tracking_id, product_info, status

#### 獲取追蹤列表
- **GET** `/api/product/products/tracked`
- 查詢: page, pageSize, status, sortBy
- 回應: tracked_products[], pagination_info

#### 獲取產品詳情
- **GET** `/api/product/products/{id}`
- 路徑參數: product_id
- 回應: complete_product_details

#### 獲取歷史數據
- **GET** `/api/product/products/{id}/history`
- 查詢: metric_type, date_range, interval
- 回應: historical_data_points[]

#### 刷新產品數據
- **POST** `/api/product/products/{id}/refresh`
- 路徑參數: product_id
- 回應: refresh_status, updated_data

#### 停止追蹤
- **DELETE** `/api/product/products/{id}/track`
- 路徑參數: product_id
- 回應: success_message

#### 異常事件列表
- **GET** `/api/product/products/anomaly-events`
- 查詢: date_range, severity, product_id
- 回應: anomaly_events[], statistics

#### 按類目搜索
- **POST** `/api/product/search-products-by-category`
- 請求: category, keywords, filters
- 回應: search_results[], total_count

### 3. Competitor Analysis Service API

#### 創建分析組
- **POST** `/api/competitor/analysis`
- 請求: main_product_id, competitor_ids[], analysis_settings
- 回應: analysis_group_id, creation_status

#### 獲取分析組列表
- **GET** `/api/competitor/analysis`
- 查詢: page, pageSize, status
- 回應: analysis_groups[], pagination_info

#### 獲取分析結果
- **GET** `/api/competitor/analysis/{id}`
- 路徑參數: analysis_id
- 回應: comparative_analysis, metrics, insights

#### 生成 LLM 報告
- **POST** `/api/competitor/analysis/{id}/generate-report`
- 路徑參數: analysis_id
- 回應: llm_report, recommendations

#### 添加競品
- **POST** `/api/competitor/analysis/{id}/competitors`
- 請求: competitor_product_ids[]
- 回應: updated_competitor_list

#### 移除競品
- **DELETE** `/api/competitor/analysis/{id}/competitors/{competitor_id}`
- 路徑參數: analysis_id, competitor_id
- 回應: success_message

#### 更新分析設定
- **PUT** `/api/competitor/analysis/{id}/settings`
- 請求: update_frequency, comparison_metrics
- 回應: updated_settings

### 4. Optimization Service API

#### 開始優化分析
- **POST** `/api/optimization/analyze`
- 請求: product_id, optimization_type
- 回應: analysis_id, estimated_time

#### 獲取優化建議
- **GET** `/api/optimization/{id}`
- 路徑參數: optimization_id
- 回應: optimization_suggestions[], score_improvements

#### 標記建議實施
- **POST** `/api/optimization/{id}/implement`
- 請求: suggestion_ids[], implementation_notes
- 回應: implementation_status

#### 獲取優化歷史
- **GET** `/api/optimization/history`
- 查詢: product_id, date_range
- 回應: optimization_history[], performance_metrics

### 5. Notification Service API

#### 獲取通知列表
- **GET** `/api/notification/notifications`
- 查詢: status, type, date_range
- 回應: notifications[], unread_count

#### 標記已讀
- **PUT** `/api/notification/notifications/{id}/read`
- 路徑參數: notification_id
- 回應: success_message

#### 通知設定
- **GET** `/api/notification/settings`
- 回應: notification_preferences

#### 更新通知設定
- **PUT** `/api/notification/settings`
- 請求: email_enabled, push_enabled, notification_types
- 回應: updated_preferences

## 錯誤碼定義

### 系統錯誤 (1xxx)
- `1000`: 內部伺服器錯誤
- `1001`: 資料庫連接錯誤
- `1002`: 外部服務不可用
- `1003`: 服務超時

### 認證錯誤 (2xxx)
- `2000`: 未授權
- `2001`: Token 無效
- `2002`: Token 過期
- `2003`: 權限不足

### 請求錯誤 (3xxx)
- `3000`: 參數無效
- `3001`: 缺少必要參數
- `3002`: 資料格式錯誤
- `3003`: 資源不存在

### 業務錯誤 (4xxx)
- `4000`: 產品已追蹤
- `4001`: 追蹤數量超限
- `4002`: 分析組已存在
- `4003`: 競品數量超限

## API 限流策略

### 限流規則

**基礎限制**:
- 普通用戶: 100 請求/分鐘
- 高級用戶: 500 請求/分鐘
- 管理員: 無限制

**特殊 API 限制**:
- 數據刷新: 10 次/小時
- LLM 報告生成: 5 次/天
- 批量操作: 1 次/分鐘

### 限流回應標頭

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```

## API 版本管理

### 版本策略

- 主版本號在 URL 路徑中指定
- 支持最近兩個主版本
- 棄用通知提前 6 個月發布

### 版本兵容性

- 向後兵容的變更不增加版本號
- 破壞性變更需要新版本
- 棄用功能標記在回應標頭中

## 效能優化

### 回應壓縮

支持 gzip 壓縮，通過請求標頭指定:
```
Accept-Encoding: gzip, deflate
```

### 欄位過濾

使用 `fields` 參數指定返回欄位:
```
GET /api/product/products/123?fields=id,title,price
```

### 批量操作

支持批量請求以減少 API 調用:
```
POST /api/product/products/batch
```

## 安全性考慮

### HTTPS 強制

所有 API 請求必須使用 HTTPS 協議

### CORS 配置

```
Access-Control-Allow-Origin: https://app.amazon-pilot.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

### 輸入驗證

- 所有輸入參數進行嚴格驗證
- SQL 注入防護
- XSS 攻擊防護
- CSRF Token 驗證

## 監控與日誌

### API 監控指標

- 請求量
- 響應時間
- 錯誤率
- 成功率

### 日誌記錄

每個 API 請求記錄:
- 請求 ID
- 用戶 ID
- API 路徑
- HTTP 方法
- 響應狀態
- 響應時間
- IP 地址