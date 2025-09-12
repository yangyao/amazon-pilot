# 快取與佇列設計文件

## 概述

本文件詳細描述 Amazon 賣家產品監控與優化工具的快取與佇列架構設計，包含 Redis 快取策略、任務佇列管理和批次處理架構。

## 快取架構設計

### 1. 多層次快取策略

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   L1 Cache      │    │   L2 Cache      │    │   L3 Cache      │
│  (In-Memory)    │    │    (Redis)      │    │  (Database)     │
│                 │    │                 │    │                 │
│ • 熱門產品資料   │    │ • 用戶會話       │    │ • 持久化資料     │
│ • API 回應快取   │    │ • 產品歷史資料   │    │ • 完整產品資訊   │
│ • 計算結果      │    │ • 分析結果       │    │ • 用戶偏好設定   │
│                 │    │ • 通知佇列       │    │                 │
│ TTL: 5-30 分鐘  │    │ TTL: 1-24 小時  │    │ 永久儲存        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 2. Redis 快取命名規範

#### 命名模式
```
{namespace}:{entity}:{identifier}[:{params}]
```

#### 快取鍵範例
```redis
# 產品基本資料
product:basic:B08N5WRWNW
product:price:B08N5WRWNW:current
product:history:uuid-123:price:30d

# 用戶相關資料
user:profile:user-uuid-456
user:tracked:user-uuid-456:active
user:settings:user-uuid-456

# 分析結果
analysis:competitor:analysis-uuid-789
analysis:optimization:product-uuid-123

# 系統快取
system:config:global
system:stats:daily:2024-01-15

# API 限流
rate_limit:user-uuid-456:api_calls:minute
rate_limit:ip:192.168.1.1:login_attempts:hour
```

### 3. TTL 策略設計

```javascript
const TTL_CONFIG = {
  // 產品資料快取
  PRODUCT_BASIC: 24 * 60 * 60,        // 24 小時 - 基本資料變動較少
  PRODUCT_PRICE: 4 * 60 * 60,         // 4 小時 - 價格變動較頻繁
  PRODUCT_RANKING: 6 * 60 * 60,       // 6 小時 - BSR 每日更新
  PRODUCT_REVIEWS: 12 * 60 * 60,      // 12 小時 - 評論累積較慢
  
  // 歷史資料快取
  HISTORY_PRICE_30D: 2 * 60 * 60,     // 2 小時 - 短期歷史
  HISTORY_PRICE_1Y: 24 * 60 * 60,     // 24 小時 - 長期歷史
  HISTORY_TREND: 6 * 60 * 60,         // 6 小時 - 趨勢分析
  
  // 用戶相關快取
  USER_PROFILE: 60 * 60,              // 1 小時 - 用戶資料
  USER_TRACKED_LIST: 30 * 60,         // 30 分鐘 - 追蹤列表
  USER_SETTINGS: 4 * 60 * 60,         // 4 小時 - 用戶設定
  USER_NOTIFICATIONS: 15 * 60,        // 15 分鐘 - 通知列表
  
  // 分析結果快取
  COMPETITOR_ANALYSIS: 6 * 60 * 60,    // 6 小時 - 競品分析
  OPTIMIZATION_SUGGESTIONS: 4 * 60 * 60, // 4 小時 - 優化建議
  ANALYSIS_REPORT: 24 * 60 * 60,       // 24 小時 - 完整報告
  
  // API 相關快取
  API_RESPONSE: 10 * 60,               // 10 分鐘 - API 回應
  SEARCH_RESULTS: 30 * 60,             // 30 分鐘 - 搜尋結果
  
  // 系統快取
  SYSTEM_CONFIG: 60 * 60,              // 1 小時 - 系統設定
  RATE_LIMIT_MINUTE: 60,               // 1 分鐘 - 分鐘級限流
  RATE_LIMIT_HOUR: 60 * 60,            // 1 小時 - 小時級限流
  RATE_LIMIT_DAY: 24 * 60 * 60,        // 1 天 - 日級限流
  
  // 會話管理
  USER_SESSION: 7 * 24 * 60 * 60,      // 7 天 - 用戶會話
  API_TOKEN: 24 * 60 * 60,             // 24 小時 - API Token
  
  // 臨時資料
  TEMP_DATA: 5 * 60,                   // 5 分鐘 - 臨時資料
  LOCK: 30,                            // 30 秒 - 分散式鎖
};
```

### 4. 快取實作架構

