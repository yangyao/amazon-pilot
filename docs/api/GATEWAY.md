# API Gateway Design

## API Gateway 路由設計

### Gateway 架構

#### 核心職責
1. **統一入口** → 所有客戶端請求的單一入口點
2. **服務路由** → 基於路徑前綴自動路由到微服務
3. **橫切關注** → 認證、限流、日誌、監控
4. **協議轉換** → HTTP 到各種後端協議

#### 技術實現
- **語言**: Go with net/http
- **路由策略**: 前綴匹配 + 反向代理
- **配置驅動**: YAML 配置檔案

### 服務路由規則

#### 路由映射
```yaml
services:
  auth: "http://localhost:8001"
  product: "http://localhost:8002"
  competitor: "http://localhost:8003"
  optimization: "http://localhost:8004"
  notification: "http://localhost:8005"
```

#### 路由邏輯
```
請求路徑解析:
/api/product/products/track → product 服務
/api/auth/login → auth 服務
/api/competitor/analysis → competitor 服務

路由規則:
1. 提取服務名: /api/{service}/...
2. 查找服務映射: services[service]
3. 代理到目標服務: http://localhost:800x
```

### 中間件處理鏈

#### 請求處理順序
```
客戶端請求
    ↓
1. CORS 處理
    ↓
2. 請求日誌記錄
    ↓
3. Rate Limiting
    ↓
4. 路由解析
    ↓
5. 服務代理
    ↓
6. 響應日誌記錄
    ↓
客戶端響應
```

#### 中間件配置
```go
// Gateway 中間件棧
mux.HandleFunc("/api/", withMiddleware(
    corsMiddleware(),
    loggingMiddleware(),
    rateLimitMiddleware(),
    routingHandler(),
))
```

### 錯誤處理

#### Gateway 層錯誤
```json
{
  "error": {
    "code": "GATEWAY_ERROR",
    "message": "Service not available",
    "request_id": "req-uuid"
  }
}
```

#### 常見錯誤情況
- **404** → 服務名稱不存在
- **502** → 後端服務不可用
- **504** → 後端服務超時
- **429** → Gateway 層限流

### 監控和可觀測性

#### 指標收集
```prometheus
# 請求計數
gateway_requests_total{service, method, status}

# 響應時間
gateway_request_duration_seconds{service, method}

# 錯誤率
gateway_errors_total{service, error_type}

# 服務健康狀態
gateway_service_up{service}
```

#### 日誌格式
```json
{
  "timestamp": "2025-09-13T10:00:00Z",
  "level": "info",
  "service": "api-gateway",
  "request_id": "req-uuid",
  "method": "POST",
  "path": "/api/product/search",
  "target_service": "product",
  "status": 200,
  "duration_ms": 1250,
  "user_id": "user-uuid"
}
```

### 超時配置

#### 服務超時設定
```go
proxy.Transport = &http.Transport{
    ResponseHeaderTimeout: 10 * time.Minute, // 適合 Apify 搜索
    IdleConnTimeout:       15 * time.Minute,
    DialTimeout:          30 * time.Second,
}
```

#### 超時策略
- **健康檢查** → 5秒
- **一般API** → 30秒
- **Apify搜索** → 10分鐘
- **數據刷新** → 5分鐘

### 安全配置

#### CORS 設定
```go
w.Header().Set("Access-Control-Allow-Origin", "http://localhost:4000")
w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
w.Header().Set("Access-Control-Allow-Credentials", "true")
```

#### 安全頭部
- **X-Content-Type-Options**: nosniff
- **X-Frame-Options**: DENY
- **X-XSS-Protection**: 1; mode=block

---

**配置文件**: `cmd/gateway/etc/gateway.yaml`
**服務實現**: `cmd/gateway/main.go`
**監控**: Prometheus metrics on `:8080/metrics`
**最後更新**: 2025-09-13