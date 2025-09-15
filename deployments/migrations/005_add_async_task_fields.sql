-- 005_add_async_task_fields.sql
-- 为 competitor_analysis_results 表添加异步任务支持字段

-- 添加 task_id 字段用于异步任务追踪
ALTER TABLE competitor_analysis_results
ADD COLUMN IF NOT EXISTS task_id VARCHAR(100);

-- 添加 queue_id 字段用于 AsyncQ 队列任务追踪
ALTER TABLE competitor_analysis_results
ADD COLUMN IF NOT EXISTS queue_id VARCHAR(100);

-- 为 task_id 添加索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_competitor_analysis_results_task_id
ON competitor_analysis_results(task_id);

-- 修改 analysis_data 字段为可选，因为异步任务初始创建时可能为空
ALTER TABLE competitor_analysis_results
ALTER COLUMN analysis_data DROP NOT NULL;

-- 添加注释说明字段用途
COMMENT ON COLUMN competitor_analysis_results.task_id IS '异步任务的唯一标识符，用于追踪任务状态';
COMMENT ON COLUMN competitor_analysis_results.queue_id IS 'AsyncQ队列中的任务ID，用于队列管理';
COMMENT ON COLUMN competitor_analysis_results.analysis_data IS '分析数据，异步任务初始可为空，完成后填入';

-- 记录迁移版本 (根据现有表结构调整)
INSERT INTO schema_migrations (version, executed_at)
VALUES ('005', NOW())
ON CONFLICT (version) DO NOTHING;