# 系統架構圖文件

## 概述

本文件包含 Amazon 賣家產品監控與優化工具的各種架構圖表，展示系統的整體設計、資料流向和部署拓撲。內容已對齊目前的程式碼與 Docker Compose 部署現狀（單一 API Gateway、Caddy 反向代理、Redis+Asynq 任務、Loki/Promtail 日誌管線，無 K8s/ELK/Jaeger）。

## 1. 系統整體架構圖（與現狀一致）

```mermaid
graph TB
    %% 用戶層
    subgraph "用戶層"
        U1[Amazon 賣家]
        U2[管理員]
    end

    %% 接入層（本地用容器Caddy；生產用物理機Caddy）
    subgraph "接入層"
        CADDY[Caddy 反向代理<br/>/api -> Gateway<br/>/ -> Frontend]
        CDN[CDN<br/>靜態資源]
    end

    %% API 閘道層（單實例）
    subgraph "API 閘道層"
        AG[API Gateway]
    end

    %% 服務層（按實作）
    subgraph "服務層"
        AS[認證服務 Auth]
        PS[產品服務 Product]
        CS[競品服務 Competitor]
        OS[優化服務 Optimization]
        WK[Worker (Asynq)]
        SCH[Scheduler (Asynq)]
        DASH[Asynq Dashboard]
    end

    %% 資料層
    subgraph "資料層"
        DB[(PostgreSQL / Supabase)]
        REDIS[(Redis<br/>快取 & Asynq佇列)]
    end

    %% 外部服務層
    subgraph "外部服務"
        APIFY[Apify API<br/>資料擷取]
        OPENAI[OpenAI API<br/>AI 分析]
    end

    %% 可觀測性
    subgraph "可觀測性"
        PROM[Prometheus]
        GRAF[Grafana]
        LOKI[Loki]
        PT[Promtail]
        NEXP[Node Exporter]
        REXP[Redis Exporter]
    end

    %% 連接關係
    U1 --> CADDY
    U2 --> CADDY
    CADDY --> AG
    CADDY -->|靜態| CDN

    AG --> AS
    AG --> PS
    AG --> CS
    AG --> OS

    AS --> DB
    PS --> DB
    CS --> DB
    OS --> DB

    AS --> REDIS
    PS --> REDIS
    CS --> REDIS
    OS --> REDIS
    SCH --> REDIS
    WK --> REDIS

    PS --> APIFY
    CS --> APIFY
    CS --> OPENAI
    OS --> OPENAI

    AG --> PROM
    AS --> PROM
    PS --> PROM
    CS --> PROM
    OS --> PROM
    WK --> PROM
    SCH --> PROM
    PROM --> GRAF
    PT --> LOKI
    LOKI --> GRAF
    NEXP --> PROM
    REXP --> PROM

    style U1 fill:#e1f5fe
    style U2 fill:#e1f5fe
    style CADDY fill:#fff3e0
    style AG fill:#f3e5f5
    style AS fill:#e8f5e8
    style PS fill:#e8f5e8
    style CS fill:#e8f5e8
    style OS fill:#e8f5e8
    style WK fill:#e8f5e8
    style SCH fill:#e8f5e8
    style DASH fill:#e8f5e8
    style DB fill:#fce4ec
    style REDIS fill:#fce4ec
    style APIFY fill:#fff9c4
    style OPENAI fill:#fff9c4
```

## 2. 微服務架構詳細圖（按 go-zero + Asynq）

