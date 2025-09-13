-- 004_create_triggers.sql
-- PostgreSQL 触发器实现，用于实时异常检测和通知

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 自动更新时间戳触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 应用到所有需要的表
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_competitor_groups_updated_at BEFORE UPDATE ON competitor_analysis_groups
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. 价格变更通知触发器 (根据设计文档)
CREATE OR REPLACE FUNCTION notify_price_change()
RETURNS TRIGGER AS $$
DECLARE
    price_change_percentage decimal;
    tracked_product_record record;
    notification_payload jsonb;
BEGIN
    -- 只处理产品价格历史表的INSERT (新价格记录)
    IF TG_OP = 'INSERT' THEN
        -- 获取前一个价格记录进行比较
        SELECT 
            ph_prev.price as prev_price,
            p.id as product_id,
            p.asin,
            p.current_price,
            tp.user_id,
            u.email,
            u.plan_type
        INTO tracked_product_record
        FROM product_price_history ph_prev
        JOIN products p ON ph_prev.product_id = p.id
        JOIN tracked_products tp ON p.id = tp.product_id  
        JOIN users u ON tp.user_id = u.id
        WHERE ph_prev.product_id = NEW.product_id
          AND ph_prev.recorded_at < NEW.recorded_at
          AND tp.is_active = true
        ORDER BY ph_prev.recorded_at DESC
        LIMIT 1;

        -- 如果找到前一个价格记录，计算变化率
        IF tracked_product_record.prev_price IS NOT NULL AND tracked_product_record.prev_price > 0 THEN
            price_change_percentage := ABS((NEW.price - tracked_product_record.prev_price) / tracked_product_record.prev_price * 100);
            
            -- 检查是否超过10%的阈值
            IF price_change_percentage >= 10.0 THEN
                -- 构建通知负载
                notification_payload := jsonb_build_object(
                    'event_type', 'price_alert',
                    'user_id', tracked_product_record.user_id,
                    'user_email', tracked_product_record.email,
                    'user_plan', tracked_product_record.plan_type,
                    'product_id', NEW.product_id,
                    'product_asin', tracked_product_record.asin,
                    'notification_data', jsonb_build_object(
                        'type', 'price_alert',
                        'title', 'Price Alert - ' || tracked_product_record.asin,
                        'message', 'Product price changed by ' || ROUND(price_change_percentage, 1)::text || '% (from $' || tracked_product_record.prev_price::text || ' to $' || NEW.price::text || ')',
                        'severity', CASE 
                            WHEN price_change_percentage > 20 THEN 'critical'
                            WHEN price_change_percentage > 10 THEN 'warning'
                            ELSE 'info'
                        END
                    ),
                    'change_data', jsonb_build_object(
                        'old_price', tracked_product_record.prev_price,
                        'new_price', NEW.price,
                        'change_percentage', ROUND(price_change_percentage, 2),
                        'timestamp', NEW.recorded_at
                    )
                );

                -- 发送到Redis队列 (使用pg_notify)
                PERFORM pg_notify('price_alerts', notification_payload::text);
                
                -- 记录日志
                RAISE INFO 'Price alert triggered: Product % changed by %% (% -> %)', 
                    tracked_product_record.asin, 
                    ROUND(price_change_percentage, 1), 
                    tracked_product_record.prev_price, 
                    NEW.price;
            END IF;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 3. BSR排名变更通知触发器
CREATE OR REPLACE FUNCTION notify_bsr_change()
RETURNS TRIGGER AS $$
DECLARE
    bsr_change_percentage decimal;
    tracked_product_record record;
    notification_payload jsonb;
