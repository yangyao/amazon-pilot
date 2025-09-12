# Amazon 賣家產品監控與優化工具

## 專案概述

這是一個專為 Amazon 賣家設計的產品監控與優化工具，能夠追蹤產品表現、分析競爭對手，並提供優化建議。本專案重視系統架構設計，展現可擴展、可維護的系統設計能力。

## 功能特色

### 🎯 核心功能

1. **產品追蹤系統**
   - 支援 1000+ 產品的架構設計
   - 追蹤價格變化、BSR 趨勢、評分與評論數變化
   - 異常變化通知（價格變動 > 10%、BSR 變動 > 30%）
   - 每日自動更新

2. **競品分析引擎**
   - 多維度競品比較分析
   - 主產品 vs 競品的價格差異、BSR 排名差距
   - LLM 驅動的競爭定位報告生成
   - 平行資料擷取架構

3. **Listing 優化建議**
   - AI 驅動的優化建議生成
   - 標題優化、定價調整、產品描述改進
   - 基於競品價格分析的策略建議
   - A/B 測試架構支援

### 🏗️ 系統架構特色

- **微服務架構**: 模組化設計，職責明確分離
- **水平擴展**: 支持服務和資料庫的水平擴展
- **高可用性**: 消除單點故障，實現故障自動恢復
- **可觀測性**: 完整的日誌、監控和追踪系統
- **安全優先**: 多層次安全防護機制

## 技術棧

### 後端技術
- **框架**: Node.js + Express.js
- **資料庫**: Supabase (PostgreSQL)
- **快取**: Redis
- **佇列**: Bull Queue (Redis-based)
- **API 整合**: Apify API + OpenAI API

### 部署與監控
- **容器化**: Docker + Docker Compose
- **監控**: Prometheus + Grafana
- **日誌**: Winston + ELK Stack
- **負載均衡**: Nginx

### 外部服務
- **資料擷取**: Apify Actors
- **AI 分析**: OpenAI GPT-4
- **資料庫**: Supabase PostgreSQL

## 快速開始

### 環境需求

- Node.js 18+
- Docker & Docker Compose
- Redis 7+
- PostgreSQL 15+ (Supabase)

### 安裝步驟

1. **克隆專案**
```bash
git clone <repository-url>
cd amazon-monitor
```

2. **安裝依賴**
```bash
npm install
```

3. **環境設定**
```bash
cp .env.example .env
# 編輯 .env 檔案，填入必要的環境變數
```

4. **啟動服務**
```bash
# 使用 Docker Compose 啟動所有服務
docker-compose up -d

# 或本地開發模式
npm run dev
```

5. **資料庫初始化**
```bash
# 執行資料庫遷移
npm run db:migrate

# 執行種子資料（可選）
npm run db:seed
```

### 環境變數設定

建立 `.env` 檔案並設定以下變數：

```env
# 應用設定
NODE_ENV=development
PORT=3000
APP_VERSION=1.0.0

# 資料庫設定
DATABASE_URL=postgresql://user:password@localhost:5432/amazon_monitor
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Redis 設定
REDIS_URL=redis://localhost:6379

# JWT 設定
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=7d

# 外部 API 設定
APIFY_TOKEN=your_apify_token
OPENAI_API_KEY=your_openai_api_key

# 加密設定
ENCRYPTION_KEY=your_32_byte_hex_encryption_key

# CORS 設定
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001

# 監控設定
GRAFANA_PASSWORD=your_grafana_password
```

## API 文件

### 認證

所有 API 請求需要包含 Bearer Token：

```http
Authorization: Bearer <jwt_token>
```

### 主要端點

#### 用戶認證
- `POST /api/auth/register` - 用戶註冊
- `POST /api/auth/login` - 用戶登入
- `GET /api/auth/profile` - 取得用戶資料

#### 產品追蹤
- `POST /api/products/track` - 新增追蹤產品
- `GET /api/products/tracked` - 取得追蹤列表
- `GET /api/products/{id}` - 取得產品詳細資料
- `GET /api/products/{id}/history` - 取得產品歷史資料