```python
import redis.asyncio as redis
import json
import asyncio
from typing import Any, Optional, Dict, List
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

class CacheManager:
    def __init__(self, redis_url: str = "redis://localhost:6379/0"):
        self.redis_client = redis.from_url(redis_url)
        self.local_cache = {}  # L1 快取
        self.stats = {
            "hits": 0,
            "misses": 0,
            "errors": 0
        }
        self._local_cache_ttl = {}
    
    async def initialize(self):
        """初始化 Redis 連接"""
        try:
            await self.redis_client.ping()
            logger.info("Redis 連接成功")
        except Exception as e:
            logger.error(f"Redis 連接失敗: {e}")
            raise

    # 快取讀取 - Cache-Aside Pattern
    async def get(self, key: str, options: Optional[Dict] = None) -> Optional[Any]:
        """獲取快取資料"""
        if options is None:
            options = {}
        
        start_time = datetime.now()
        
        try:
            # L1 快取檢查
            if key in self.local_cache:
                if self._is_local_cache_valid(key):
                    self.stats["hits"] += 1
                    return self.local_cache[key]
                else:
                    # 過期則刪除
                    del self.local_cache[key]
                    if key in self._local_cache_ttl:
                        del self._local_cache_ttl[key]

            # L2 快取檢查 (Redis)
            cached = await self.redis_client.get(key)
            if cached:
                data = json.loads(cached)
                
                # 回填 L1 快取
                if options.get("use_local_cache", True):
                    self.local_cache[key] = data
                    local_ttl = options.get("local_ttl", 5 * 60)  # 5分鐘
                    self._local_cache_ttl[key] = datetime.now() + timedelta(seconds=local_ttl)
                
                self.stats["hits"] += 1
                return data

            self.stats["misses"] += 1
            return None
            
        except Exception as error:
            self.stats["errors"] += 1
            logger.error(f"Cache get error: {error}", extra={"key": key})
            return None
        finally:
            duration = (datetime.now() - start_time).total_seconds()
            self._record_metrics("cache_get_duration", duration)
    
    def _is_local_cache_valid(self, key: str) -> bool:
        """檢查 L1 快取是否有效"""
        if key not in self._local_cache_ttl:
            return False
        return datetime.now() < self._local_cache_ttl[key]

    # 快取寫入
    async def set(self, key: str, value: Any, ttl: int = 3600, options: Optional[Dict] = None) -> bool:
        """設定快取資料"""
        if options is None:
            options = {}
        
        try:
            serialized = json.dumps(value, ensure_ascii=False)
            
            # 寫入 Redis
            if ttl > 0:
                await self.redis_client.setex(key, ttl, serialized)
            else:
                await self.redis_client.set(key, serialized)
            
            # 寫入 L1 快取
            if options.get("use_local_cache", True):
                self.local_cache[key] = value
                local_ttl = min(ttl, 5 * 60)  # 最多5分鐘
                self._local_cache_ttl[key] = datetime.now() + timedelta(seconds=local_ttl)
            
            return True
            
        except Exception as error:
            logger.error(f"Cache set error: {error}", extra={"key": key})
            return False

  // Write-Through Pattern - 同時寫入快取和資料庫
  async setWithWriteThrough(key, value, ttl, updateFn) {
    try {
      // 先更新資料庫
      await updateFn(value);
      
      // 再更新快取
      await this.set(key, value, ttl);
      
      return true;
    } catch (error) {
      logger.error('Write-through error', { key, error: error.message });
      throw error;
    }
  }

  // Write-Behind Pattern - 異步寫入資料庫
  async setWithWriteBehind(key, value, ttl, updateFn) {
    try {
      // 立即更新快取
      await this.set(key, value, ttl);
      
      // 異步更新資料庫
      setImmediate(async () => {
        try {
          await updateFn(value);
        } catch (error) {
          logger.error('Write-behind error', { key, error: error.message });
          // 考慮重試或加入錯誤佇列
        }
      });
      
      return true;
    } catch (error) {
      logger.error('Write-behind cache error', { key, error: error.message });
      throw error;
    }
  }

  // 批次獲取
  async mget(keys) {
    try {
      const result = {};
      const missedKeys = [];
      
      // 檢查 L1 快取
      for (const key of keys) {
        if (this.localCache.has(key)) {
          result[key] = this.localCache.get(key);
        } else {
          missedKeys.push(key);
        }
      }
      
      // 批次獲取 Redis 快取
      if (missedKeys.length > 0) {
        const cached = await this.redis.mget(...missedKeys);
        
        for (let i = 0; i < missedKeys.length; i++) {
          const key = missedKeys[i];
          const value = cached[i];
          
          if (value) {
            const data = JSON.parse(value);
            result[key] = data;
            this.localCache.set(key, data);
          }
        }
      }
      
      return result;
    } catch (error) {
      logger.error('Cache mget error', { keys, error: error.message });
      return {};
    }
  }

  // 快取失效
  async invalidate(pattern) {
    try {
      if (pattern.includes('*')) {
        // 批次刪除
        const keys = await this.redis.keys(pattern);
        if (keys.length > 0) {
          await this.redis.del(...keys);
          
          // 清除 L1 快取中匹配的項目
          for (const key of this.localCache.keys()) {
            if (this.matchPattern(key, pattern)) {
              this.localCache.delete(key);
            }
          }
        }
        return keys.length;
      } else {
        // 單個刪除
        await this.redis.del(pattern);
        this.localCache.delete(pattern);
        return 1;
      }
    } catch (error) {
      logger.error('Cache invalidate error', { pattern, error: error.message });
      return 0;
    }
  }

  // 快取預熱
  async warmup(warmupFunctions) {
    logger.info('Starting cache warmup');
    
    const results = await Promise.allSettled(
      warmupFunctions.map(fn => fn())
    );
    
    const successful = results.filter(r => r.status === 'fulfilled').length;
    const failed = results.length - successful;
    
    logger.info('Cache warmup completed', { successful, failed });
    return { successful, failed };
  }

  // 獲取快取統計
  getStats() {
    const hitRate = this.stats.hits / (this.stats.hits + this.stats.misses) || 0;
    
    return {
      ...this.stats,
      hitRate: Math.round(hitRate * 100) / 100,
      localCacheSize: this.localCache.size
    };
  }
}
```

