# 技術決策說明文件

## 概述

本文件記錄了在開發 Amazon 賣家產品監控與優化工具過程中的重要技術決策，包括技術選型理由、權衡考量和替代方案分析。

## 技術棧選擇

### 1. 後端框架選擇：Go + goZero

**決策理由**:
- **高性能**: Go 編譯型語言特性，提供優異的運行時性能
- **並發優勢**: 原生 goroutine 支持，適合高並發場景
- **微服務架構**: goZero 專為微服務設計，提供完整的微服務工具鏈
- **代碼生成**: goctl 工具自動生成代碼，提高開發效率
- **內建中間件**: 提供限流、熔斷、監控等企業級功能
- **類型安全**: 靜態類型檢查，編譯時發現錯誤
- **部署簡單**: 單一二進制文件，無需運行時環境

**權衡考量**:
- **優點**: 
  - 運行時性能優異
  - 內存使用效率高
  - 並發處理能力強
  - 部署和維護簡單
  - 企業級功能完整
- **缺點**: 
  - AI/ML 整合相對複雜
  - 學習曲線較陡峭
  - 生態系統相對較小

**替代方案**:
- **Node.js + Express.js**: 開發速度快，但並發處理能力有限
- **Java + Spring Boot**: 企業級特性完整，但開發複雜度較高
- **Rust + Actix**: 極高性能，但開發複雜度較高

**實作考量**:
```go
// goZero 配置範例
package main

import (
    "context"
    "net/http"

    "github.com/zeromicro/go-zero/core/conf"
    "github.com/zeromicro/go-zero/core/logx"
    "github.com/zeromicro/go-zero/rest"
    "github.com/zeromicro/go-zero/rest/httpx"
    "github.com/zeromicro/go-zero/rest/middleware"
)

type Config struct {
    rest.RestConf
    Database struct {
        DataSource string
    }
    Redis struct {
        Host string
        Pass string
        Type string
    }
}

func main() {
    var c Config
    conf.MustLoad("config.yaml", &c)
    
    server := rest.MustNewServer(c.RestConf)
    defer server.Stop()
    
    // 中間件配置
    server.Use(middleware.NewCorsMiddleware().Handle)
    server.Use(middleware.NewRecoverMiddleware().Handle)
    server.Use(middleware.NewLogMiddleware().Handle)
    
    // 全域異常處理
    server.Use(func(next http.HandlerFunc) http.HandlerFunc {
        return func(w http.ResponseWriter, r *http.Request) {
            defer func() {
                if err := recover(); err != nil {
                    logx.Errorf("Panic recovered: %v", err)
                    httpx.WriteJson(w, http.StatusInternalServerError, map[string]interface{}{
                        "error": map[string]interface{}{
                            "code":    "INTERNAL_ERROR",
                            "message": "Internal server error",
                        },
                    })
                }
            }()
            next(w, r)
        }
    })
    
    server.Start()
}
```

### 2. 資料庫選擇：Supabase (PostgreSQL)

**決策理由**:
- **功能完整**: 提供完整的 PostgreSQL 功能
- **內建功能**: 認證、即時訂閱、存儲等開箱即用功能
- **審計日誌**: 內建審計日誌功能，無需額外配置
- **API 自動生成**: 自動生成 RESTful API
- **即時功能**: 支援即時資料同步
- **擴展性**: 支援水平擴展和讀寫分離

**權衡考量**:
- **優點**: 
  - 功能豐富，開發效率高
  - 內建認證和授權
  - 自動 API 生成
  - 即時資料同步
- **缺點**: 
  - 依賴第三方服務
  - 自定義程度相對較低

**替代方案**:
- **自建 PostgreSQL**: 完全控制，但維護成本高
- **AWS RDS**: 雲端原生，但功能相對基礎
- **MongoDB**: 文檔型資料庫，但事務支援較弱

### 3. 快取層選擇：Redis

**決策理由**:
- **高性能**: 記憶體內運算，回應時間極低
- **多用途**: 同時支援快取和消息佇列功能
- **資料結構豐富**: 支援 String、Hash、List、Set 等多種資料結構
- **持久化選項**: 支援 RDB 和 AOF 持久化
- **叢集支援**: 原生支援分散式部署