```mermaid
graph TB
    subgraph "API Gateway"
        AG[API Gateway<br/>• 路由<br/>• 認證<br/>• 限流<br/>• 日誌]
    end

    subgraph "核心服務"
        subgraph "認證服務"
            AUTH[Auth Service<br/>• JWT 管理<br/>• 用戶註冊/登入<br/>• 權限控制]
        end
        
        subgraph "產品服務"
            PROD[Product Service<br/>• 產品追蹤<br/>• 資料更新<br/>• 歷史記錄<br/>• 變化檢測]
        end
        
        subgraph "競品服務"
            COMP[Competitor Service<br/>• 競品分析<br/>• 價格/BSR/評分對比<br/>• 洞察生成]
        end
        
        subgraph "優化服務"
            OPT[Optimization Service<br/>• AI 建議<br/>• 關鍵字/定價分析]
        end
    end

    subgraph "任務處理"
        WORKER[Asynq Worker<br/>• 異步任務處理]
        SCHED[Asynq Scheduler<br/>• Cron/週期任務]
        DASH[Asynq Dashboard]
    end

    subgraph "資料儲存"
        PRIMARY[(主資料庫<br/>PostgreSQL/Supabase)]
        CACHE[(快取層<br/>Redis)]
        QUEUE[(佇列系統<br/>Redis+Asynq)]
    end

    %% 連接關係
    AG --> AUTH
    AG --> PROD
    AG --> COMP
    AG --> OPT
    
    AUTH --> PRIMARY
    AUTH --> CACHE
    
    PROD --> PRIMARY
    PROD --> CACHE
    PROD --> QUEUE
    
    COMP --> PRIMARY
    COMP --> CACHE
    COMP --> QUEUE
    
    OPT --> PRIMARY
    OPT --> CACHE
    
    SCHED --> QUEUE
    WORKER --> QUEUE
    
    style AUTH fill:#bbdefb
    style PROD fill:#c8e6c9
    style COMP fill:#ffcdd2
    style OPT fill:#fff9c4
    style WORKER fill:#d1c4e9
    style SCHED fill:#d1c4e9
    style DASH fill:#d1c4e9
```

## 3. 資料流架構圖（精簡版）

```mermaid
sequenceDiagram
    participant U as 用戶
    participant AG as API Gateway
    participant PS as Product Service
    participant CS as Competitor Service
    participant OS as Optimization Service
    participant Q as Asynq Queue
    participant C as Redis Cache
    participant DB as PostgreSQL/Supabase
    participant API as External APIs (Apify/OpenAI)

    Note over U,PS: 產品追蹤流程
    U->>AG: 1. 新增追蹤產品
    AG->>PS: 2. 驗證並建立追蹤
    PS->>DB: 3. 儲存追蹤設定
    PS->>Q: 4. 入隊資料抓取任務
    AG-->>U: 5. 返回追蹤 ID
    Q->>API: 6. 調用 Apify API
    API-->>Q: 7. 返回產品資料
    Q->>DB: 8. 儲存產品資料
    Q->>C: 9. 更新快取

    Note over U,CS: 競品分析流程
    U->>AG: 10. 請求競品分析
    AG->>CS: 11. 建立分析任務
    CS->>Q: 12. 入隊分析任務
    Q->>API: 13. 抓取競品資料
    Q->>CS: 14. 執行比較與洞察
    CS->>OS: 15. 需要時請求 AI 洞察
    OS->>API: 16. 調用 OpenAI
    API-->>OS: 17. 返回分析
    OS-->>CS: 18. 返回洞察
    CS->>DB: 19. 儲存分析結果
    CS->>C: 20. 快取結果
```

## 4. 部署架構圖（Docker Compose 現狀）