#### 競品分析
- `POST /api/competitors/analysis` - 建立競品分析
- `GET /api/competitors/analysis/{id}` - 取得分析結果
- `GET /api/competitors/analysis/{id}/report` - 取得詳細報告

#### 優化建議
- `POST /api/optimization/analyze` - 開始優化分析
- `GET /api/optimization/{id}` - 取得優化建議

### 完整 API 文件

詳細的 API 文件請參考：
- [API_DESIGN.md](./API_DESIGN.md) - 完整 API 設計文件
- Swagger 文件：`http://localhost:3000/api-docs`（啟動後可用）

## 架構文件

本專案提供完整的系統設計文件：

- [ARCHITECTURE.md](./ARCHITECTURE.md) - 系統架構設計
- [DATABASE_DESIGN.md](./DATABASE_DESIGN.md) - 資料庫設計
- [DESIGN_DECISIONS.md](./DESIGN_DECISIONS.md) - 技術決策說明

## 專案結構

```
amazon-monitor/
├── src/
│   ├── controllers/         # API 控制器
│   ├── services/           # 業務邏輯服務
│   ├── models/             # 資料模型
│   ├── middleware/         # 中間件
│   ├── utils/              # 工具函數
│   ├── queues/             # 佇列處理
│   └── app.js              # 應用程式入口
├── config/
│   ├── database.js         # 資料庫設定
│   ├── redis.js            # Redis 設定
│   └── index.js            # 設定檔入口
├── migrations/             # 資料庫遷移檔案
├── seeds/                  # 種子資料
├── tests/                  # 測試檔案
├── docs/                   # 文件
├── monitoring/             # 監控設定
├── docker-compose.yml      # Docker Compose 設定
├── Dockerfile              # Docker 映像檔
├── package.json            # 依賴管理
└── README.md              # 專案說明
```

## 開發指南

### 本地開發

1. **啟動開發環境**
```bash
npm run dev
```

2. **執行測試**
```bash
# 執行所有測試
npm test

# 執行測試並產生覆蓋率報告
npm run test:coverage

# 執行特定測試
npm run test:unit
npm run test:integration
```

3. **程式碼品質檢查**
```bash
# ESLint 檢查
npm run lint

# 程式碼格式化
npm run format

# 型別檢查（如果使用 TypeScript）
npm run type-check
```

### 資料庫管理

```bash
# 建立新的遷移檔案
npm run db:migration:create <migration_name>

# 執行遷移
npm run db:migrate

# 回滾遷移
npm run db:rollback

# 重置資料庫
npm run db:reset
```

### 佇列管理

```bash
# 啟動佇列工作器
npm run queue:worker

# 檢視佇列狀態
npm run queue:status

# 清空佇列
npm run queue:clear
```

## 部署指南

### Docker 部署

1. **建立 Docker 映像檔**
```bash
docker build -t amazon-monitor .
```

2. **使用 Docker Compose 部署**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### 環境設定

不同環境的設定檔案：
- `docker-compose.yml` - 開發環境
- `docker-compose.prod.yml` - 生產環境
- `docker-compose.test.yml` - 測試環境

### 健康檢查

系統提供多個健康檢查端點：

```bash
# 基本健康檢查
curl http://localhost:3000/health

# 詳細系統狀態
curl http://localhost:3000/health/detailed

# 就緒狀態檢查
curl http://localhost:3000/ready
```

## 監控與日誌

### Prometheus 指標

系統暴露以下 Prometheus 指標：

- `http_request_duration_seconds` - HTTP 請求時間
- `active_users_total` - 活躍用戶數
- `queue_length_total` - 佇列長度
- `database_connections_active` - 資料庫連接數

訪問指標：`http://localhost:3000/metrics`

### Grafana 儀表板

預設提供以下儀表板：

- 系統效能監控
- API 請求統計
- 資料庫效能
- 佇列狀態
- 用戶行為分析