## 佇列架構設計

### 1. 任務佇列分類

```javascript
const QUEUE_CONFIG = {
  // 高優先級佇列 - 即時處理
  HIGH_PRIORITY: {
    name: 'high-priority',
    concurrency: 10,
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 2000,
    },
    removeOnComplete: 20,
    removeOnFail: 10,
  },
  
  // 產品更新佇列 - 定期處理
  PRODUCT_UPDATE: {
    name: 'product-update',
    concurrency: 5,
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 5000,
    },
    removeOnComplete: 10,
    removeOnFail: 5,
  },
  
  // 分析佇列 - 計算密集
  ANALYSIS: {
    name: 'analysis',
    concurrency: 2,
    attempts: 2,
    backoff: {
      type: 'fixed',
      delay: 10000,
    },
    removeOnComplete: 5,
    removeOnFail: 3,
  },
  
  // 通知佇列 - 低優先級
  NOTIFICATION: {
    name: 'notification',
    concurrency: 20,
    attempts: 5,
    backoff: {
      type: 'exponential',
      delay: 1000,
    },
    removeOnComplete: 50,
    removeOnFail: 20,
  },
  
  // 清理佇列 - 批次處理
  CLEANUP: {
    name: 'cleanup',
    concurrency: 1,
    attempts: 1,
    removeOnComplete: 5,
    removeOnFail: 5,
  }
};
```

### 2. 佇列管理器實作

