# 📚 Amazon Pilot 技術文檔

## 🚀 項目簡介

Amazon Pilot 是一個為 Amazon 賣家設計的產品監控與優化工具，提供產品追蹤、競品分析和智能優化建議功能。

### 🎯 核心功能
1. **產品資料追蹤系統** - 追蹤價格、BSR、評分、評論數變化
2. **競品分析引擎** - 多維度競品對比 + LLM 競爭洞察報告
3. **異常檢測通知** - 自動檢測價格變動 >10%, BSR變動 >30%
4. **實時監控儀表板** - Prometheus + Grafana 完整監控體系

### 🛠️ 技術架構
- **後端**: Go + go-zero 微服務架構
- **數據庫**: PostgreSQL (主庫) + Redis (緩存/隊列)
- **前端**: Next.js 14 + React 18 + TypeScript
- **部署**: Docker + GitHub Actions CI/CD
- **監控**: Prometheus + Grafana + Loki + 結構化日誌
- **數據源**: Apify API (真實 Amazon 數據) + DeepSeek LLM

## 🚀 快速開始

### 一鍵啟動演示
```bash
# 1. 確保在項目根目錄
cd /Users/yangyao/work/github/amazon-pilot/

# 2. 一鍵啟動所有服務
./scripts/service-manager.sh start

# 3. 訪問應用
# Frontend: http://localhost:4000
# API Gateway: http://localhost:8080
# Grafana: http://localhost:3001 (admin/admin123)

# 4. 查看服務狀態
./scripts/service-manager.sh status

# 5. 停止服務
./scripts/service-manager.sh stop
```

### 生產環境部署
```bash
# 自動部署 (推送到 main 分支觸發)
git push origin main

# 訪問生產環境
https://amazon-pilot.phpman.top
```

## 🎯 文檔概覽

本目錄包含 Amazon Pilot 項目的所有技術設計文檔，每個文檔都是系統設計的 **source of truth**。

## 📋 核心設計文檔

### 🏗️ 系統架構
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - 完整的系統架構設計
  - 微服務架構設計原則
  - 技術棧選型說明
  - 數據流向和部署架構
  - 安全性架構 (Caddy HTTPS, JWT 認證)
  - 性能優化和擴展策略

### 🔌 API 設計
- **[API_DESIGN.md](./API_DESIGN.md)** - RESTful API 設計規範
  - API 版本化策略 (go-zero)
  - 統一錯誤代碼規範 (9種標準錯誤)
  - 認證授權機制 (JWT)
  - Rate Limiting 策略
  - 完整的端點設計和使用指南

### 🗃️ 數據庫設計
- **[DATABASE_DESIGN.md](./DATABASE_DESIGN.md)** - 完整的數據庫架構
  - ERD 實體關聯圖 (Mermaid 格式)
  - 完整的表結構定義
  - 按月分區策略 (時間序列數據)
  - 索引和約束設計
  - 性能優化方案

### 🔌 API 文檔
- **[go-zero .api 文件](../api/openapi/)** - API 定義文檔 (Source of Truth)
  - `auth.api` - 認證服務 API (2.7KB)
  - `product.api` - 產品追蹤 API (8.6KB)
  - `competitor.api` - 競品分析 API (6.7KB)
  - `optimization.api` - 優化建議 API (3.9KB)

**go-zero API 文件特性**:
- ✅ **完整的類型定義**: Request/Response 結構
- ✅ **認證配置**: JWT 和中間件配置
- ✅ **路由定義**: RESTful 端點設計
- ✅ **參數驗證**: 內建驗證規則
- ✅ **自動代碼生成**: 使用 `./scripts/goctl-centralized.sh`

*註：go-zero .api 文件比 Swagger 或 Postman Collection 更強大，既是文檔也是代碼生成源*

## 🔧 運維和監控文檔

### 📊 監控體系
- **[MONITORING.md](./MONITORING.md)** - Prometheus + Grafana 監控設計
  - RED 方法論指標設計
  - 完整的 PromQL 查詢配置
  - Grafana Dashboard 配置
  - 告警規則和 SLI/SLO 定義

### 🚀 緩存設計
- **[CACHING.md](./CACHING.md)** - Redis 緩存架構
  - 基於產品維度的分層緩存策略
  - 緩存 Key 設計規範
  - TTL 策略和失效機制
  - 性能監控和優化

## 📖 項目相關文檔

### 🎯 需求和評估
- **[questions.md](./questions.md)** - 原始需求文檔 (面試要求)
- **[EVALUATION_REPORT.md](./EVALUATION_REPORT.md)** - 項目評估報告
- **[DESIGN_DECISIONS.md](./DESIGN_DECISIONS.md)** - 技術決策說明
- **[ARCHITECTURE_DIAGRAMS.md](./ARCHITECTURE_DIAGRAMS.md)** - 架構圖表文檔

## 🚨 重要提醒

### 📋 開發前必讀清單
在進行任何代碼修改前，請務必查看相關文檔：

1. **系統架構修改** → 查看 `ARCHITECTURE.md`
2. **API 端點修改** → 查看 `API_DESIGN.md`
3. **數據庫變更** → 查看 `DATABASE_DESIGN.md`
4. **緩存策略** → 查看 `CACHING.md`
5. **監控指標** → 查看 `MONITORING.md`

### 🔄 文檔更新原則
- **先文檔後代碼**: 技術方案必須先在文檔中說明
- **保持同步**: 代碼變更後及時更新對應文檔
- **設計驅動**: 文檔是 source of truth，必須參考後再決策

---

**文檔版本**: v2.0
**最後更新**: 2025-09-16
**維護團隊**: Amazon Pilot Team