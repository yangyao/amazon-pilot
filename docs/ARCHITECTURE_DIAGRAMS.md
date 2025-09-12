# 系統架構圖文件

## 概述

本文件包含 Amazon 賣家產品監控與優化工具的各種架構圖表，展示系統的整體設計、資料流向和部署拓撲。

## 1. 系統整體架構圖

```mermaid
graph TB
    %% 用戶層
    subgraph "用戶層"
        U1[Amazon 賣家]
        U2[管理員]
    end

    %% 接入層
    subgraph "接入層"
        LB[負載均衡器<br/>Nginx]
        CDN[CDN<br/>靜態資源]
    end

    %% API 閘道層
    subgraph "API 閘道層"
        AG1[API Gateway 1]
        AG2[API Gateway 2]
        AG3[API Gateway 3]
    end

    %% 微服務層
    subgraph "微服務層"
        AS[認證服務<br/>Auth Service]
        PS[產品服務<br/>Product Service]
        CS[競品服務<br/>Competitor Service]
        OS[優化服務<br/>Optimization Service]
        NS[通知服務<br/>Notification Service]
    end

    %% 資料層
    subgraph "資料層"
        DB[(Supabase<br/>PostgreSQL)]
        REDIS[(Redis<br/>快取 & 佇列)]
    end

    %% 外部服務層
    subgraph "外部服務"
        APIFY[Apify API<br/>資料擷取]
        OPENAI[OpenAI API<br/>AI 分析]
    end

    %% 監控層
    subgraph "監控層"
        PROM[Prometheus<br/>指標收集]
        GRAF[Grafana<br/>視覺化]
        ELK[ELK Stack<br/>日誌分析]
    end

    %% 連接關係
    U1 --> LB
    U2 --> LB
    LB --> AG1
    LB --> AG2
    LB --> AG3
    
    AG1 --> AS
    AG1 --> PS
    AG1 --> CS
    AG2 --> AS
    AG2 --> OS
    AG2 --> NS
    AG3 --> PS
    AG3 --> CS
    
    AS --> DB
    AS --> REDIS
    PS --> DB
    PS --> REDIS
    PS --> APIFY
    CS --> DB
    CS --> REDIS
    CS --> APIFY
    CS --> OPENAI
    OS --> DB
    OS --> REDIS
    OS --> OPENAI
    NS --> DB
    NS --> REDIS
    
    AS --> PROM
    PS --> PROM
    CS --> PROM
    OS --> PROM
    NS --> PROM
    
    PROM --> GRAF
    ELK --> GRAF
    
    style U1 fill:#e1f5fe
    style U2 fill:#e1f5fe
    style LB fill:#fff3e0
    style AG1 fill:#f3e5f5
    style AG2 fill:#f3e5f5
    style AG3 fill:#f3e5f5
    style AS fill:#e8f5e8
    style PS fill:#e8f5e8
    style CS fill:#e8f5e8
    style OS fill:#e8f5e8
    style NS fill:#e8f5e8
    style DB fill:#fce4ec
    style REDIS fill:#fce4ec
    style APIFY fill:#fff9c4
    style OPENAI fill:#fff9c4
```

## 2. 微服務架構詳細圖

