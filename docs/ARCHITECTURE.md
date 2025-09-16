# 系統架構設計文件

## 概述

本文件描述 Amazon 賣家產品監控與優化工具的整體系統架構設計，包含後端服務架構、部署拓撲、資料流向和擴展策略。

**實現的核心功能**：
- 產品資料追蹤系統 - 完整實現
- 競品分析引擎 - 完整實現，包含LLM報告生成

## 系統架構概覽

### 設計原則

1. **微服務架構**: 模組化設計，職責明確分離
2. **水平擴展**: 支持服務和資料庫的水平擴展
3. **高可用性**: 消除單點故障，實現故障自動恢復
4. **可觀測性**: 完整的日誌、監控和追踪系統
5. **安全優先**: 多層次安全防護機制

### 核心技術棧

- **後端框架**: Go + go-zero微服務架構
- **ORM**: GORM v2 + 自定義JSON結構化日誌
- **資料庫**: PostgreSQL + Redis (快取層)
- **消息佇列**: Redis + Asynq (異步任務處理)
- **LLM集成**: DeepSeek API (競爭定位報告生成)
- **數據源**: Apify API (Amazon產品數據爬取)
- **前端**: Next.js + React + TypeScript + Tailwind CSS
- **API網關**: 統一路由和認證
- **監控**: Prometheus + Grafana + 結構化JSON日誌
- **部署**: Docker + Docker Compose + GitHub Actions CI/CD

## 📖 API 文檔架構

### go-zero API 定義文件

**重要說明**: 本項目使用 **go-zero .api 文件** 作為 API 文檔，這比傳統的 Swagger 或 Postman Collection 更先進和實用。

#### API 文件架構 (`api/openapi/`)
```
api/openapi/
├── auth.api         # 認證服務 API (2.7KB)
├── product.api      # 產品追蹤 API (8.6KB)
├── competitor.api   # 競品分析 API (6.7KB)
└── optimization.api # 優化建議 API (3.9KB)
```

#### go-zero .api 文件技術優勢

**相比 Swagger/OpenAPI 的優勢**:
- ✅ **單一真實源頭**: API 定義即代碼生成源，避免文檔與代碼不同步
- ✅ **自動代碼生成**: 修改 .api 文件後自動生成 Handler, Types, Routes
- ✅ **類型安全**: 編譯時檢查 API 契約，避免運行時錯誤
- ✅ **簡潔語法**: 比 JSON/YAML 更簡潔易讀
- ✅ **完整配置**: 包含認證、中間件、路由等完整配置

**示例對比**:
```go
// go-zero .api 文件 (簡潔)
type LoginRequest {
    Email    string `json:"email"`
    Password string `json:"password"`
}

@handler login
post /login (LoginRequest) returns (LoginResponse)
```

```yaml
# 傳統 Swagger (冗長)
paths:
  /login:
    post:
      requestBody:
        content:
          application/json:
            schema:
              type: object
              properties:
                email:
                  type: string
                password:
                  type: string
```

#### API 文件完整性

**每個 .api 文件包含**:
- 📋 **完整的類型定義**: Request/Response 結構體
- 🔐 **認證配置**: JWT 和中間件設定
- 🛣️ **路由定義**: RESTful 端點設計
- ✅ **參數驗證**: 內建驗證規則和約束
- 📊 **健康檢查**: 標準的 ping/health 端點

**代碼生成流程**:
```bash
# 修改 API 定義後自動生成代碼
./scripts/goctl-centralized.sh -s product
./scripts/goctl-centralized.sh -s competitor
```

**總計 22KB 的 API 定義文件，涵蓋所有微服務端點，提供比傳統 API 文檔更強大的功能。**

## 微服務架構設計

### 1. API Gateway

**職責**:
- 請求路由和負載均衡
- 統一認證和授權
- Rate limiting 和 API 版本控制
- 請求/回應日誌記錄

### 2. Authentication Service

**職責**:
- 用戶註冊和登入
- JWT token 生成和驗證
- 權限管理
- 用戶資料管理

### 3. Product Tracking Service

**職責**:
- Amazon產品數據抓取和更新 (Apify集成)
- 用戶追蹤設定管理 (固定每日更新)
- 歷史數據存儲 (價格、BSR、評分、評論數歷史)
- 異常變化檢測和警報 (價格變動>10%, BSR變動>30%)
- 產品數據快取管理 (Redis 1小時TTL)

