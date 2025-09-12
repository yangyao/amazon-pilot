# **【資深全端工程師】Test Case** - 2025.Q3

你的測評 project 是為 Amazon 賣家設計並實作一個產品監控與優化工具。這個工具需要能夠追蹤產品表現、分析競爭對手，並提供優化建議。

重要：我們重視系統架構設計勝過單純的功能實作。請展現你設計可擴展、可維護系統的能力。

- **時間限制**：7天
- **提供資源**：Claude Code 付費帳號 (Max Plan) 、OpenAI API 與 Apify API Token
- **資料庫**：後端資料庫一律使用 Supabase（PostgreSQL）。
- **環境變數**：提交最終 GitHub 連結時，請同時以安全方式提供可用的 `.env` 檔。
- **二次面試 - 現場 Demo**：清楚說明資料流、檢視資料庫結構、說明快取項目…

---

## 挑戰結構

### 第一部分：系統架構設計（必須完成，佔 50%）

針對能夠**追蹤產品表現、分析競爭對手，並提供優化建議**的工具，設計一個完整的後端系統架構，包含以下文件：

1. API 設計文件
    - RESTful API endpoints 設計
    - Request/ Response 格式定義
    - 認證與授權機制
    - Rate limiting 策略
    - 錯誤處理規範
2. 資料庫設計
    - 資料表 schema（使用 PostgreSQL）
    - 索引策略
    - 資料分區考量（如時間序列資料）
    - 資料一致性保證
3. 系統架構圖
    - 元件關係圖
    - 資料流向圖
    - 部署架構（考慮水平擴展）
4. 快取與佇列設計
    - Redis 快取策略（哪些資料要快取、TTL 設定）
    - 任務佇列設計（使用 Celery 或類似工具）
    - 批次處理架構
5. 監控與維運
    - Log 架構設計
    - 關鍵指標定義（SLA、SLO）
    - 錯誤追蹤與告警機制

---

### 第二部分：核心功能實作（選擇 2 項，佔 40%）

從以下 4 個功能中選擇 2 個進行實作：

**選項 1：產品資料追蹤系統**

需求：

- 設計可支援 1000+ 產品的系統架構
- 實作 Demo 時使用 10-20 個同類別產品
- 追蹤項目：
    - 價格變化
    - BSR 趨勢
    - 評分與評論數變化
    - Buy Box 價格
- 更新頻率：每日一次
- 異常變化通知（ie. 價格變動 > 10%、小類別 BSR 變動 > 30）

技術要求：

- 使用 Apify 的 “Actor” 擷取產品資料（可依需求選擇合適的爬蟲，例如 Amazon Product Details、Amazon Reviews、或自建私有 Actor）
- Redis 快取機制（24-48 小時）
- 背景任務排程（每日更新）
- 資料變化追蹤與通知系統

**選項 2：競品分析引擎**

需求：

- 設定主產品（賣家自己的產品）
- 加入 3-5 個競品 URL 進行多維度比較分析：
    - 主產品 vs 各競品的價格差異
    - BSR 排名差距
    - 評分優劣勢
    - 產品特色對比（從產品 bullet points 提取）
- 生成競爭定位報告（LLM)
- 提供 API 查詢競品資料

技術要求：

- 平行資料擷取架構
- 資料標準化處理
- 比較演算法實作
- 報告生成系統

**選項 3：Listing 優化建議生成器**

需求：

- 分析產品當前表現生成優化建議
- 建議類型：
    - 標題優化（加入高搜尋量關鍵字）
    - 定價調整（基於競品價格分析）
    - 產品描述改進（突出差異化）
    - 圖片建議（缺少哪些角度）
- 每個建議附上具體理由
- 優先級排序（哪個改進影響最大）

技術要求：

- 使用 OpenAI API 分析產品資料
- 結構化 prompt 設計
- 建議結果快取
- A/B 測試架構（追蹤改進效果）

---

## 提供的資源