```mermaid
graph TB
    subgraph "API Gateway"
        AG[API Gateway<br/>• 路由<br/>• 認證<br/>• 限流<br/>• 日誌]
    end

    subgraph "核心服務"
        subgraph "認證服務"
            AUTH[Auth Service<br/>• JWT 管理<br/>• 用戶註冊/登入<br/>• 權限控制<br/>• 會話管理]
        end
        
        subgraph "產品服務"
            PROD[Product Service<br/>• 產品追蹤<br/>• 資料更新<br/>• 歷史記錄<br/>• 變化檢測]
        end
        
        subgraph "競品服務"
            COMP[Competitor Service<br/>• 競品分析<br/>• 價格比較<br/>• 市場定位<br/>• 洞察生成]
        end
        
        subgraph "優化服務"
            OPT[Optimization Service<br/>• AI 建議<br/>• 關鍵字分析<br/>• 定價策略<br/>• A/B 測試]
        end
        
        subgraph "通知服務"
            NOTIF[Notification Service<br/>• 即時通知<br/>• 郵件發送<br/>• 推播通知<br/>• Webhook]
        end
    end

    subgraph "支援服務"
        SCHED[排程服務<br/>• Cron 任務<br/>• 批次處理<br/>• 任務調度]
        
        MONITOR[監控服務<br/>• 健康檢查<br/>• 指標收集<br/>• 告警管理]
    end

    subgraph "資料儲存"
        PRIMARY[(主資料庫<br/>Supabase)]
        CACHE[(快取層<br/>Redis)]
        QUEUE[(佇列系統<br/>Bull Queue)]
    end

    %% 連接關係
    AG --> AUTH
    AG --> PROD
    AG --> COMP
    AG --> OPT
    AG --> NOTIF
    
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
    COMP --> OPT
    
    NOTIF --> PRIMARY
    NOTIF --> CACHE
    NOTIF --> QUEUE
    
    SCHED --> QUEUE
    MONITOR --> CACHE
    
    style AUTH fill:#bbdefb
    style PROD fill:#c8e6c9
    style COMP fill:#ffcdd2
    style OPT fill:#fff9c4
    style NOTIF fill:#d1c4e9
```

## 3. 資料流架構圖

```mermaid
sequenceDiagram
    participant U as 用戶
    participant AG as API Gateway
    participant PS as Product Service
    participant CS as Competitor Service
    participant OS as Optimization Service
    participant Q as Queue System
    participant C as Cache
    participant DB as Database
    participant API as External APIs

    Note over U,API: 產品追蹤流程
    U->>AG: 1. 新增追蹤產品
    AG->>PS: 2. 驗證並建立追蹤
    PS->>DB: 3. 儲存追蹤設定
    PS->>Q: 4. 排隊資料抓取任務
    PS->>AG: 5. 返回追蹤 ID
    AG->>U: 6. 確認建立成功
    
    Note over Q,API: 背景資料處理
    Q->>API: 7. 調用 Apify API
    API-->>Q: 8. 返回產品資料
    Q->>DB: 9. 儲存產品資料
    Q->>C: 10. 更新快取
    Q->>PS: 11. 觸發變化檢測
    
    Note over U,OS: 競品分析流程
    U->>AG: 12. 請求競品分析
    AG->>CS: 13. 建立分析任務
    CS->>Q: 14. 排隊分析任務
    CS->>AG: 15. 返回任務 ID
    
    Q->>API: 16. 平行抓取競品資料
    Q->>CS: 17. 執行比較分析
    CS->>OS: 18. 請求 AI 洞察
    OS->>API: 19. 調用 OpenAI API
    API-->>OS: 20. 返回分析結果
    OS-->>CS: 21. 返回洞察
    CS->>DB: 22. 儲存分析結果
    CS->>C: 23. 快取結果
```

## 4. 部署架構圖