```go
package queue

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/hibiken/asynq"
    "github.com/zeromicro/go-zero/core/logx"
)

type QueueManager struct {
    client   *asynq.Client
    server   *asynq.Server
    scheduler *asynq.Scheduler
}

type TaskPayload struct {
    ProductID    string                 `json:"product_id,omitempty"`
    UserID       string                 `json:"user_id,omitempty"`
    AnalysisID   string                 `json:"analysis_id,omitempty"`
    Priority     int                    `json:"priority,omitempty"`
    Metadata     map[string]interface{} `json:"metadata,omitempty"`
}

func NewQueueManager(redisAddr string) *QueueManager {
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
    
    // 創建調度器
    scheduler := asynq.NewScheduler(asynq.RedisClientOpt{Addr: redisAddr}, nil)
    
    qm := &QueueManager{
        client:    client,
        server:    server,
        scheduler: scheduler,
    }
    
    // 設置任務處理器
    qm.setupTaskHandlers()
    
    return qm
}

func (qm *QueueManager) setupTaskHandlers() {
    // 產品更新任務
    qm.server.HandleFunc("update_product", qm.handleUpdateProduct)
    
    // 競品分析任務
    qm.server.HandleFunc("competitor_analysis", qm.handleCompetitorAnalysis)
    
    // 優化建議任務
    qm.server.HandleFunc("optimization_analysis", qm.handleOptimizationAnalysis)
    
    // 通知發送任務
    qm.server.HandleFunc("send_notification", qm.handleSendNotification)
}

func (qm *QueueManager) handleUpdateProduct(ctx context.Context, t *asynq.Task) error {
    var payload TaskPayload
    if err := json.Unmarshal(t.Payload(), &payload); err != nil {
        return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
    }

    logx.Infof("Processing update product task: %s", payload.ProductID)

    // 執行產品更新邏輯
    if err := qm.updateProductData(payload.ProductID); err != nil {
        return fmt.Errorf("update product failed: %v", err)
    }

    logx.Infof("Successfully updated product: %s", payload.ProductID)
    return nil
}

func (qm *QueueManager) handleCompetitorAnalysis(ctx context.Context, t *asynq.Task) error {
    var payload TaskPayload
    if err := json.Unmarshal(t.Payload(), &payload); err != nil {
        return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
    }

    logx.Infof("Processing competitor analysis task: %s", payload.AnalysisID)

    // 執行競品分析邏輯
    if err := qm.performCompetitorAnalysis(payload.AnalysisID); err != nil {
        return fmt.Errorf("competitor analysis failed: %v", err)
    }

    logx.Infof("Successfully completed competitor analysis: %s", payload.AnalysisID)
    return nil
}

func (qm *QueueManager) handleOptimizationAnalysis(ctx context.Context, t *asynq.Task) error {
    var payload TaskPayload
    if err := json.Unmarshal(t.Payload(), &payload); err != nil {
        return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
    }

    logx.Infof("Processing optimization analysis task: %s", payload.ProductID)

    // 執行優化分析邏輯
    if err := qm.performOptimizationAnalysis(payload.ProductID); err != nil {
        return fmt.Errorf("optimization analysis failed: %v", err)
    }

    logx.Infof("Successfully completed optimization analysis: %s", payload.ProductID)
    return nil
}

func (qm *QueueManager) handleSendNotification(ctx context.Context, t *asynq.Task) error {
    var payload TaskPayload
    if err := json.Unmarshal(t.Payload(), &payload); err != nil {
        return fmt.Errorf("json.Unmarshal failed: %v: %w", err, asynq.SkipRetry)
    }

    logx.Infof("Processing send notification task: %s", payload.UserID)

    // 執行通知發送邏輯
    if err := qm.sendNotification(payload.UserID, payload.Metadata); err != nil {
        return fmt.Errorf("send notification failed: %v", err)
    }

    logx.Infof("Successfully sent notification: %s", payload.UserID)
    return nil
}
                # 執行產品更新邏輯
                result = asyncio.run(self._update_product(product_id))
                return {"status": "success", "product_id": product_id, "result": result}
            except Exception as exc:
                logger.error(f"產品更新失敗: {exc}")
                raise self.retry(exc=exc, countdown=60 * (2 ** self.request.retries))
        
        # 競品分析任務
        @self.celery_app.task(bind=True, max_retries=2)
        def competitor_analysis_task(self, analysis_id: str):
            """執行競品分析"""
            try:
                result = asyncio.run(self._run_competitor_analysis(analysis_id))
                return {"status": "success", "analysis_id": analysis_id, "result": result}
            except Exception as exc:
                logger.error(f"競品分析失敗: {exc}")
                raise self.retry(exc=exc, countdown=120 * (2 ** self.request.retries))
        
        # 通知發送任務
        @self.celery_app.task(bind=True, max_retries=5)
        def send_notification_task(self, notification_data: Dict[str, Any]):
            """發送通知"""
            try:
                result = asyncio.run(self._send_notification(notification_data))
                return {"status": "success", "notification_id": notification_data.get("id")}
            except Exception as exc:
                logger.error(f"通知發送失敗: {exc}")
                raise self.retry(exc=exc, countdown=30 * (2 ** self.request.retries))
    
    def _setup_schedules(self):
        """設置定期任務"""
        self.celery_app.conf.beat_schedule = {
            'daily-product-update': {
                'task': 'amazon_monitor.tasks.product_tasks.schedule_all_updates',
                'schedule': crontab(hour=9, minute=0),  # 每日上午 9 點
            },
            'hourly-high-freq-update': {
                'task': 'amazon_monitor.tasks.product_tasks.update_high_frequency_products',
                'schedule': crontab(minute=0),  # 每小時
            },
            'weekly-competitor-analysis': {
                'task': 'amazon_monitor.tasks.analysis_tasks.schedule_weekly_analysis',
                'schedule': crontab(hour=2, minute=0, day_of_week=0),  # 週日凌晨 2 點
            },
            'daily-cleanup': {
                'task': 'amazon_monitor.tasks.cleanup_tasks.daily_cleanup',
                'schedule': crontab(hour=3, minute=0),  # 每日凌晨 3 點
            },
        }

  setupWorker(queueKey, queue, config) {
    const worker = queue.process('*', config.concurrency, async (job) => {
      return await this.processJob(queueKey, job);
    });
    
    // 錯誤處理
    worker.on('error', (error) => {
      logger.error('Queue worker error', { 
        queue: queueKey, 
        error: error.message 
      });
    });
    
    // 任務完成事件
    worker.on('completed', (job, result) => {
      logger.info('Job completed', { 
        queue: queueKey, 
        jobId: job.id,
        duration: Date.now() - job.timestamp 
      });
    });
    
    // 任務失敗事件
    worker.on('failed', (job, error) => {
      logger.error('Job failed', { 
        queue: queueKey, 
        jobId: job.id,
        error: error.message,
        attempts: job.attemptsMade 
      });
    });
    
    this.workers.set(queueKey, worker);
  }

  async processJob(queueKey, job) {
    const { type, data } = job.data;
    
    try {
      switch (queueKey) {
        case 'HIGH_PRIORITY':
          return await this.processHighPriorityJob(type, data);
        case 'PRODUCT_UPDATE':
          return await this.processProductUpdateJob(type, data);
        case 'ANALYSIS':
          return await this.processAnalysisJob(type, data);
        case 'NOTIFICATION':
          return await this.processNotificationJob(type, data);
        case 'CLEANUP':
          return await this.processCleanupJob(type, data);
        default:
          throw new Error(`Unknown queue: ${queueKey}`);
      }
    } catch (error) {
      logger.error('Job processing error', {
        queue: queueKey,
        type,
        error: error.message
      });
      throw error;
    }
  }

  // 高優先級任務處理
  async processHighPriorityJob(type, data) {
    switch (type) {
      case 'price_alert':
        return await this.handlePriceAlert(data);
      case 'system_alert':
        return await this.handleSystemAlert(data);
      case 'user_action':
        return await this.handleUserAction(data);
      default:
        throw new Error(`Unknown high priority job type: ${type}`);
    }
  }

  // 產品更新任務處理
  async processProductUpdateJob(type, data) {
    switch (type) {
      case 'update_product':
        return await this.updateProduct(data.productId);
      case 'batch_update':
        return await this.batchUpdateProducts(data.productIds);
      case 'sync_product_data':
        return await this.syncProductData(data.asin);
      default:
        throw new Error(`Unknown product update job type: ${type}`);
    }
  }

  // 分析任務處理
  async processAnalysisJob(type, data) {
    switch (type) {
      case 'competitor_analysis':
        return await this.runCompetitorAnalysis(data.analysisId);
      case 'optimization_analysis':
        return await this.runOptimizationAnalysis(data.productId);
      case 'trend_analysis':
        return await this.runTrendAnalysis(data.timeRange);
      default:
        throw new Error(`Unknown analysis job type: ${type}`);
    }
  }

  // 任務排隊方法
  async addJob(queueKey, jobType, data, options = {}) {
    const queue = this.queues.get(queueKey);
    if (!queue) {
      throw new Error(`Queue not found: ${queueKey}`);
    }

    const jobData = {
      type: jobType,
      data,
      createdAt: new Date().toISOString(),
      userId: options.userId,
    };

    const jobOptions = {
      priority: options.priority || 0,
      delay: options.delay || 0,
      repeat: options.repeat,
      jobId: options.jobId,
    };

    const job = await queue.add(jobType, jobData, jobOptions);
    
    logger.info('Job added to queue', {
      queue: queueKey,
      jobType,
      jobId: job.id,
      priority: jobOptions.priority
    });

    return job;
  }

  // 批次任務處理
  async addBatchJobs(queueKey, jobs) {
    const queue = this.queues.get(queueKey);
    if (!queue) {
      throw new Error(`Queue not found: ${queueKey}`);
    }

    const batchJobs = jobs.map(job => ({
      name: job.type,
      data: {
        type: job.type,
        data: job.data,
        createdAt: new Date().toISOString(),
      },
      opts: job.options || {}
    }));

    const addedJobs = await queue.addBulk(batchJobs);
    
    logger.info('Batch jobs added', {
      queue: queueKey,
      count: addedJobs.length
    });

    return addedJobs;
  }
}
```