```mermaid
graph TB
    subgraph "單機/VM（Docker Compose）"
        subgraph "網關與前端"
            CADDY[Caddy (本地容器/生產物理機)]
            GATEWAY[amazon-pilot-gateway:8080]
            FRONTEND[amazon-pilot-frontend:3000]
        end

        subgraph "後端服務"
            AUTH[amazon-pilot-auth]
            PRODUCT[amazon-pilot-product]
            COMP[amazon-pilot-competitor]
            OPT[amazon-pilot-optimization]
            WORKER[amazon-pilot-worker]
            SCHED[amazon-pilot-scheduler]
            DASH[amazon-pilot-dashboard]
        end

        subgraph "資料服務"
            POSTGRES[(PostgreSQL 本地容器/連線Supabase)]
            REDIS[(Redis)]
        end

        subgraph "可觀測性"
            PROM[Prometheus]
            GRAF[Grafana]
            LOKI[Loki]
            PT[Promtail]
            NEXP[Node Exporter]
            REXP[Redis Exporter]
        end
    end

    CADDY --> GATEWAY
    CADDY --> FRONTEND
    GATEWAY --> AUTH
    GATEWAY --> PRODUCT
    GATEWAY --> COMP
    GATEWAY --> OPT

    AUTH --> POSTGRES
    PRODUCT --> POSTGRES
    COMP --> POSTGRES
    OPT --> POSTGRES

    AUTH --> REDIS
    PRODUCT --> REDIS
    COMP --> REDIS
    OPT --> REDIS
    WORKER --> REDIS
    SCHED --> REDIS
    DASH --> REDIS

    PRODUCT --> APIFY[(Apify API)]
    COMP --> APIFY
    COMP --> OPENAI[(OpenAI API)]
    OPT --> OPENAI

    GATEWAY --> PROM
    AUTH --> PROM
    PRODUCT --> PROM
    COMP --> PROM
    OPT --> PROM
    WORKER --> PROM
    SCHED --> PROM
    NEXP --> PROM
    REXP --> PROM
    PROM --> GRAF
    PT --> LOKI
    LOKI --> GRAF
```

## 5. 快取與佇列架構圖（Redis + Asynq）

```mermaid
graph TB
    subgraph "任務生產者"
        PROD1[API Gateway<br/>用戶請求]
        PROD2[Scheduler<br/>定時任務]
        PROD3[Service Events<br/>事件觸發]
    end
    
    subgraph "佇列系統 (Redis + Asynq)"
        subgraph "高優先級佇列"
            HQ[critical 隊列<br/>• 即時處理<br/>• 權重: 6]
        end
        
        subgraph "預設佇列"
            PQ[default 隊列<br/>• 資料更新<br/>• 權重: 3]
        end
        
        subgraph "低優先級佇列"
            AQ[low 隊列<br/>• 競品/優化分析<br/>• 權重: 1]
        end
    end
    
    subgraph "任務消費者"
        WORKER1[Asynq Worker<br/>• 產品更新]
        WORKER2[Asynq Worker<br/>• 競品/優化分析]
        WORKER4[Asynq Worker<br/>• 清理/異常檢測]
    end
    
    subgraph "外部服務"
        APIFY[Apify API]
        OPENAI[OpenAI API]
    end

    %% 生產者到佇列
    PROD1 --> HQ
    PROD1 --> PQ
    PROD1 --> AQ
    PROD2 --> PQ
    PROD2 --> AQ
    PROD3 --> PQ
    
    %% 佇列到消費者
    HQ --> WORKER1
    PQ --> WORKER1
    AQ --> WORKER2
    PQ --> WORKER4
    
    %% 消費者到外部服務
    WORKER1 --> APIFY
    WORKER2 --> OPENAI
    
    style HQ fill:#ffcdd2
    style PQ fill:#dcedc8
    style AQ fill:#bbdefb
```

## 7. 安全架構圖（概念一致）

