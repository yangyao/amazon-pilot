-- 006_change_events_partitioned.sql
-- 创建分区的change_events表，支持高性能时间序列数据

-- 1. 创建主分区表 (按月分区)
CREATE TABLE change_events (
    id UUID DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    old_value DECIMAL(15,2),
    new_value DECIMAL(15,2),
    change_percentage DECIMAL(10,2),
    metadata JSONB,
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    
    -- 分区键必须包含在主键中
    PRIMARY KEY (id, created_at),
    
    CONSTRAINT change_events_type_check CHECK (event_type IN ('price_change', 'bsr_change', 'rating_change'))
) PARTITION BY RANGE (created_at);

-- 2. 创建当前月和未来几个月的分区
DO $$
DECLARE
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
    i INTEGER;
BEGIN
    -- 从当前月开始，创建6个月的分区 (当前月 + 未来5个月)
    FOR i IN 0..5 LOOP
        start_date := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '%s month' % i);
        end_date := start_date + INTERVAL '1 month';
        partition_name := 'change_events_' || TO_CHAR(start_date, 'YYYY_MM');
        
        EXECUTE format('
            CREATE TABLE %I PARTITION OF change_events
            FOR VALUES FROM (%L) TO (%L)',
            partition_name, start_date, end_date
        );
        
        -- 为每个分区创建索引
        EXECUTE format('CREATE INDEX %I ON %I (product_id, created_at DESC)', 
            'idx_' || partition_name || '_product_time', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (processed, created_at)', 
            'idx_' || partition_name || '_processed', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (event_type, created_at DESC)', 
            'idx_' || partition_name || '_type_time', partition_name);
            
        RAISE NOTICE 'Created partition: %', partition_name;
    END LOOP;
END $$;

-- 3. 添加外键约束 (需要在每个分区上)
-- 注意：PostgreSQL分区表的外键约束需要特殊处理
ALTER TABLE change_events 
ADD CONSTRAINT fk_change_events_product_id 
FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE;

-- 4. 创建自动分区管理函数
CREATE OR REPLACE FUNCTION create_monthly_partition(target_date DATE)
RETURNS TEXT AS $$
DECLARE
    partition_name TEXT;
    start_date DATE;
    end_date DATE;
BEGIN
    start_date := DATE_TRUNC('month', target_date);
    end_date := start_date + INTERVAL '1 month';
    partition_name := 'change_events_' || TO_CHAR(start_date, 'YYYY_MM');
    
    -- 检查分区是否已存在
    IF EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE tablename = partition_name
    ) THEN
        RETURN 'Partition ' || partition_name || ' already exists';
    END IF;
    
    -- 创建分区
    EXECUTE format('
        CREATE TABLE %I PARTITION OF change_events
        FOR VALUES FROM (%L) TO (%L)',
        partition_name, start_date, end_date
    );
    
    -- 创建索引
    EXECUTE format('CREATE INDEX %I ON %I (product_id, created_at DESC)', 
        'idx_' || partition_name || '_product_time', partition_name);
    EXECUTE format('CREATE INDEX %I ON %I (processed, created_at)', 
        'idx_' || partition_name || '_processed', partition_name);
    EXECUTE format('CREATE INDEX %I ON %I (event_type, created_at DESC)', 
        'idx_' || partition_name || '_type_time', partition_name);
    
    RETURN 'Created partition: ' || partition_name;
END;
$$ LANGUAGE plpgsql;

-- 5. 创建自动分区清理函数 (保留3个月数据)
CREATE OR REPLACE FUNCTION drop_old_partitions(retention_months INTEGER DEFAULT 3)
RETURNS TEXT[] AS $$
DECLARE
    partition_record RECORD;
    dropped_partitions TEXT[] := '{}';
    cutoff_date DATE;
BEGIN
    cutoff_date := DATE_TRUNC('month', CURRENT_DATE - INTERVAL '%s month' % retention_months);
    
    -- 查找需要删除的旧分区
    FOR partition_record IN
        SELECT tablename 
        FROM pg_tables 
        WHERE tablename LIKE 'change_events_%'
        AND tablename < 'change_events_' || TO_CHAR(cutoff_date, 'YYYY_MM')
    LOOP
        -- 删除分区
        EXECUTE format('DROP TABLE IF EXISTS %I', partition_record.tablename);
        dropped_partitions := array_append(dropped_partitions, partition_record.tablename);
        
        RAISE NOTICE 'Dropped old partition: %', partition_record.tablename;
    END LOOP;
    
    RETURN dropped_partitions;
END;
$$ LANGUAGE plpgsql;

-- 6. 创建分区维护的定时任务函数
CREATE OR REPLACE FUNCTION maintain_change_events_partitions()
RETURNS TEXT AS $$
DECLARE
    result TEXT := '';
    next_month_result TEXT;
    cleanup_result TEXT[];