**核心特性**:
- 基於Apify爬蟲的真實Amazon數據
- 異步任務處理 (Worker + Scheduler)
- 多維度異常檢測算法
- 結構化JSON日誌記錄
- 完整的產品特徵數據 (bullet points, images)

### 4. Competitor Analysis Service

**職責**:
- 競品分析組管理（主產品 + 3-5個競品）
- 多維度比較分析（價格、BSR、評分、產品特色）
- LLM驅動的競爭定位報告生成
- 固定每日自動分析調度

**核心特性**:
- 從已追蹤產品選擇主產品和競品 (復用現有數據)
- 利用現有Apify爬蟲數據，避免重複開發
- 固定每日更新頻率（不可用戶配置）
- 使用事務確保分析組和競品關聯的數據一致性
- DeepSeek LLM驅動的競爭定位報告生成

**多維度分析實現**:
- 價格差異分析 - 基於product_price_history真實數據
- BSR排名差距 - 基於product_ranking_history數據
- 評分優劣勢 - 基於評分和評論數歷史
- 產品特色對比 - 基於bullet_points特徵數據
- LLM競爭洞察 - DeepSeek生成的市場定位建議

### 5. Optimization Service

**職責**:
- Listing 優化分析
- OpenAI API 整合
- 優化建議生成
- A/B 測試追蹤

### 6. Notification Service

**職責**:
- 實時通知管理
- 多渠道通知發送 (Email, Push, Webhook)
- 通知模板管理
- 通知歷史記錄

## 資料流向設計

### 1. 產品追蹤資料流

1. 用戶通過前端發起產品追蹤請求
2. API Gateway 驗證請求並轉發至 Product Service
3. Product Service 將任務加入 Asynq 佇列
4. Worker 從佇列取出任務，調用 Apify API 抓取數據
5. 數據存儲至 PostgreSQL，同時更新 Redis 快取
6. 異常檢測模組分析數據變化
7. 觸發條件時通過 Notification Service 發送通知

### 2. 競品分析資料流

1. 用戶選擇主產品和競品創建分析組
2. Competitor Service 驗證產品並建立關聯
3. Scheduler 定時觸發分析任務
4. 系統並行抓取所有產品數據
5. 數據標準化處理後進行多維度比較
6. 調用 DeepSeek API 生成競爭洞察報告
7. 分析結果存儲並推送通知

## 快取與佇列設計

### Redis 快取架構

**快取層級**:
- L1 Cache: 熱門產品基本資料 (TTL: 24小時)
- L2 Cache: 產品歷史資料 (TTL: 1小時)
- L3 Cache: 用戶相關資料 (TTL: 30分鐘)
- Session Cache: 用戶會話 (TTL: 7天)
- Rate Limiting: API 限流 (TTL: 1分鐘)

### 任務佇列設計

**佇列類型**:
- 高優先級佇列: 即時數據刷新、用戶請求
- 普通佇列: 定時更新、批量處理
- 低優先級佇列: 報告生成、數據清理

**任務調度**:
- Cron 排程: 每日固定時間更新
- 即時觸發: 用戶手動刷新
- 重試機制: 失敗任務自動重試3次

## 部署架構

### 容器化部署

**服務拆分**:
- 每個微服務獨立容器化
- 使用 Alpine Linux 最小化鏡像體積
- 多階段構建優化編譯過程

**編排管理**:
- Docker Compose 本地開發環境
- 生產環境分離配置 (docker-compose.prod.yml)
- 環境變量管理敏感配置

### 水平擴展策略

**負載均衡**:
- Caddy 反向代理分發請求
- 最少連接數算法
- 健康檢查自動剔除故障節點

**自動擴展**:
- 基於 CPU/記憶體使用率
- 佇列長度觸發 Worker 擴展
- 數據庫連接池動態調整

## 監控與維運設計

### 監控指標

**系統指標**:
- CPU 使用率
- 記憶體使用率
- 磁碟 I/O
- 網路流量

**應用指標**:
- API 回應時間
- 錯誤率
- 請求吞吐量
- 佇列長度