### 3. 任務調度器

```javascript
class TaskScheduler {
  constructor(queueManager) {
    this.queueManager = queueManager;
    this.schedules = new Map();
    this.cron = require('node-cron');
  }

  // 定期任務註冊
  registerSchedule(name, cronExpression, taskFn) {
    const task = this.cron.schedule(cronExpression, async () => {
      try {
        logger.info('Scheduled task started', { name });
        await taskFn();
        logger.info('Scheduled task completed', { name });
      } catch (error) {
        logger.error('Scheduled task failed', { 
          name, 
          error: error.message 
        });
      }
    }, {
      scheduled: false,
      timezone: 'Asia/Taipei'
    });
    
    this.schedules.set(name, task);
    return task;
  }

  // 啟動所有調度任務
  startAll() {
    this.schedules.forEach((task, name) => {
      task.start();
      logger.info('Scheduled task started', { name });
    });
  }

  // 停止所有調度任務
  stopAll() {
    this.schedules.forEach((task, name) => {
      task.stop();
      logger.info('Scheduled task stopped', { name });
    });
  }

  // 預定義調度任務
  setupDefaultSchedules() {
    // 每日產品更新 - 上午 9 點
    this.registerSchedule('daily-product-update', '0 9 * * *', async () => {
      const activeProducts = await this.getActiveProducts();
      
      for (const product of activeProducts) {
        await this.queueManager.addJob('PRODUCT_UPDATE', 'update_product', {
          productId: product.id
        }, {
          priority: this.calculatePriority(product)
        });
      }
    });

    // 每小時高頻產品更新
    this.registerSchedule('hourly-high-freq-update', '0 * * * *', async () => {
      const highFreqProducts = await this.getHighFrequencyProducts();
      
      await this.queueManager.addBatchJobs('PRODUCT_UPDATE', 
        highFreqProducts.map(product => ({
          type: 'update_product',
          data: { productId: product.id },
          options: { priority: 10 }
        }))
      );
    });

    // 每週競品分析 - 週日凌晨 2 點
    this.registerSchedule('weekly-competitor-analysis', '0 2 * * 0', async () => {
      const analysisGroups = await this.getActiveAnalysisGroups();
      
      for (const group of analysisGroups) {
        await this.queueManager.addJob('ANALYSIS', 'competitor_analysis', {
          analysisId: group.id
        }, {
          priority: 5
        });
      }
    });

    // 每日清理任務 - 凌晨 3 點
    this.registerSchedule('daily-cleanup', '0 3 * * *', async () => {
      await this.queueManager.addJob('CLEANUP', 'cleanup_old_data', {
        days: 90
      });
      
      await this.queueManager.addJob('CLEANUP', 'cleanup_cache', {
        pattern: 'temp:*'
      });
    });

    // 每分鐘佇列監控
    this.registerSchedule('queue-monitor', '* * * * *', async () => {
      await this.monitorQueues();
    });
  }

  // 動態優先級計算
  calculatePriority(product) {
    let priority = 0;
    
    // 用戶計劃權重
    const planWeights = { basic: 1, premium: 3, enterprise: 5 };
    priority += planWeights[product.userPlan] || 1;
    
    // 資料新鮮度權重
    const hoursOld = (Date.now() - new Date(product.lastUpdated)) / (1000 * 60 * 60);
    if (hoursOld > 24) priority += 3;
    else if (hoursOld > 12) priority += 2;
    else if (hoursOld > 6) priority += 1;
    
    // 用戶活躍度權重
    if (product.userLastActive > Date.now() - 24 * 60 * 60 * 1000) {
      priority += 2;
    }
    
    return Math.min(priority, 10); // 最大優先級為 10
  }

  // 佇列監控
  async monitorQueues() {
    for (const [queueKey, queue] of this.queueManager.queues) {
      const waiting = await queue.getWaiting();
      const active = await queue.getActive();
      const failed = await queue.getFailed();
      
      // 記錄指標
      prometheus.queueLength.labels(queueKey, 'waiting').set(waiting.length);
      prometheus.queueLength.labels(queueKey, 'active').set(active.length);
      prometheus.queueLength.labels(queueKey, 'failed').set(failed.length);
      
      // 警告條件
      if (waiting.length > 1000) {
        logger.warn('Queue backlog detected', {
          queue: queueKey,
          waiting: waiting.length
        });
      }
      
      if (failed.length > 100) {
        logger.error('High failure rate detected', {
          queue: queueKey,
          failed: failed.length
        });
      }
    }
  }
}
```