```mermaid
graph TB
    subgraph "生產環境"
        subgraph "容器編排層"
            K8S[Kubernetes Cluster]
        end
        
        subgraph "應用容器"
            POD1[API Gateway Pod<br/>• 3 replicas<br/>• Load Balanced]
            POD2[Auth Service Pod<br/>• 2 replicas<br/>• Stateless]
            POD3[Product Service Pod<br/>• 3 replicas<br/>• Auto Scaling]
            POD4[Competitor Service Pod<br/>• 2 replicas<br/>• CPU Intensive]
            POD5[Optimization Service Pod<br/>• 2 replicas<br/>• Memory Intensive]
            POD6[Notification Service Pod<br/>• 2 replicas<br/>• IO Intensive]
        end
        
        subgraph "資料服務"
            REDIS_CLUSTER[Redis Cluster<br/>• 3 Masters<br/>• 3 Slaves<br/>• Sentinel]
            
            SUPABASE[Supabase<br/>• Managed PostgreSQL<br/>• Auto Backup<br/>• Replication]
        end
        
        subgraph "監控基礎設施"
            PROM_POD[Prometheus Pod<br/>• Data Collection<br/>• Alert Manager]
            GRAF_POD[Grafana Pod<br/>• Dashboards<br/>• Visualization]
            ELK_POD[ELK Stack Pod<br/>• Log Aggregation<br/>• Search & Analysis]
        end
    end
    
    subgraph "外部服務"
        APIFY_SVC[Apify Cloud<br/>• Web Scraping<br/>• Data Extraction]
        OPENAI_SVC[OpenAI API<br/>• GPT-4 Analysis<br/>• Natural Language Processing]
    end
    
    subgraph "網路層"
        INGRESS[Ingress Controller<br/>• SSL Termination<br/>• Path Routing]
        LB[Cloud Load Balancer<br/>• Health Check<br/>• Auto Scaling]
    end

    %% 連接關係
    LB --> INGRESS
    INGRESS --> POD1
    
    POD1 --> POD2
    POD1 --> POD3
    POD1 --> POD4
    POD1 --> POD5
    POD1 --> POD6
    
    POD2 --> REDIS_CLUSTER
    POD3 --> REDIS_CLUSTER
    POD4 --> REDIS_CLUSTER
    POD5 --> REDIS_CLUSTER
    POD6 --> REDIS_CLUSTER
    
    POD2 --> SUPABASE
    POD3 --> SUPABASE
    POD4 --> SUPABASE
    POD5 --> SUPABASE
    POD6 --> SUPABASE
    
    POD3 --> APIFY_SVC
    POD4 --> APIFY_SVC
    POD4 --> OPENAI_SVC
    POD5 --> OPENAI_SVC
    
    POD1 --> PROM_POD
    POD2 --> PROM_POD
    POD3 --> PROM_POD
    POD4 --> PROM_POD
    POD5 --> PROM_POD
    POD6 --> PROM_POD
    
    PROM_POD --> GRAF_POD
    ELK_POD --> GRAF_POD
    
    style POD1 fill:#e3f2fd
    style POD2 fill:#e8f5e8
    style POD3 fill:#fff3e0
    style POD4 fill:#fce4ec
    style POD5 fill:#f3e5f5
    style POD6 fill:#e0f2f1
```

## 5. 快取架構圖

```mermaid
graph TB
    subgraph "應用層"
        APP1[API Gateway]
        APP2[Product Service]
        APP3[Competitor Service]
        APP4[Optimization Service]
    end
    
    subgraph "快取層次"
        subgraph "L1 快取 (記憶體)"
            L1_1[應用內快取<br/>• 熱門資料<br/>• TTL: 5-30分鐘]
            L1_2[計算結果快取<br/>• 頻繁計算<br/>• TTL: 10-60分鐘]
        end
        
        subgraph "L2 快取 (Redis)"
            L2_1[產品資料快取<br/>• 基本資訊<br/>• TTL: 4-24小時]
            L2_2[用戶會話快取<br/>• 登入狀態<br/>• TTL: 7天]
            L2_3[分析結果快取<br/>• 競品分析<br/>• TTL: 1-6小時]
            L2_4[API 回應快取<br/>• 外部API<br/>• TTL: 10-30分鐘]
        end
        
        subgraph "L3 快取 (資料庫)"
            DB[(Supabase<br/>持久化資料)]
        end
    end
    
    subgraph "快取策略"
        STRATEGY1[Cache-Aside<br/>• 讀取時檢查<br/>• 未命中時載入]
        STRATEGY2[Write-Through<br/>• 同步寫入<br/>• 保證一致性]
        STRATEGY3[Write-Behind<br/>• 異步寫入<br/>• 提高效能]
    end

    %% 應用層到快取層
    APP1 --> L1_1
    APP2 --> L1_1
    APP3 --> L1_2
    APP4 --> L1_2
    
    %% L1 到 L2
    L1_1 -.-> L2_1
    L1_1 -.-> L2_2
    L1_2 -.-> L2_3
    L1_2 -.-> L2_4
    
    %% L2 到 L3
    L2_1 -.-> DB
    L2_2 -.-> DB
    L2_3 -.-> DB
    L2_4 -.-> DB
    
    %% 策略應用
    STRATEGY1 -.-> L2_1
    STRATEGY2 -.-> L2_2
    STRATEGY3 -.-> L2_3
    
    style L1_1 fill:#e8f5e8
    style L1_2 fill:#e8f5e8
    style L2_1 fill:#fff3e0
    style L2_2 fill:#fff3e0
    style L2_3 fill:#fff3e0
    style L2_4 fill:#fff3e0
    style DB fill:#fce4ec
```

