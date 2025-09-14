# Optimization Service Database Design

## 優化建議相關表

### 1. optimization_tasks (優化任務表)
```sql
CREATE TABLE optimization_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    task_type VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    priority INTEGER DEFAULT 1,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_optimization_tasks_user ON optimization_tasks(user_id);
CREATE INDEX idx_optimization_tasks_product ON optimization_tasks(product_id);
CREATE INDEX idx_optimization_tasks_status ON optimization_tasks(status);
CREATE INDEX idx_optimization_tasks_scheduled ON optimization_tasks(scheduled_at);
```

### 2. optimization_suggestions (優化建議表)
```sql
CREATE TABLE optimization_suggestions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES optimization_tasks(id) ON DELETE CASCADE,
    suggestion_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    reasoning TEXT,
    priority_score INTEGER DEFAULT 1,
    estimated_impact VARCHAR(50),
    implementation_difficulty VARCHAR(50),
    suggested_actions JSONB,
    ai_confidence DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_suggestions_task ON optimization_suggestions(task_id);
CREATE INDEX idx_suggestions_type ON optimization_suggestions(suggestion_type);
CREATE INDEX idx_suggestions_priority ON optimization_suggestions(priority_score);
```

### 3. ab_test_results (A/B測試結果表)
```sql
CREATE TABLE ab_test_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    suggestion_id UUID NOT NULL REFERENCES optimization_suggestions(id) ON DELETE CASCADE,
    test_name VARCHAR(255) NOT NULL,
    variant_a_data JSONB,
    variant_b_data JSONB,
    test_start_date TIMESTAMP WITH TIME ZONE,
    test_end_date TIMESTAMP WITH TIME ZONE,
    winner_variant VARCHAR(10),
    confidence_level DECIMAL(5,2),
    statistical_significance BOOLEAN DEFAULT FALSE,
    results_summary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_ab_tests_suggestion ON ab_test_results(suggestion_id);
CREATE INDEX idx_ab_tests_dates ON ab_test_results(test_start_date, test_end_date);
```

## 相關服務

- **API定義**: `api/openapi/optimization.api`
- **服務實現**: `internal/optimization/`
- **模型定義**: `internal/pkg/models/optimization.go`

---

**狀態**: 🔄 設計完成，待實現
**最後更新**: 2025-09-13