**快取策略設計**:
```go
// 快取策略實現
package cache

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/go-redis/redis/v8"
    "github.com/zeromicro/go-zero/core/logx"
)

type CacheStrategy struct {
    redis     *redis.Client
    ttlConfig map[string]time.Duration
}

func NewCacheStrategy(redisAddr string) *CacheStrategy {
    rdb := redis.NewClient(&redis.Options{
        Addr:     redisAddr,
        Password: "",
        DB:       0,
    })

    return &CacheStrategy{
        redis: rdb,
        ttlConfig: map[string]time.Duration{
            // 產品基本資料 - 變動較少，長快取
            "productBasic": 24 * time.Hour,
            
            // 價格資料 - 需要準即時，短快取
            "productPrice": 1 * time.Hour,
            
            // 用戶追蹤列表 - 中等頻率變動
            "userTracked": 30 * time.Minute,
            
            // 分析結果 - 計算成本高，長快取
            "analysisResult": 6 * time.Hour,
            
            // API 限流 - 短時間窗口
            "rateLimit": 1 * time.Minute,
        },
    }
}

func (cs *CacheStrategy) GetCacheKey(cacheType, identifier, params string) string {
    if params != "" {
        return fmt.Sprintf("%s:%s:%s", cacheType, identifier, params)
    }
    return fmt.Sprintf("%s:%s", cacheType, identifier)
}

func (cs *CacheStrategy) CacheAside(ctx context.Context, key string, fetchFunction func() (interface{}, error), ttl time.Duration) (interface{}, error) {
    // Cache-aside pattern implementation
    data, err := cs.redis.Get(ctx, key).Result()
    if err == nil {
        var result interface{}
        if err := json.Unmarshal([]byte(data), &result); err == nil {
            return result, nil
        }
    }

    // 快取未命中，執行回調函數
    result, err := fetchFunction()
    if err != nil {
        return nil, err
    }

    if result != nil {
        if err := cs.Set(ctx, key, result, ttl); err != nil {
            logx.Errorf("Failed to set cache: %v", err)
        }
    }

    return result, nil
}

func (cs *CacheStrategy) Set(ctx context.Context, key string, data interface{}, ttl time.Duration) error {
    jsonData, err := json.Marshal(data)
    if err != nil {
        return err
    }

    if ttl == 0 {
        ttl = time.Hour // 預設 1 小時
    }

    return cs.redis.Set(ctx, key, jsonData, ttl).Err()
}
```

### 4. 消息佇列：Asynq (Redis-based)

**決策理由**:
- **Go 原生**: 與 goZero 完美整合，無需語言切換
- **功能完整**: 支援延遲任務、重試機制、優先級、定期任務
- **監控介面**: Asynq Monitor 提供完整的任務監控界面
- **分散式支援**: 原生支援多 Worker 分散式處理
- **高性能**: 基於 Go 的高性能任務處理
- **類型安全**: 強類型任務定義，編譯時檢查

**權衡考量**:
- **優點**: 
  - 與 Go 生態系統完美整合
  - 功能豐富，支援複雜任務調度
  - 監控和調試工具完善
  - 高性能任務處理
  - 類型安全的任務定義
- **缺點**: 
  - 相比專業 MQ 功能略少
  - 記憶體使用相對較高

**替代方案**:
- **RabbitMQ**: 更強大的消息代理，但複雜度較高
- **Apache Kafka**: 適合大規模串流處理，但過於複雜
- **AWS SQS**: 雲端原生，但綁定 AWS 生態
- **RQ (Redis Queue)**: 更輕量，但功能較少