- 鼓勵使用 [Claude Code](https://www.youtube.com/playlist?list=PLf2m23nhTg1P5BsOHUOXyQz5RhfUSSVUi) 進行開發
    - 帳號：experts@transbiz.co
    - [Claude 登入 Magic Link Doc](https://docs.google.com/document/d/1ekvr754whTEcoRyn7hawEUhqXdm5ZvpyFJlqALmA_JQ/edit?usp=sharing)
        
        https://www.loom.com/share/00c38248b7e245dd8807c14b4213674c
        
- API Keys **(請勿將 API Token/Key 上傳至 GitHub)**
    - Apify 帳密
        
        ```jsx
        帳號：account@transbiz.co
        密碼：*LEK7HgOiCkh
        ```
        
    - OpenAI API Key
        
        ```jsx
        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
        ```
        

## 重要提醒

所有資料必須為真實即時資料：

- 必須透過 Apify 的 Actor 取得真實 Amazon 產品資料（例如 Amazon Product Details、Reviews 相關 Actors，或自建私有 Actor）
- 不接受任何 mock data 或假資料
- Demo 時展示的必須是真實抓取的結果

## 交付要求

1. 架構設計文件
    - ARCHITECTURE.md - 系統架構說明
    - API_DESIGN.md - API 設計文件
    - DATABASE_DESIGN.md - 資料庫設計
    - 架構圖（使用 [draw.io](http://draw.io/) 或類似工具）
2. 程式碼實作
    - 選擇的 2 個功能的完整實作
    - 單元測試（至少 70% coverage）
    - Docker Compose 部署設定
    - .env.example 檔案
3. 文件說明
    - README.md - 專案說明與執行步驟
    - DESIGN_DECISIONS.md - 技術決策說明
    - API 文件（Swagger 或 Postman collection）
4. Demo 影片（5-10 分鐘）
    - 系統架構講解（3-5 分鐘）
    - 功能展示（2-3 分鐘，使用真實資料）
    - 擴展性說明（2 分鐘）

## Demo 產品選擇

建議選擇同一類別產品進行測試，例如：

- 無線藍牙耳機類別
- 瑜珈墊類別
- 廚房用品類別
- 寵物用品類別

## 評分標準

| 項目 | 權重 | 評估重點 |
| --- | --- | --- |
| 系統架構設計 | 40% | 可擴展性、可維護性、效能考量 |
| 程式碼品質 | 30% | 遵循 SOLID、DRY、程式碼組織 |
| 問題解決能力 | 20% | 技術決策、錯誤處理、邊界案例 |
| 文件完整性 | 10% | 清晰度、完整性、可執行性 |

## 加分項目

- 效能優化：展示具體的效能測試與優化
- 安全考量：API 安全、資料加密、OWASP 實踐
- CI/CD：自動化測試與部署流程
- 監控設計：Prometheus + Grafana 整合
- 成本意識：API 使用效率、快取策略

## 補充規範（Submission Add-ons）

- 使用 Supabase
    - 後端資料庫使用 Supabase（PostgreSQL）。免費方案即可。
    - 請提供 Supabase 專案的讀取或檢視權限邀請，或提供可重現的資料表建置腳本，方便我們預先檢視資料表與欄位設計。
    - 需附上資料庫結構說明：ERD 圖或 SQL schema dump（其一）。
- 提交 GitHub 的同時，提供可用的 .env 檔案
    - 請勿將任何金鑰提交到 GitHub 儲存庫。以壓縮檔形式，透過 Email 提供即可。
- 二面現場 Demo 要求
    - 現場完整 Demo，請能清楚說明資料流：資料從哪裡輸入、經過哪些服務、儲存在哪裡、在哪裡可看到日誌。
    - 現場開啟資料庫介面，說明資料表與欄位設計依據（例如 Firecrawl 抓取資料的正規化策略與擴充考量）。
    - 若有使用快取（Redis），請說明快取了哪些資料、TTL 設定與合理性。
    - 若實作加分項（如 log 監控、儀表板），請現場操作展示。
    - 準備好一鍵啟動的指令與最小測試資料，以確保 Demo 流程順暢。

## 注意事項

1. 架構優先：請先完成架構設計再開始實作
2. 程式碼品質：使用 linter 和 formatter
3. 測試覆蓋：關鍵邏輯必須有測試
4. 文件驅動：先寫文件再寫程式碼
5. 真實資料：所有展示必須使用真實 Amazon 產品資料

## 提示

- 使用 Claude Code 幫助您快速實作，但架構設計需要您的思考
- 考慮真實世界的限制：API rate limits、成本、延遲
- 不要過度設計，但要考慮未來擴展
- 參考 KISS、DRY、YAGNI 原則
- 善用快取減少 API 調用，但要標註資料新鮮度

## 常見問題

Q: 可以使用 Claude Code 到什麼程度？
A: 任何程度，我們評估的是最後的結果，不是過程。

Q: 必須實作所有 API endpoints 嗎？
A: 不用。實作核心功能即可，但 API 設計文件要完整。

Q: 資料庫一定要用 PostgreSQL 嗎？
A: 是的，但可以搭配 Redis 作為快取。

Q: Demo 一定要用真實資料嗎？
A: 是的，必須透過 Apify 的付費 Actor 抓取真實 Amazon 產品資料（或自建私有 Actor），不接受 mock data。

---

祝您挑戰順利！我們期待看到您的系統設計能力。