## 6. 佇列架構圖

```mermaid
graph TB
    subgraph "任務生產者"
        PROD1[API Gateway<br/>用戶請求]
        PROD2[Scheduler<br/>定時任務]
        PROD3[Event Handler<br/>事件觸發]
    end
    
    subgraph "佇列系統 (Redis + Bull)"
        subgraph "高優先級佇列"
            HQ[High Priority Queue<br/>• 即時處理<br/>• 並發: 10<br/>• 重試: 3次]
        end
        
        subgraph "產品更新佇列"
            PQ[Product Update Queue<br/>• 資料更新<br/>• 並發: 5<br/>• 重試: 3次]
        end
        
        subgraph "分析佇列"
            AQ[Analysis Queue<br/>• 競品分析<br/>• 並發: 2<br/>• 重試: 2次]
        end
        
        subgraph "通知佇列"
            NQ[Notification Queue<br/>• 消息發送<br/>• 並發: 20<br/>• 重試: 5次]
        end
        
        subgraph "清理佇列"
            CQ[Cleanup Queue<br/>• 批次處理<br/>• 並發: 1<br/>• 重試: 1次]
        end
    end
    
    subgraph "任務消費者"
        WORKER1[Product Workers<br/>• 資料擷取<br/>• 狀態更新]
        WORKER2[Analysis Workers<br/>• AI 分析<br/>• 報告生成]
        WORKER3[Notification Workers<br/>• 郵件發送<br/>• 推播通知]
        WORKER4[Cleanup Workers<br/>• 資料清理<br/>• 快取清理]
    end
    
    subgraph "外部服務"
        APIFY[Apify API]
        OPENAI[OpenAI API]
        EMAIL[Email Service]
        PUSH[Push Service]
    end

    %% 生產者到佇列
    PROD1 --> HQ
    PROD1 --> PQ
    PROD1 --> AQ
    PROD2 --> PQ
    PROD2 --> CQ
    PROD3 --> NQ
    
    %% 佇列到消費者
    HQ --> WORKER1
    PQ --> WORKER1
    AQ --> WORKER2
    NQ --> WORKER3
    CQ --> WORKER4
    
    %% 消費者到外部服務
    WORKER1 --> APIFY
    WORKER2 --> OPENAI
    WORKER3 --> EMAIL
    WORKER3 --> PUSH
    
    style HQ fill:#ffcdd2
    style PQ fill:#dcedc8
    style AQ fill:#bbdefb
    style NQ fill:#f8bbd9
    style CQ fill:#d7ccc8
```

## 7. 安全架構圖

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
            
            VALID[Input Validation<br/>• 參數驗證<br/>• SQL 注入防護<br/>• XSS 過濾]
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

## 8. 監控架構圖