```mermaid
graph TB
    subgraph "外部威脅"
        THREAT1[DDoS 攻擊]
        THREAT2[SQL 注入]
        THREAT3[XSS 攻擊]
        THREAT4[未授權存取]
    end
    
    subgraph "防護層"
        subgraph "網路層防護"
            WAF[Web Application Firewall<br/>• 過濾惡意請求<br/>• Rate Limiting<br/>• IP 黑名單]
            
            CDN[CDN + DDoS Protection<br/>• 分散式防護<br/>• 快取靜態資源<br/>• 地理分散]
        end
        
        subgraph "應用層防護"
            AUTH[Authentication Layer<br/>• JWT Token<br/>• 多因素認證<br/>• 會話管理]
            
            AUTHZ[Authorization Layer<br/>• RBAC 權限控制<br/>• API 權限檢查<br/>• 資源存取控制]
            
            VALID[Input Validation
• 參數驗證
• SQL 注入防護
• XSS 過濾]
        end
        
        subgraph "資料層防護"
            ENCRYPT[Data Encryption<br/>• 傳輸加密 (TLS)<br/>• 靜態加密<br/>• 欄位級加密]
            
            AUDIT[Audit Logging<br/>• 存取日誌<br/>• 操作追蹤<br/>• 異常檢測]
        end
    end
    
    subgraph "核心系統"
        API[API Gateway]
        SERVICES[Microservices]
        DATABASE[(Database)]
    end
    
    subgraph "監控與回應"
        SIEM[安全資訊與事件管理<br/>• 即時監控<br/>• 威脅檢測<br/>• 自動回應]
        
        INCIDENT[事件回應<br/>• 告警通知<br/>• 自動隔離<br/>• 恢復程序]
    end

    %% 威脅到防護
    THREAT1 --> CDN
    THREAT2 --> WAF
    THREAT3 --> VALID
    THREAT4 --> AUTH
    
    %% 防護層級
    CDN --> WAF
    WAF --> API
    
    API --> AUTH
    AUTH --> AUTHZ
    AUTHZ --> VALID
    
    VALID --> SERVICES
    SERVICES --> ENCRYPT
    ENCRYPT --> DATABASE
    
    %% 監控
    API --> AUDIT
    SERVICES --> AUDIT
    DATABASE --> AUDIT
    AUDIT --> SIEM
    SIEM --> INCIDENT
    
    style THREAT1 fill:#ffcdd2
    style THREAT2 fill:#ffcdd2
    style THREAT3 fill:#ffcdd2
    style THREAT4 fill:#ffcdd2
    style WAF fill:#c8e6c9
    style CDN fill:#c8e6c9
    style AUTH fill:#bbdefb
    style AUTHZ fill:#bbdefb
    style VALID fill:#bbdefb
    style ENCRYPT fill:#fff9c4
    style AUDIT fill:#fff9c4
```

## 8. 監控架構圖（Prometheus + Loki/Promtail）

```mermaid
graph TB
    subgraph "應用層"
        APP1[API Gateway]
        APP2[Microservices]
        APP3[Database]
        APP4[Cache & Queue]
    end
    
    subgraph "資料收集層"
        subgraph "指標收集"
            PROM[Prometheus<br/>• 時間序列資料<br/>• 指標聚合<br/>• 告警規則]
            
            NODE[Node Exporter<br/>• 系統指標]
            
            REXP[Redis Exporter<br/>• Redis 指標]
        end
        
        subgraph "日誌收集"
            PT[Promtail<br/>• 容器日誌收集]
        end
    end
    
    subgraph "資料儲存層"
        TSDB[(Prometheus TSDB)]
        
        LOKI[(Loki<br/>日誌儲存)]
    end
    
    subgraph "視覺化與告警層"
        GRAFANA[Grafana<br/>• 儀表板/日誌查詢]
        
        ALERT[AlertManager<br/>• 告警管理/通知路由]
    end
    
    subgraph "通知渠道"
        EMAIL[Email]
        SLACK[Slack]
        WEBHOOK[Webhook]
    end

    %% 應用到收集
    APP1 --> PROM
    APP2 --> PROM
    APP3 --> PROM
    APP4 --> PROM
    NODE --> PROM
    REXP --> PROM
    APP1 --> PT
    APP2 --> PT
    APP3 --> PT
    APP4 --> PT
    
    %% 收集到儲存
    PROM --> TSDB
    PT --> LOKI
    
    %% 儲存到視覺化
    TSDB --> GRAFANA
    LOKI --> GRAFANA
    
    PROM --> ALERT
    
    %% 告警到通知
    ALERT --> EMAIL
    ALERT --> SLACK
    ALERT --> WEBHOOK
    
    style PROM fill:#fff3e0
    style LOKI fill:#e8f5e8
    style GRAFANA fill:#bbdefb
    style ALERT fill:#ffcdd2
```

