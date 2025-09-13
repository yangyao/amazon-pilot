-- 005_hybrid_triggers.sql
-- 混合架构：轻量级触发器 + 应用层处理 + 数据保障

-- 1. 创建变更事件表 (数据保障)
CREATE TABLE IF NOT EXISTS change_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL, -- price_change, bsr_change, rating_change
    old_value DECIMAL(15,2),
    new_value DECIMAL(15,2),
    change_percentage DECIMAL(10,2),
    metadata JSONB,
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT change_events_type_check CHECK (event_type IN ('price_change', 'bsr_change', 'rating_change'))
);

-- 索引优化
CREATE INDEX idx_change_events_product_id ON change_events(product_id);
CREATE INDEX idx_change_events_processed ON change_events(processed, created_at);
CREATE INDEX idx_change_events_type ON change_events(event_type, created_at DESC);

-- 2. 轻量级价格变更触发器
CREATE OR REPLACE FUNCTION notify_price_change_hybrid()
RETURNS TRIGGER AS $$
DECLARE
    change_percentage DECIMAL(10,2);
    prev_price DECIMAL(15,2);
BEGIN
    -- 获取前一个价格 (简单查询)
    SELECT price INTO prev_price 
    FROM product_price_history 
    WHERE product_id = NEW.product_id 
      AND recorded_at < NEW.recorded_at 
    ORDER BY recorded_at DESC 
    LIMIT 1;

    IF prev_price IS NOT NULL AND prev_price > 0 THEN
        change_percentage := ABS((NEW.price - prev_price) / prev_price * 100);
        
        -- 只有超过阈值才处理
        IF change_percentage >= 10.0 THEN
            -- 1. 轻量级pg_notify (实时)
            PERFORM pg_notify('product_changes', json_build_object(
                'product_id', NEW.product_id,
                'change_type', 'price',
                'old_value', prev_price,
                'new_value', NEW.price,
                'change_percentage', change_percentage,
                'timestamp', NEW.recorded_at
            )::text);
            
            -- 2. 写入审计表 (数据保障)
            INSERT INTO change_events (
                product_id, event_type, old_value, new_value, 
                change_percentage, processed
            ) VALUES (
                NEW.product_id, 'price_change', prev_price, NEW.price,
                change_percentage, false
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. 轻量级BSR变更触发器
CREATE OR REPLACE FUNCTION notify_bsr_change_hybrid()
RETURNS TRIGGER AS $$
DECLARE
    change_percentage DECIMAL(10,2);
    prev_bsr INTEGER;
BEGIN
    -- 获取前一个BSR
    SELECT bsr INTO prev_bsr 
    FROM product_bsr_history 
    WHERE product_id = NEW.product_id 
      AND recorded_at < NEW.recorded_at 
    ORDER BY recorded_at DESC 
    LIMIT 1;

    IF prev_bsr IS NOT NULL AND prev_bsr > 0 THEN
        change_percentage := ABS((prev_bsr - NEW.bsr) / prev_bsr::DECIMAL * 100);
        
        -- BSR变动超过30%才处理
        IF change_percentage >= 30.0 THEN
            -- 1. 轻量级pg_notify
            PERFORM pg_notify('product_changes', json_build_object(
                'product_id', NEW.product_id,
                'change_type', 'bsr',
                'old_value', prev_bsr,
                'new_value', NEW.bsr,
                'change_percentage', change_percentage,
                'is_improvement', NEW.bsr < prev_bsr,
                'timestamp', NEW.recorded_at
            )::text);
            
            -- 2. 写入审计表
            INSERT INTO change_events (
                product_id, event_type, old_value, new_value, 
                change_percentage, processed
            ) VALUES (
                NEW.product_id, 'bsr_change', prev_bsr, NEW.bsr,
                change_percentage, false
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. 创建混合触发器
DROP TRIGGER IF EXISTS price_change_hybrid ON product_price_history;
CREATE TRIGGER price_change_hybrid
    AFTER INSERT ON product_price_history
    FOR EACH ROW EXECUTE FUNCTION notify_price_change_hybrid();

DROP TRIGGER IF EXISTS bsr_change_hybrid ON product_bsr_history;  
CREATE TRIGGER bsr_change_hybrid
    AFTER INSERT ON product_bsr_history
    FOR EACH ROW EXECUTE FUNCTION notify_bsr_change_hybrid();

-- 5. 补偿查询函数 (用于应用层补偿机制)
CREATE OR REPLACE FUNCTION get_unprocessed_changes(limit_count INTEGER DEFAULT 100)
RETURNS TABLE (
    id UUID,
    product_id UUID,
    product_asin VARCHAR(10),
    user_id UUID,
    user_email VARCHAR(255),
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
      AND ce.created_at < NOW() - INTERVAL '5 minutes'
      AND tp.is_active = true
    ORDER BY ce.created_at ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;