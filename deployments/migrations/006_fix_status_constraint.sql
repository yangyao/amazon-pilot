-- 006_fix_status_constraint.sql
-- 修复 competitor_analysis_results 表的 status 字段约束，添加异步任务状态

-- 查找并删除现有的 status check 约束（约束名可能不同）
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- 查找现有的 check 约束
    SELECT conname INTO constraint_name
    FROM pg_constraint c
    JOIN pg_class t ON c.conrelid = t.oid
    WHERE t.relname = 'competitor_analysis_results'
    AND c.contype = 'c'
    AND pg_get_constraintdef(c.oid) LIKE '%status%';

    -- 如果找到约束，删除它
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE competitor_analysis_results DROP CONSTRAINT ' || constraint_name;
    END IF;
END $$;

-- 重新创建 status check 约束，包含异步任务状态
ALTER TABLE competitor_analysis_results
ADD CONSTRAINT analysis_results_status_check
CHECK (status IN ('pending', 'queued', 'processing', 'completed', 'failed'));

-- 添加注释说明各状态含义
COMMENT ON CONSTRAINT analysis_results_status_check ON competitor_analysis_results IS
'状态约束: pending(待处理), queued(队列中), processing(处理中), completed(已完成), failed(失败)';