## 批次處理架構

### 1. 批次處理策略

```javascript
class BatchProcessor {
  constructor(queueManager, cacheManager) {
    this.queueManager = queueManager;
    this.cacheManager = cacheManager;
    this.batchConfig = {
      maxBatchSize: 50,
      maxWaitTime: 30000, // 30 seconds
      maxConcurrency: 5
    };
  }

  // 批次產品更新
  async batchUpdateProducts(productIds) {
    const batches = this.createBatches(productIds, this.batchConfig.maxBatchSize);
    const results = [];
    
    // 並行處理批次
    const promises = batches.map(async (batch, index) => {
      try {
        logger.info('Processing batch', { 
          batchIndex: index, 
          size: batch.length 
        });
        
        const batchResult = await this.processBatch(batch);
        results.push(...batchResult);
        
        // 批次間延遲避免 API 限流
        if (index < batches.length - 1) {
          await this.delay(1000);
        }
        
      } catch (error) {
        logger.error('Batch processing error', { 
          batchIndex: index, 
          error: error.message 
        });
        throw error;
      }
    });
    
    await Promise.allSettled(promises);
    return results;
  }

  // 處理單一批次
  async processBatch(productIds) {
    const promises = productIds.map(async (productId) => {
      try {
        // 檢查快取
        const cached = await this.cacheManager.get(`product:basic:${productId}`);
        if (cached && this.isFresh(cached)) {
          return cached;
        }
        
        // API 調用
        const productData = await this.fetchProductData(productId);
        
        // 更新快取
        await this.cacheManager.set(
          `product:basic:${productId}`,
          productData,
          TTL_CONFIG.PRODUCT_BASIC
        );
        
        // 更新資料庫
        await this.updateProductInDatabase(productId, productData);
        
        return productData;
        
      } catch (error) {
        logger.error('Product update error', { 
          productId, 
          error: error.message 
        });
        return null;
      }
    });
    
    const results = await Promise.allSettled(promises);
    return results
      .filter(result => result.status === 'fulfilled' && result.value)
      .map(result => result.value);
  }

  // 智能批次大小調整
  async adaptiveBatchSize(queueLength, errorRate) {
    let newBatchSize = this.batchConfig.maxBatchSize;
    
    // 根據佇列長度調整
    if (queueLength > 1000) {
      newBatchSize = Math.min(newBatchSize * 1.5, 100);
    } else if (queueLength < 100) {
      newBatchSize = Math.max(newBatchSize * 0.8, 10);
    }
    
    // 根據錯誤率調整
    if (errorRate > 0.1) {
      newBatchSize = Math.max(newBatchSize * 0.5, 5);
    }
    
    this.batchConfig.maxBatchSize = Math.round(newBatchSize);
    
    logger.info('Batch size adjusted', {
      oldSize: this.batchConfig.maxBatchSize,
      newSize: newBatchSize,
      queueLength,
      errorRate
    });
  }

  createBatches(items, batchSize) {
    const batches = [];
    for (let i = 0; i < items.length; i += batchSize) {
      batches.push(items.slice(i, i + batchSize));
    }
    return batches;
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  isFresh(cachedData, maxAge = 4 * 60 * 60 * 1000) {
    return Date.now() - new Date(cachedData.updatedAt).getTime() < maxAge;
  }
}
```