```mermaid
graph TB
    subgraph "應用層"
        APP1[API Gateway]
        APP2[Microservices]
        APP3[Databases]
        APP4[Cache & Queue]
    end
    
    subgraph "資料收集層"
        subgraph "指標收集"
            PROM[Prometheus<br/>• 時間序列資料<br/>• 指標聚合<br/>• 告警規則]
            
            NODE[Node Exporter<br/>• 系統指標<br/>• 硬體監控<br/>• 效能資料]
        end
        
        subgraph "日誌收集"
            BEATS[Filebeat<br/>• 日誌收集<br/>• 檔案監控<br/>• 資料轉發]
            
            LOGSTASH[Logstash<br/>• 日誌處理<br/>• 格式轉換<br/>• 資料清理]
        end
        
        subgraph "追蹤收集"
            JAEGER[Jaeger<br/>• 分散式追蹤<br/>• 請求追蹤<br/>• 效能分析]
        end
    end
    
    subgraph "資料儲存層"
        TSDB[(時間序列資料庫<br/>Prometheus TSDB)]
        
        ELK[(Elasticsearch<br/>日誌索引)]
        
        TRACE[(Jaeger Storage<br/>追蹤資料)]
    end
    
    subgraph "視覺化與告警層"
        GRAFANA[Grafana<br/>• 儀表板<br/>• 圖表視覺化<br/>• 告警通知]
        
        KIBANA[Kibana<br/>• 日誌搜尋<br/>• 日誌分析<br/>• 查詢介面]
        
        ALERT[AlertManager<br/>• 告警管理<br/>• 通知路由<br/>• 告警聚合]
    end
    
    subgraph "通知渠道"
        EMAIL[Email]
        SLACK[Slack]
        SMS[SMS]
        WEBHOOK[Webhook]
    end

    %% 應用到收集
    APP1 --> PROM
    APP2 --> PROM
    APP3 --> PROM
    APP4 --> PROM
    
    APP1 --> BEATS
    APP2 --> BEATS
    APP3 --> BEATS
    APP4 --> BEATS
    
    APP1 --> JAEGER
    APP2 --> JAEGER
    
    NODE --> PROM
    
    %% 收集到儲存
    PROM --> TSDB
    BEATS --> LOGSTASH
    LOGSTASH --> ELK
    JAEGER --> TRACE
    
    %% 儲存到視覺化
    TSDB --> GRAFANA
    ELK --> KIBANA
    TRACE --> GRAFANA
    
    PROM --> ALERT
    
    %% 告警到通知
    ALERT --> EMAIL
    ALERT --> SLACK
    ALERT --> SMS
    ALERT --> WEBHOOK
    
    GRAFANA --> EMAIL
    GRAFANA --> SLACK
    
    style PROM fill:#fff3e0
    style ELK fill:#e8f5e8
    style GRAFANA fill:#bbdefb
    style ALERT fill:#ffcdd2
```

## 9. CI/CD 流程圖

```mermaid
graph TB
    subgraph "開發階段"
        DEV[開發者]
        GIT[Git Repository<br/>• Feature Branch<br/>• Pull Request<br/>• Code Review]
    end
    
    subgraph "CI 流程"
        TRIGGER[觸發器<br/>• Push Event<br/>• PR Event<br/>• Scheduled]
        
        BUILD[建置階段<br/>• Install Dependencies<br/>• Build Application<br/>• Run Tests]
        
        TEST[測試階段<br/>• Unit Tests<br/>• Integration Tests<br/>• Security Scan]
        
        QUALITY[品質檢查<br/>• Code Coverage<br/>• Linting<br/>• Security Analysis]
    end
    
    subgraph "CD 流程"
        PACKAGE[打包階段<br/>• Docker Build<br/>• Image Scan<br/>• Push to Registry]
        
        DEPLOY_DEV[開發環境部署<br/>• Auto Deploy<br/>• Smoke Tests<br/>• Environment Setup]
        
        DEPLOY_STAGING[測試環境部署<br/>• Manual Approval<br/>• Full Test Suite<br/>• Performance Tests]
        
        DEPLOY_PROD[生產環境部署<br/>• Blue-Green Deploy<br/>• Health Checks<br/>• Rollback Ready]
    end
    
    subgraph "環境"
        ENV_DEV[開發環境<br/>• Feature Testing<br/>• Developer Access]
        
        ENV_STAGING[測試環境<br/>• QA Testing<br/>• Client Demo]
        
        ENV_PROD[生產環境<br/>• Live System<br/>• User Access]
    end
    
    subgraph "監控與回饋"
        MONITOR[監控系統<br/>• Health Metrics<br/>• Error Tracking<br/>• Performance]
        
        FEEDBACK[回饋機制<br/>• User Feedback<br/>• Error Reports<br/>• Performance Issues]
    end

    %% 開發流程
    DEV --> GIT
    GIT --> TRIGGER
    
    %% CI 流程
    TRIGGER --> BUILD
    BUILD --> TEST
    TEST --> QUALITY
    
    %% CD 流程
    QUALITY --> PACKAGE
    PACKAGE --> DEPLOY_DEV
    DEPLOY_DEV --> ENV_DEV
    
    DEPLOY_DEV --> DEPLOY_STAGING
    DEPLOY_STAGING --> ENV_STAGING
    
    DEPLOY_STAGING --> DEPLOY_PROD
    DEPLOY_PROD --> ENV_PROD
    
    %% 監控回饋
    ENV_DEV --> MONITOR
    ENV_STAGING --> MONITOR
    ENV_PROD --> MONITOR
    
    MONITOR --> FEEDBACK
    FEEDBACK --> DEV
    
    style BUILD fill:#e8f5e8
    style TEST fill:#fff3e0
    style QUALITY fill:#bbdefb
    style DEPLOY_PROD fill:#ffcdd2
```