**業務指標**:
- 產品追蹤數量
- 分析完成率
- 用戶活躍度
- API 使用量

### 日誌架構

**結構化日誌**:
- JSON 格式統一輸出
- 分級日誌 (DEBUG, INFO, WARN, ERROR)
- 集中式日誌收集 (Loki)
- 關鍵業務操作審計日誌

### 錯誤追蹤與告警

**告警規則**:
- 高錯誤率告警 (>10% 5xx 錯誤)
- 高響應時間告警 (P95 > 1秒)
- 佇列積壓告警 (>1000 待處理任務)
- 數據庫連接池耗盡告警

## 安全性架構

### 傳輸層安全

**Caddy 自動 HTTPS 配置**:
- **自動證書管理**: Caddy 使用 Let's Encrypt 自動申請和續期 SSL 證書
- **多域名 HTTPS**: 支持 amazon-pilot.phpman.top, monitor.*, grafana.* 等子域名
- **HTTP 自動重定向**: 所有 HTTP 請求自動重定向到 HTTPS
- **現代 TLS 配置**: 默認 TLS 1.2+, HTTP/2, 安全密碼套件

**部署配置**:
```caddy
# 生產環境自動 HTTPS (caddy-amazon-pilot.conf)
amazon-pilot.phpman.top {
    handle /api/* {
        reverse_proxy localhost:8080  # Gateway
    }
    handle {
        reverse_proxy localhost:4000  # Frontend
    }
}
```

### API 安全

**認證與授權**:
- **JWT Bearer Token**: 所有保護端點需要有效 JWT
- **用戶資源隔離**: 用戶只能訪問自己的數據 (`WHERE user_id = ?`)
- **Token 自動過期**: 1小時過期時間，增強安全性
- **Rate Limiting**: 基於用戶計劃的 API 限流防護

**輸入驗證與防護**:
- **go-zero 參數驗證**: 自動驗證請求參數格式和類型
- **SQL 注入防護**: GORM ORM 參數化查詢，避免 SQL 拼接
- **ASIN 格式驗證**: 強制 10 位字符長度驗證
- **錯誤信息脫敏**: 不暴露內部系統錯誤詳情

### 資料安全

**敏感資料保護**:
- **密碼加密**: bcrypt 雜湊存儲，不可逆加密
- **API 密鑰管理**: 環境變數管理，不在代碼中硬編碼
- **數據庫連接**: 支援 SSL/TLS 連接加密
- **敏感日誌脫敏**: 日誌中不記錄密碼、Token 等敏感信息

**訪問控制**:
- **用戶數據隔離**: 每個用戶只能訪問自己創建的資源
- **事務完整性**: 使用數據庫事務確保數據一致性
- **外鍵約束**: 確保數據關聯完整性

### 網路安全

**安全防護**:
- **HTTPS 強制加密**: Caddy 自動配置，無需手動管理
- **反向代理**: Caddy 隱藏內部服務端口，提供統一入口
- **訪問日誌**: JSON 格式日誌記錄，便於安全審計
- **服務隔離**: 微服務架構，服務間通過內部網絡通信

## 效能優化策略

### 資料庫優化

**連接池設定**:
- 最大連接數: 100
- 最大空閒連接: 10
- 連接最大生命週期: 1小時

**查詢優化**:
- 索引優化 (ASIN, user_id, created_at)
- 批量操作減少往返
- 預加載關聯數據
- 分頁查詢限制

### 快取優化

**多層快取策略**:
- CDN 靜態資源快取
- Redis 應用層快取
- PostgreSQL 查詢快取
- 本地記憶體快取

## 災難恢復計畫

### 備份策略

**數據備份**:
- 每日全量備份
- 每小時增量備份
- 異地備份存儲
- 30天備份保留

### 故障恢復

**高可用保障**:
- 服務健康檢查
- 自動故障轉移
- 數據主從複製
- 快速回滾機制

## 擴展性規劃

### 水平擴展

**微服務擴展**:
- 各服務獨立擴展
- 無狀態設計
- 負載均衡分發

**數據庫擴展**:
- 讀寫分離
- 分片策略
- 連接池優化

### 垂直擴展

**資源優化**:
- CPU 密集型: 增加核心數
- I/O 密集型: SSD 存儲
- 記憶體密集型: 擴大 RAM