### 2. 流控制機制

```javascript
class FlowController {
  constructor() {
    this.rateLimiters = new Map();
    this.circuitBreakers = new Map();
  }

  // API 流控制
  async controlAPIFlow(apiName, fn) {
    const rateLimiter = this.getRateLimiter(apiName);
    const circuitBreaker = this.getCircuitBreaker(apiName);
    
    // 檢查斷路器狀態
    if (circuitBreaker.isOpen()) {
      throw new Error(`Circuit breaker open for ${apiName}`);
    }
    
    // 限流檢查
    await rateLimiter.removeTokens(1);
    
    try {
      const result = await circuitBreaker.fire(fn);
      return result;
    } catch (error) {
      logger.error('API call failed', { apiName, error: error.message });
      throw error;
    }
  }

  getRateLimiter(apiName) {
    if (!this.rateLimiters.has(apiName)) {
      const config = this.getRateLimitConfig(apiName);
      const limiter = new RateLimiter(config);
      this.rateLimiters.set(apiName, limiter);
    }
    return this.rateLimiters.get(apiName);
  }

  getCircuitBreaker(apiName) {
    if (!this.circuitBreakers.has(apiName)) {
      const config = this.getCircuitBreakerConfig(apiName);
      const breaker = new CircuitBreaker(config);
      this.circuitBreakers.set(apiName, breaker);
    }
    return this.circuitBreakers.get(apiName);
  }

  getRateLimitConfig(apiName) {
    const configs = {
      'apify': {
        tokensPerInterval: 10,
        interval: 'minute'
      },
      'openai': {
        tokensPerInterval: 100,
        interval: 'minute'
      },
      'database': {
        tokensPerInterval: 1000,
        interval: 'minute'
      }
    };
    
    return configs[apiName] || configs['database'];
  }

  getCircuitBreakerConfig(apiName) {
    const configs = {
      'apify': {
        timeout: 30000,
        errorThresholdPercentage: 50,
        resetTimeout: 60000
      },
      'openai': {
        timeout: 10000,
        errorThresholdPercentage: 30,
        resetTimeout: 30000
      },
      'database': {
        timeout: 5000,
        errorThresholdPercentage: 20,
        resetTimeout: 15000
      }
    };
    
    return configs[apiName] || configs['database'];
  }
}
```

## 監控與維護

### 1. 快取監控

```javascript
class CacheMonitor {
  constructor(cacheManager) {
    this.cacheManager = cacheManager;
    this.metrics = {
      hitRate: 0,
      memoryUsage: 0,
      keyCount: 0,
      evictionCount: 0
    };
  }

  async collectMetrics() {
    const redis = this.cacheManager.redis;
    
    // 基本統計
    const info = await redis.info('stats');
    const memory = await redis.info('memory');
    
    // 解析統計資訊
    this.metrics = {
      hitRate: this.parseHitRate(info),
      memoryUsage: this.parseMemoryUsage(memory),
      keyCount: await redis.dbsize(),
      evictionCount: this.parseEvictions(info)
    };
    
    // 記錄 Prometheus 指標
    prometheus.cacheHitRate.set(this.metrics.hitRate);
    prometheus.cacheMemoryUsage.set(this.metrics.memoryUsage);
    prometheus.cacheKeyCount.set(this.metrics.keyCount);
    
    return this.metrics;
  }

  async analyzeKeyDistribution() {
    const redis = this.cacheManager.redis;
    const sample = await redis.randomkey();
    
    if (!sample) return {};
    
    const patterns = {
      'product:*': 0,
      'user:*': 0,
      'analysis:*': 0,
      'system:*': 0,
      'temp:*': 0
    };
    
    // 抽樣分析
    for (let i = 0; i < 1000; i++) {
      const key = await redis.randomkey();
      if (key) {
        for (const pattern of Object.keys(patterns)) {
          if (key.startsWith(pattern.replace('*', ''))) {
            patterns[pattern]++;
            break;
          }
        }
      }
    }
    
    return patterns;
  }

  parseHitRate(info) {
    const lines = info.split('\r\n');
    let hits = 0, misses = 0;
    
    lines.forEach(line => {
      if (line.startsWith('keyspace_hits:')) {
        hits = parseInt(line.split(':')[1]);
      }
      if (line.startsWith('keyspace_misses:')) {
        misses = parseInt(line.split(':')[1]);
      }
    });
    
    return hits + misses > 0 ? hits / (hits + misses) : 0;
  }
}
```

### 2. 佇列監控