**任務設計模式**:
```go
// Asynq 任務定義與錯誤處理
package tasks

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/hibiken/asynq"
    "github.com/zeromicro/go-zero/core/logx"
)

type TaskProcessor struct {
    client *asynq.Client
    server *asynq.Server
}

type UpdateProductPayload struct {
    ProductID string `json:"product_id"`
    Priority  int    `json:"priority"`
}

type AnalysisPayload struct {
    AnalysisID string `json:"analysis_id"`
}

func NewTaskProcessor(redisAddr string) *TaskProcessor {
    // 創建 Asynq 客戶端
    client := asynq.NewClient(asynq.RedisClientOpt{Addr: redisAddr})
    
    // 創建 Asynq 服務器
    server := asynq.NewServer(
        asynq.RedisClientOpt{Addr: redisAddr},
        asynq.Config{
            Concurrency: 10,
            Queues: map[string]int{
                "critical": 6,
                "default":  3,
                "low":      1,
            },
            StrictPriority: true,
            ErrorHandler: asynq.ErrorHandlerFunc(func(ctx context.Context, task *asynq.Task, err error) {
                logx.Errorf("Task %s failed: %v", task.Type(), err)
            }),
        },
    )
    
    tp := &TaskProcessor{
        client: client,
        server: server,
    }
    
    tp.setupTaskHandlers()
    return tp
}

func (tp *TaskProcessor) setupTaskHandlers() {
    // 產品更新任務
    tp.server.HandleFunc("update_product", tp.handleUpdateProduct)
    
    // 分析任務
    tp.server.HandleFunc("analysis", tp.handleAnalysis)
}

func (tp *TaskProcessor) handleUpdateProduct(ctx context.Context, t *asynq.Task) error {
    var payload UpdateProductPayload
    if err := json.Unmarshal(t.Payload(), &payload); err != nil {
        return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
    }

    logx.Infof("Processing update product task: %s", payload.ProductID)

    // 執行產品更新邏輯
    if err := tp.updateProduct(payload.ProductID); err != nil {
        return fmt.Errorf("update product failed: %v", err)
    }

    logx.Infof("Successfully updated product: %s", payload.ProductID)
    return nil
}

func (tp *TaskProcessor) handleAnalysis(ctx context.Context, t *asynq.Task) error {
    var payload AnalysisPayload
    if err := json.Unmarshal(t.Payload(), &payload); err != nil {
        return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
    }

    logx.Infof("Processing analysis task: %s", payload.AnalysisID)

    // 執行分析邏輯
    if err := tp.performAnalysis(payload.AnalysisID); err != nil {
        return fmt.Errorf("analysis failed: %v", err)
    }

    logx.Infof("Successfully completed analysis: %s", payload.AnalysisID)
    return nil
}

func (tp *TaskProcessor) AddProductUpdateTask(productID string, priority int) error {
    payload := UpdateProductPayload{
        ProductID: productID,
        Priority:  priority,
    }
    
    task, err := asynq.NewTask("update_product", payload)
    if err != nil {
        return err
    }
    
    // 根據優先級選擇隊列
    queue := "default"
    if priority > 5 {
        queue = "critical"
    } else if priority < 2 {
        queue = "low"
    }
    
    _, err = tp.client.Enqueue(task, asynq.Queue(queue))
    return err
}
```

### 5. 外部 API 整合策略

#### Apify 選擇理由

**決策理由**:
- **需求符合**: 題目指定使用 Apify 抓取 Amazon 資料
- **專業性**: 專門針對網路爬蟲和資料擷取
- **可靠性**: 處理反爬蟲機制，提供穩定的資料來源
- **擴展性**: 支援自定義 Actor 和大規模資料抓取

**API 呼叫優化**:
```go
// Apify 服務實現
package apify

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/zeromicro/go-zero/core/logx"
    "github.com/zeromicro/go-zero/rest/httpx"
)

type ApifyService struct {
    client      *httpx.Client
    token       string
    rateLimiter *RateLimiter
}

type ProductData struct {
    ASIN         string  `json:"asin"`
    Title        string  `json:"title"`
    Price        float64 `json:"price"`
    BSR          int     `json:"bsr"`
    Availability string  `json:"availability"`
    Images       []string `json:"images"`
    BulletPoints []string `json:"bulletPoints"`
}

func NewApifyService(token string) *ApifyService {
    return &ApifyService{
        client: httpx.NewClient(),
        token:  token,
        rateLimiter: NewRateLimiter(10, time.Minute), // 每分鐘 10 次請求
    }
}

func (as *ApifyService) GetProductData(ctx context.Context, asin string) (*ProductData, error) {
    // 限流控制
    if err := as.rateLimiter.Wait(ctx); err != nil {
        return nil, fmt.Errorf("rate limit exceeded: %v", err)
    }

    // 調用 Apify API
    url := fmt.Sprintf("https://api.apify.com/v2/acts/apify~amazon-product-scraper/runs/last/dataset/items?token=%s", as.token)
    
    var response []ProductData
    err := as.client.Get(ctx, url, &response)
    if err != nil {
        return nil, fmt.Errorf("failed to get product data: %v", err)
    }

    if len(response) == 0 {
        return nil, fmt.Errorf("no product data found for ASIN: %s", asin)
    }

    return &response[0], nil
}
```