## 10. 災難恢復架構圖

```mermaid
graph TB
    subgraph "主要站點 (Primary Site)"
        subgraph "生產環境"
            PROD_APP[應用服務群集]
            PROD_DB[(主資料庫)]
            PROD_CACHE[(主快取)]
        end
        
        subgraph "備份系統"
            BACKUP[備份服務<br/>• 定期備份<br/>• 增量備份<br/>• 快照]
        end
    end
    
    subgraph "災難恢復站點 (DR Site)"
        subgraph "待命環境"
            DR_APP[待命應用服務<br/>• 最小配置<br/>• 快速啟動]
            DR_DB[(備援資料庫<br/>• 同步複製<br/>• 讀取副本)]
            DR_CACHE[(備援快取<br/>• 冷備份)]
        end
    end
    
    subgraph "雲端儲存"
        CLOUD_BACKUP[(雲端備份<br/>• 長期保存<br/>• 地理分散<br/>• 版本控制)]
    end
    
    subgraph "監控與自動化"
        HEALTH_CHECK[健康檢查<br/>• 服務監控<br/>• 可用性檢測<br/>• 自動告警]
        
        FAILOVER[故障轉移<br/>• 自動切換<br/>• DNS 更新<br/>• 流量路由]
        
        RECOVERY[恢復程序<br/>• 資料同步<br/>• 服務恢復<br/>• 一致性檢查]
    end
    
    subgraph "故障情境"
        SCENARIO1[服務故障<br/>• 應用異常<br/>• 服務重啟]
        
        SCENARIO2[資料庫故障<br/>• 主庫不可用<br/>• 切換到備庫]
        
        SCENARIO3[站點故障<br/>• 整體不可用<br/>• 切換到 DR 站點]
    end

    %% 正常操作
    PROD_APP --> PROD_DB
    PROD_APP --> PROD_CACHE
    BACKUP --> PROD_DB
    BACKUP --> CLOUD_BACKUP
    
    %% 資料同步
    PROD_DB -.->|同步複製| DR_DB
    BACKUP -.->|備份複製| DR_CACHE
    
    %% 監控
    HEALTH_CHECK --> PROD_APP
    HEALTH_CHECK --> PROD_DB
    HEALTH_CHECK --> PROD_CACHE
    
    %% 故障處理
    SCENARIO1 --> FAILOVER
    SCENARIO2 --> FAILOVER
    SCENARIO3 --> FAILOVER
    
    FAILOVER --> DR_APP
    FAILOVER --> DR_DB
    FAILOVER --> DR_CACHE
    
    %% 恢復
    RECOVERY --> PROD_APP
    RECOVERY --> PROD_DB
    CLOUD_BACKUP --> RECOVERY
    
    style SCENARIO1 fill:#ffcdd2
    style SCENARIO2 fill:#ffcdd2
    style SCENARIO3 fill:#ffcdd2
    style FAILOVER fill:#fff3e0
    style RECOVERY fill:#e8f5e8
```

這些架構圖展示了系統的不同層面和視角，幫助理解整體設計和各組件之間的關係。每個圖表都專注於特定的架構面向，提供清晰的視覺化表示。