BEGIN
    -- 创建下个月的分区 (提前准备)
    SELECT create_monthly_partition(CURRENT_DATE + INTERVAL '1 month') INTO next_month_result;
    result := result || next_month_result || '; ';
    
    -- 清理旧分区 (保留3个月)
    SELECT drop_old_partitions(3) INTO cleanup_result;
    IF array_length(cleanup_result, 1) > 0 THEN
        result := result || 'Dropped partitions: ' || array_to_string(cleanup_result, ', ');
    ELSE
        result := result || 'No old partitions to drop';
    END IF;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 7. 优化查询的函数 (用于应用层)
CREATE OR REPLACE FUNCTION get_recent_unprocessed_changes(
    limit_count INTEGER DEFAULT 100,
    minutes_ago INTEGER DEFAULT 5
)
RETURNS TABLE (
    id UUID,
    product_id UUID,
    product_asin VARCHAR(10),
    user_id UUID,
    user_email VARCHAR(255),
    user_plan VARCHAR(50),
    event_type VARCHAR(50),
    old_value DECIMAL(15,2),
    new_value DECIMAL(15,2),
    change_percentage DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ce.id,
        ce.product_id,
        p.asin,
        tp.user_id,
        u.email,
        u.plan_type,
        ce.event_type,
        ce.old_value,
        ce.new_value,
        ce.change_percentage,
        ce.created_at
    FROM change_events ce
    JOIN products p ON ce.product_id = p.id
    JOIN tracked_products tp ON p.id = tp.product_id
    JOIN users u ON tp.user_id = u.id
    WHERE ce.processed = false 
      AND ce.created_at < NOW() - (minutes_ago || ' minutes')::INTERVAL
      AND ce.created_at >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '2 month') -- 只查询近2个月
      AND tp.is_active = true
    ORDER BY ce.created_at ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 8. 创建分区统计视图 (用于监控)
CREATE OR REPLACE VIEW change_events_partition_stats AS
SELECT 
    schemaname,
    tablename as partition_name,
    CASE 
        WHEN tablename ~ 'change_events_[0-9]{4}_[0-9]{2}' 
        THEN SUBSTRING(tablename FROM 'change_events_([0-9]{4}_[0-9]{2})')
        ELSE 'unknown'
    END as period,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    (SELECT COUNT(*) FROM change_events WHERE created_at >= 
        TO_DATE(SUBSTRING(tablename FROM 'change_events_([0-9]{4}_[0-9]{2})'), 'YYYY_MM')
        AND created_at < TO_DATE(SUBSTRING(tablename FROM 'change_events_([0-9]{4}_[0-9]{2})'), 'YYYY_MM') + INTERVAL '1 month'
    ) as row_count,
    (SELECT COUNT(*) FROM change_events WHERE processed = false AND created_at >= 
        TO_DATE(SUBSTRING(tablename FROM 'change_events_([0-9]{4}_[0-9]{2})'), 'YYYY_MM')
        AND created_at < TO_DATE(SUBSTRING(tablename FROM 'change_events_([0-9]{4}_[0-9]{2})'), 'YYYY_MM') + INTERVAL '1 month'
    ) as unprocessed_count
FROM pg_tables 
WHERE tablename LIKE 'change_events_%'
  AND tablename ~ 'change_events_[0-9]{4}_[0-9]{2}'
ORDER BY tablename;

-- 9. 创建监控函数
CREATE OR REPLACE FUNCTION get_change_events_health()
RETURNS TABLE (
    total_unprocessed BIGINT,
    oldest_unprocessed TIMESTAMP WITH TIME ZONE,
    avg_processing_delay_minutes NUMERIC,
    events_last_hour BIGINT,
    events_last_24h BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM change_events WHERE processed = false) as total_unprocessed,
        (SELECT MIN(created_at) FROM change_events WHERE processed = false) as oldest_unprocessed,
        (SELECT ROUND(AVG(EXTRACT(EPOCH FROM (processed_at - created_at))/60), 2) 
         FROM change_events 
         WHERE processed = true 
           AND processed_at >= NOW() - INTERVAL '1 day') as avg_processing_delay_minutes,
        (SELECT COUNT(*) FROM change_events WHERE created_at >= NOW() - INTERVAL '1 hour') as events_last_hour,
        (SELECT COUNT(*) FROM change_events WHERE created_at >= NOW() - INTERVAL '1 day') as events_last_24h;
END;
$$ LANGUAGE plpgsql;

-- 10. 添加性能提示
COMMENT ON TABLE change_events IS '分区的变更事件表，按月分区以支持高性能时间序列数据处理';
COMMENT ON FUNCTION create_monthly_partition IS '自动创建新月份分区，建议在每月1号运行';
COMMENT ON FUNCTION drop_old_partitions IS '清理旧分区，默认保留3个月数据';
COMMENT ON FUNCTION maintain_change_events_partitions IS '完整的分区维护，建议每月运行一次';
COMMENT ON FUNCTION get_recent_unprocessed_changes IS '高性能查询未处理事件，用于补偿机制';
COMMENT ON VIEW change_events_partition_stats IS '分区统计信息，用于监控和容量规划';