#### OpenAI API 整合

**決策理由**:
- **AI 能力**: 提供強大的自然語言處理能力
- **分析功能**: 適合產品分析和優化建議生成
- **API 穩定**: 可靠的 API 服務和文檔
- **成本效益**: 按使用量計費，適合中小型應用

**整合實現**:
```go
// OpenAI 服務實現
package openai

import (
    "context"
    "encoding/json"
    "fmt"

    "github.com/zeromicro/go-zero/core/logx"
    "github.com/zeromicro/go-zero/rest/httpx"
)

type OpenAIService struct {
    client *httpx.Client
    apiKey string
    model  string
}

type OptimizationRequest struct {
    ProductTitle    string   `json:"product_title"`
    CurrentPrice    float64  `json:"current_price"`
    CompetitorData  []CompetitorData `json:"competitor_data"`
    Category        string   `json:"category"`
}

type OptimizationResponse struct {
    Suggestions []string `json:"suggestions"`
    PriceRecommendation float64 `json:"price_recommendation"`
    TitleOptimization string `json:"title_optimization"`
}

func NewOpenAIService(apiKey string) *OpenAIService {
    return &OpenAIService{
        client: httpx.NewClient(),
        apiKey: apiKey,
        model:  "gpt-3.5-turbo",
    }
}

func (os *OpenAIService) GenerateOptimizationSuggestions(ctx context.Context, req *OptimizationRequest) (*OptimizationResponse, error) {
    prompt := os.buildOptimizationPrompt(req)
    
    requestBody := map[string]interface{}{
        "model": os.model,
        "messages": []map[string]string{
            {
                "role":    "system",
                "content": "You are an Amazon product optimization expert. Provide actionable suggestions for improving product listings.",
            },
            {
                "role":    "user",
                "content": prompt,
            },
        },
        "max_tokens": 1000,
        "temperature": 0.7,
    }

    var response struct {
        Choices []struct {
            Message struct {
                Content string `json:"content"`
            } `json:"message"`
        } `json:"choices"`
    }

    err := os.client.Post(ctx, "https://api.openai.com/v1/chat/completions", requestBody, &response)
    if err != nil {
        return nil, fmt.Errorf("failed to call OpenAI API: %v", err)
    }

    if len(response.Choices) == 0 {
        return nil, fmt.Errorf("no response from OpenAI")
    }

    // 解析回應
    var optimizationResp OptimizationResponse
    if err := json.Unmarshal([]byte(response.Choices[0].Message.Content), &optimizationResp); err != nil {
        return nil, fmt.Errorf("failed to parse OpenAI response: %v", err)
    }

    return &optimizationResp, nil
}

func (os *OpenAIService) buildOptimizationPrompt(req *OptimizationRequest) string {
    return fmt.Sprintf(`
        Analyze the following Amazon product and provide optimization suggestions:
        
        Product Title: %s
        Current Price: $%.2f
        Category: %s
        
        Competitor Analysis:
        %+v
        
        Please provide:
        1. Price optimization recommendations
        2. Title improvement suggestions
        3. General listing optimization tips
    `, req.ProductTitle, req.CurrentPrice, req.Category, req.CompetitorData)
}
```

## 架構設計決策

### 1. 微服務架構