訪問 Grafana：`http://localhost:3000` (預設密碼請查看 `.env`)

### 日誌管理

系統使用結構化日誌記錄：

```javascript
// 日誌範例
logger.info('Product updated', {
  event: 'product_updated',
  productId: 'uuid',
  changes: ['price', 'bsr'],
  userId: 'user-uuid',
  timestamp: new Date().toISOString()
});
```

日誌檔案位置：
- `logs/combined.log` - 所有日誌
- `logs/error.log` - 錯誤日誌
- `logs/access.log` - 存取日誌

## 安全性

### 安全措施

1. **認證與授權**
   - JWT Token 認證
   - 角色基礎存取控制（RBAC）
   - API Rate Limiting

2. **資料保護**
   - 敏感資料加密
   - HTTPS 強制使用
   - SQL 注入防護

3. **輸入驗證**
   - 請求參數驗證
   - XSS 防護
   - CSRF 保護

### 安全配置

```javascript
// 安全標頭設定
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true
  }
}));
```

## 效能優化

### 快取策略

- **L1 快取**: 記憶體快取（熱門資料）
- **L2 快取**: Redis 快取（共享資料）
- **L3 快取**: CDN 快取（靜態資源）

### 資料庫優化

- 索引策略優化
- 查詢效能監控
- 連接池管理
- 資料分區策略

### API 優化

- 回應壓縮
- 批次處理
- 分頁查詢
- 條件式請求

## 測試策略

### 測試類型

1. **單元測試** - 個別函數和模組測試
2. **整合測試** - API 端點測試
3. **效能測試** - 負載和壓力測試
4. **安全測試** - 安全漏洞掃描

### 測試覆蓋率目標

- 單元測試：> 80%
- 整合測試：> 70%
- API 測試：100% 端點覆蓋

## 故障排除

### 常見問題

1. **資料庫連接失敗**
```bash
# 檢查資料庫狀態
docker-compose ps postgres
docker-compose logs postgres
```

2. **Redis 連接問題**
```bash
# 檢查 Redis 狀態
docker-compose ps redis
redis-cli ping
```

3. **API 呼叫失敗**
```bash
# 檢查 API 金鑰設定
echo $APIFY_TOKEN
echo $OPENAI_API_KEY
```

4. **記憶體使用過高**
```bash
# 監控記憶體使用
docker stats
node --max-old-space-size=4096 src/app.js
```

### 日誌分析

```bash
# 查看錯誤日誌
tail -f logs/error.log

# 搜尋特定錯誤
grep "ERROR" logs/combined.log

# 分析 API 效能
grep "slow_query" logs/combined.log
```

## 貢獻指南

### 開發流程

1. Fork 專案
2. 建立功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交變更 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟 Pull Request

### 程式碼規範

- 使用 ESLint 和 Prettier
- 遵循 Conventional Commits 規範
- 新增功能需要包含測試
- 文件更新與程式碼同步

## 授權條款

本專案採用 MIT 授權條款 - 詳見 [LICENSE](LICENSE) 檔案

## 聯絡資訊

- **專案負責人**: [Your Name]
- **Email**: [your.email@example.com]
- **專案網址**: [https://github.com/your-username/amazon-monitor]

## 致謝

感謝以下專案和服務：

- [Supabase](https://supabase.com/) - 提供資料庫服務
- [Apify](https://apify.com/) - 提供網路爬蟲服務
- [OpenAI](https://openai.com/) - 提供 AI 分析能力
- [Express.js](https://expressjs.com/) - Web 框架
- [Redis](https://redis.io/) - 快取和佇列服務

---

## 更新日誌

### v1.0.0 (2024-01-15)
- 初始版本發布
- 完成核心產品追蹤功能
- 實現競品分析引擎
- 添加 AI 優化建議功能
- 完整的監控和日誌系統

---

**注意**: 這是一個技術評測專案，展示系統架構設計和開發能力。所有 API 金鑰和敏感資訊請妥善保管，不要提交到版本控制系統。