```javascript
class QueueMonitor {
  constructor(queueManager) {
    this.queueManager = queueManager;
  }

  async collectQueueMetrics() {
    const metrics = {};
    
    for (const [queueKey, queue] of this.queueManager.queues) {
      const waiting = await queue.getWaiting();
      const active = await queue.getActive();
      const completed = await queue.getCompleted();
      const failed = await queue.getFailed();
      
      metrics[queueKey] = {
        waiting: waiting.length,
        active: active.length,
        completed: completed.length,
        failed: failed.length,
        throughput: await this.calculateThroughput(queue)
      };
      
      // Prometheus 指標
      prometheus.queueSize.labels(queueKey, 'waiting').set(waiting.length);
      prometheus.queueSize.labels(queueKey, 'active').set(active.length);
      prometheus.queueSize.labels(queueKey, 'failed').set(failed.length);
    }
    
    return metrics;
  }

  async calculateThroughput(queue) {
    const oneHourAgo = Date.now() - 60 * 60 * 1000;
    const completed = await queue.getCompleted();
    
    const recentJobs = completed.filter(job => 
      job.finishedOn && job.finishedOn > oneHourAgo
    );
    
    return recentJobs.length; // jobs per hour
  }

  async getSlowJobs(queueKey, threshold = 60000) {
    const queue = this.queueManager.queues.get(queueKey);
    const active = await queue.getActive();
    
    return active.filter(job => 
      Date.now() - job.processedOn > threshold
    );
  }
}
```

### 3. 自動化維護

```javascript
class MaintenanceScheduler {
  constructor(cacheManager, queueManager) {
    this.cacheManager = cacheManager;
    this.queueManager = queueManager;
  }

  scheduleMaintenance() {
    // 每小時快取清理
    cron.schedule('0 * * * *', async () => {
      await this.cleanupExpiredCache();
    });
    
    // 每日佇列清理
    cron.schedule('0 2 * * *', async () => {
      await this.cleanupCompletedJobs();
    });
    
    // 每週效能分析
    cron.schedule('0 3 * * 0', async () => {
      await this.performanceAnalysis();
    });
  }

  async cleanupExpiredCache() {
    const redis = this.cacheManager.redis;
    
    // 清理已過期但未自動刪除的鍵
    const script = `
      local keys = redis.call('keys', '*')
      local cleaned = 0
      for i=1,#keys do
        local ttl = redis.call('ttl', keys[i])
        if ttl == -1 then  -- 沒有設定 TTL 的鍵
          local key = keys[i]
          if string.match(key, '^temp:') then
            redis.call('del', key)
            cleaned = cleaned + 1
          end
        end
      end
      return cleaned
    `;
    
    const cleaned = await redis.eval(script, 0);
    logger.info('Cache cleanup completed', { cleaned });
  }

  async cleanupCompletedJobs() {
    for (const [queueKey, queue] of this.queueManager.queues) {
      try {
        // 清理舊的已完成任務
        await queue.clean(24 * 60 * 60 * 1000, 'completed');
        
        // 清理舊的失敗任務
        await queue.clean(7 * 24 * 60 * 60 * 1000, 'failed');
        
        logger.info('Queue cleanup completed', { queue: queueKey });
      } catch (error) {
        logger.error('Queue cleanup error', { 
          queue: queueKey, 
          error: error.message 
        });
      }
    }
  }

  async performanceAnalysis() {
    const cacheStats = this.cacheManager.getStats();
    const queueMetrics = await this.collectQueueMetrics();
    
    // 生成效能報告
    const report = {
      timestamp: new Date().toISOString(),
      cache: cacheStats,
      queues: queueMetrics,
      recommendations: this.generateRecommendations(cacheStats, queueMetrics)
    };
    
    logger.info('Performance analysis completed', report);
    
    // 儲存報告到資料庫或文件
    await this.savePerformanceReport(report);
  }

  generateRecommendations(cacheStats, queueMetrics) {
    const recommendations = [];
    
    // 快取建議
    if (cacheStats.hitRate < 0.8) {
      recommendations.push({
        type: 'cache',
        priority: 'high',
        message: 'Cache hit rate is below 80%, consider increasing TTL or cache size'
      });
    }
    
    // 佇列建議
    Object.entries(queueMetrics).forEach(([queueKey, metrics]) => {
      if (metrics.waiting > 1000) {
        recommendations.push({
          type: 'queue',
          priority: 'high',
          queue: queueKey,
          message: 'High queue backlog, consider increasing workers'
        });
      }
      
      if (metrics.failed > metrics.completed * 0.1) {
        recommendations.push({
          type: 'queue',
          priority: 'medium',
          queue: queueKey,
          message: 'High failure rate, check error logs'
        });
      }
    });
    
    return recommendations;
  }
}
```

## 總結

本快取與佇列設計文件提供了完整的架構說明，包括：

1. **多層次快取策略**：記憶體、Redis、資料庫三層架構
2. **智能 TTL 管理**：根據資料特性設定不同過期時間
3. **任務佇列分類**：按優先級和性質分離處理
4. **批次處理優化**：提高系統吞吐量和資源使用效率
5. **監控與維護**：自動化監控和定期維護機制

這個設計確保系統在高負載情況下仍能保持穩定效能，同時提供靈活的擴展能力。