BEGIN
    -- 只处理BSR历史表的INSERT (新BSR记录)
    IF TG_OP = 'INSERT' THEN
        -- 获取前一个BSR记录进行比较
        SELECT 
            bh_prev.bsr as prev_bsr,
            p.id as product_id,
            p.asin,
            p.current_bsr,
            tp.user_id,
            u.email,
            u.plan_type
        INTO tracked_product_record
        FROM product_bsr_history bh_prev
        JOIN products p ON bh_prev.product_id = p.id
        JOIN tracked_products tp ON p.id = tp.product_id
        JOIN users u ON tp.user_id = u.id
        WHERE bh_prev.product_id = NEW.product_id
          AND bh_prev.recorded_at < NEW.recorded_at
          AND tp.is_active = true
        ORDER BY bh_prev.recorded_at DESC
        LIMIT 1;

        -- 如果找到前一个BSR记录，计算变化率
        IF tracked_product_record.prev_bsr IS NOT NULL AND tracked_product_record.prev_bsr > 0 THEN
            -- BSR越小越好，所以改善是正向的
            bsr_change_percentage := ABS((tracked_product_record.prev_bsr - NEW.bsr) / tracked_product_record.prev_bsr::decimal * 100);
            
            -- 检查是否超过30%的阈值
            IF bsr_change_percentage >= 30.0 THEN
                -- 构建通知负载
                notification_payload := jsonb_build_object(
                    'event_type', 'bsr_alert',
                    'user_id', tracked_product_record.user_id,
                    'user_email', tracked_product_record.email,
                    'user_plan', tracked_product_record.plan_type,
                    'product_id', NEW.product_id,
                    'product_asin', tracked_product_record.asin,
                    'notification_data', jsonb_build_object(
                        'type', 'bsr_change',
                        'title', 'BSR Ranking Alert - ' || tracked_product_record.asin,
                        'message', CASE 
                            WHEN NEW.bsr < tracked_product_record.prev_bsr 
                            THEN 'BSR improved by ' || ROUND(bsr_change_percentage, 1)::text || '% (from #' || tracked_product_record.prev_bsr::text || ' to #' || NEW.bsr::text || ')'
                            ELSE 'BSR worsened by ' || ROUND(bsr_change_percentage, 1)::text || '% (from #' || tracked_product_record.prev_bsr::text || ' to #' || NEW.bsr::text || ')'
                        END,
                        'severity', CASE 
                            WHEN bsr_change_percentage > 50 THEN 'critical'
                            WHEN bsr_change_percentage > 30 THEN 
                                CASE WHEN NEW.bsr > tracked_product_record.prev_bsr THEN 'warning' ELSE 'info' END
                            ELSE 'info'
                        END
                    ),
                    'change_data', jsonb_build_object(
                        'old_bsr', tracked_product_record.prev_bsr,
                        'new_bsr', NEW.bsr,
                        'change_percentage', ROUND(bsr_change_percentage, 2),
                        'is_improvement', NEW.bsr < tracked_product_record.prev_bsr,
                        'timestamp', NEW.recorded_at
                    )
                );

                -- 发送到Redis队列
                PERFORM pg_notify('bsr_alerts', notification_payload::text);
                
                -- 记录日志
                RAISE INFO 'BSR alert triggered: Product % changed by %% (% -> %)', 
                    tracked_product_record.asin, 
                    ROUND(bsr_change_percentage, 1), 
                    tracked_product_record.prev_bsr, 
                    NEW.bsr;
            END IF;
        END IF;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
DROP TRIGGER IF EXISTS price_change_notification ON product_price_history;
CREATE TRIGGER price_change_notification
    AFTER INSERT ON product_price_history
    FOR EACH ROW EXECUTE FUNCTION notify_price_change();

DROP TRIGGER IF EXISTS bsr_change_notification ON product_bsr_history;
CREATE TRIGGER bsr_change_notification
    AFTER INSERT ON product_bsr_history
    FOR EACH ROW EXECUTE FUNCTION notify_bsr_change();

-- 创建通用的异常事件表 (用于审计和调试)
CREATE TABLE IF NOT EXISTS anomaly_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(50) NOT NULL,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    severity VARCHAR(20) NOT NULL,
    change_percentage DECIMAL(10,2),
    old_value DECIMAL(15,2),
    new_value DECIMAL(15,2),
    event_data JSONB,
    processed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT anomaly_events_severity_check CHECK (severity IN ('info', 'warning', 'critical'))
);

-- 索引
CREATE INDEX idx_anomaly_events_product_id ON anomaly_events(product_id);
CREATE INDEX idx_anomaly_events_user_id ON anomaly_events(user_id);
CREATE INDEX idx_anomaly_events_type_severity ON anomaly_events(event_type, severity);
CREATE INDEX idx_anomaly_events_processed ON anomaly_events(processed, created_at);

-- 4. 为触发器添加事件记录功能
CREATE OR REPLACE FUNCTION log_anomaly_event(
    p_event_type VARCHAR(50),
    p_product_id UUID,
    p_user_id UUID,
    p_severity VARCHAR(20),
    p_change_percentage DECIMAL(10,2),
    p_old_value DECIMAL(15,2),
    p_new_value DECIMAL(15,2),
    p_event_data JSONB
)
RETURNS UUID AS $$
DECLARE
    event_id UUID;
BEGIN
    INSERT INTO anomaly_events (
        event_type, product_id, user_id, severity,
        change_percentage, old_value, new_value, event_data
    ) VALUES (
        p_event_type, p_product_id, p_user_id, p_severity,
        p_change_percentage, p_old_value, p_new_value, p_event_data
    ) RETURNING id INTO event_id;
    
    RETURN event_id;
END;
$$ LANGUAGE plpgsql;