## 9. CI/CD 流程圖（簡要）

```mermaid
graph TB
    subgraph "開發流程"
        DEV[開發者]
        GIT[GitHub]
    end
    
    subgraph "CI 管線"
        TRIGGER[Workflow Trigger]
        BUILD[Build Docker Images]
        TEST[Test & Lint]
        QUALITY[Quality Gates]
    end
    
    subgraph "CD 部署"
        PACKAGE[Push Images]
        DEPLOY_DEV[Deploy Dev]
        DEPLOY_STAGING[Deploy Staging]
        DEPLOY_PROD[Deploy Prod]
    end
    
    subgraph "環境"
        ENV_DEV[開發環境]
        ENV_STAGING[測試環境]
        ENV_PROD[生產環境]
    end
    
    subgraph "監控與回饋"
        MONITOR[監控系統]
        FEEDBACK[回饋機制]
    end

    DEV --> GIT
    GIT --> TRIGGER
    TRIGGER --> BUILD
    BUILD --> TEST
    TEST --> QUALITY
    QUALITY --> PACKAGE
    PACKAGE --> DEPLOY_DEV
    DEPLOY_DEV --> ENV_DEV
    DEPLOY_DEV --> DEPLOY_STAGING
    DEPLOY_STAGING --> ENV_STAGING
    DEPLOY_STAGING --> DEPLOY_PROD
    DEPLOY_PROD --> ENV_PROD
    
    ENV_DEV --> MONITOR
    ENV_STAGING --> MONITOR
    ENV_PROD --> MONITOR
    MONITOR --> FEEDBACK
    FEEDBACK --> DEV
```

## 10. 災難恢復架構圖（概念）

```mermaid
graph TB
    subgraph "主要站點 (Primary)"
        PROD_APP[應用服務]
        PROD_DB[(主資料庫)]
        PROD_CACHE[(主快取)]
        BACKUP[備份服務]
    end
    
    subgraph "災難恢復站點 (DR)"
        DR_APP[待命應用服務]
        DR_DB[(備援資料庫)]
        DR_CACHE[(備援快取)]
    end
    
    subgraph "雲端儲存"
        CLOUD_BACKUP[(雲端備份)]
    end
    
    subgraph "監控與自動化"
        HEALTH_CHECK[健康檢查]
        FAILOVER[故障轉移]
        RECOVERY[恢復程序]
    end

    PROD_APP --> PROD_DB
    PROD_APP --> PROD_CACHE
    BACKUP --> PROD_DB
    BACKUP --> CLOUD_BACKUP
    PROD_DB -.-> DR_DB
    BACKUP -.-> DR_CACHE
    HEALTH_CHECK --> PROD_APP
    HEALTH_CHECK --> PROD_DB
    HEALTH_CHECK --> PROD_CACHE
    FAILOVER --> DR_APP
    FAILOVER --> DR_DB
    FAILOVER --> DR_CACHE
    RECOVERY --> PROD_APP
    RECOVERY --> PROD_DB
    CLOUD_BACKUP --> RECOVERY
```

以上圖表已與以下倉庫實際實現對齊：
- Docker Compose 定義：deployments/compose/docker-compose.yml（及 .local/.prod 覆蓋）
- 反向代理：deployments/compose/Caddyfile
- 佇列：internal/pkg/queue/queue.go（Redis + Asynq）
- 監控：Prometheus/Grafana/Loki/Promtail/Exporters（compose/monitoring）
- 服務邏輯：cmd/*、internal/*

