# API Rate Limiting Strategy

## API 限流策略

### 限流架構

#### 多層級限流
1. **Gateway 層** → 全局限流，基於 IP 和用戶
2. **服務層** → 各微服務獨立限流
3. **功能層** → 特定 API 端點限流

### 限流規則

#### 基於用戶計劃的限流
```yaml
basic_plan:
  requests_per_minute: 60
  burst_size: 10
  daily_limit: 5000

premium_plan:
  requests_per_minute: 600
  burst_size: 50
  daily_limit: 50000

enterprise_plan:
  requests_per_minute: 6000
  burst_size: 100
  daily_limit: 500000
```

#### 特殊端點限流
```yaml
apify_search:
  requests_per_hour: 10    # Apify 搜索較昂貴
  concurrent_limit: 2

data_refresh:
  requests_per_minute: 30  # 限制刷新頻率
  per_product_cooldown: 300s # 每個產品5分鐘冷卻

bulk_operations:
  requests_per_minute: 10  # 批量操作限制
  max_items_per_request: 50
```

### 實現機制

#### 算法選擇
- **Token Bucket** → 支援突發請求
- **Sliding Window** → 精確時間窗口控制
- **固定窗口** → 簡單計數限制

#### 儲存後端
- **Redis** → 分佈式限流計數
- **內存** → 單機限流 (開發環境)

### 限流響應

#### 觸發限流時
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests",
    "request_id": "req-uuid",
    "retry_after": 60
  }
}
```

#### HTTP Headers
```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1694678460
Retry-After: 60
```

### 監控和告警

#### Prometheus 指標
```
# 限流事件計數
api_rate_limit_exceeded_total{service="product", endpoint="/search", plan="basic"}

# 請求頻率
api_requests_per_second{service="product", endpoint="/track"}

# 限流剩餘配額
api_rate_limit_remaining{user_id="uuid", plan="premium"}
```

#### 告警規則
- **高限流率** → 超過10%請求被限流
- **異常流量** → 單用戶請求量異常
- **服務降級** → 限流導致服務可用性下降

---

**實現位置**: `internal/pkg/middleware/ratelimitMiddleware.go`
**監控工具**: Prometheus + Grafana
**最後更新**: 2025-09-13