**決策理由**:
- **可擴展性**: 各服務可獨立擴展
- **技術多樣性**: 不同服務可使用不同技術棧
- **故障隔離**: 單一服務故障不影響整體系統
- **團隊協作**: 不同團隊可獨立開發不同服務

**服務劃分**:
- **API Gateway**: 統一入口，路由和認證
- **Auth Service**: 用戶認證和授權
- **Product Service**: 產品資料管理
- **Analysis Service**: 競品分析和優化建議
- **Notification Service**: 通知發送

### 2. 資料一致性策略

**決策理由**:
- **最終一致性**: 適合高並發場景
- **事件驅動**: 通過事件確保資料同步
- **補償機制**: 提供資料修復能力

**實現方式**:
- **Saga 模式**: 分散式事務管理
- **事件溯源**: 記錄所有狀態變更
- **CQRS**: 讀寫分離，提升性能

### 3. 監控和日誌

**決策理由**:
- **可觀測性**: 完整的系統監控
- **故障診斷**: 快速定位問題
- **性能優化**: 識別性能瓶頸

**技術選型**:
- **Prometheus**: 指標收集
- **Grafana**: 監控面板
- **ELK Stack**: 日誌聚合和分析
- **Jaeger**: 分散式追踪

## 性能優化決策

### 1. 快取策略

**多層次快取**:
- **L1 快取**: 應用內存快取
- **L2 快取**: Redis 快取
- **L3 快取**: 資料庫查詢優化

**快取更新策略**:
- **Cache-Aside**: 應用控制快取
- **Write-Through**: 同步寫入快取和資料庫
- **Write-Behind**: 異步寫入資料庫

### 2. 資料庫優化

**索引策略**:
- **複合索引**: 多欄位查詢優化
- **部分索引**: 條件查詢優化
- **函數索引**: 計算欄位索引

**查詢優化**:
- **分頁查詢**: 避免大量資料載入
- **預計算**: 複雜計算結果快取
- **讀寫分離**: 查詢和更新分離

### 3. API 優化

**限流策略**:
- **令牌桶**: 平滑限流
- **滑動窗口**: 精確限流
- **分層限流**: 用戶和系統級限流

**回應優化**:
- **壓縮**: Gzip 壓縮
- **快取**: HTTP 快取頭
- **CDN**: 靜態資源加速

## 安全決策

### 1. 認證和授權

**JWT Token**:
- **無狀態**: 服務器不存儲會話
- **自包含**: Token 包含用戶信息
- **過期機制**: 自動過期和刷新

**RBAC 模型**:
- **角色定義**: 明確的角色權限
- **資源保護**: API 和資料保護
- **動態權限**: 運行時權限檢查

### 2. 資料保護

**加密策略**:
- **傳輸加密**: HTTPS/TLS
- **存儲加密**: 敏感資料加密
- **密碼加密**: bcrypt 加密

**隱私保護**:
- **資料脫敏**: 敏感資料處理
- **訪問日誌**: 完整的訪問記錄
- **合規性**: 符合資料保護法規

## 部署和運維決策

### 1. 容器化

**Docker**:
- **環境一致性**: 開發和生產環境一致
- **快速部署**: 容器化部署
- **資源隔離**: 進程和資源隔離

**Kubernetes**:
- **自動擴展**: 根據負載自動擴展
- **服務發現**: 自動服務註冊和發現
- **滾動更新**: 零停機更新

### 2. CI/CD

**持續集成**:
- **自動測試**: 代碼提交自動測試
- **代碼質量**: 靜態分析和代碼檢查
- **構建優化**: 並行構建和快取

**持續部署**:
- **自動部署**: 測試通過自動部署
- **藍綠部署**: 零停機部署
- **回滾機制**: 快速回滾能力

## 總結

本技術決策文件記錄了 Amazon 賣家產品監控與優化工具的核心技術選型和架構決策。通過選擇 Go + goZero 作為後端框架，Supabase 作為資料庫，Redis 作為快取和消息佇列，以及 Asynq 作為任務處理器，我們構建了一個高性能、可擴展、易維護的系統架構。

這些決策充分考慮了系統的性能需求、可擴展性要求、開發效率和維護成本，為系統的長期發展奠定了堅實的技術基礎。
