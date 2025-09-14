# Competitor Service Database Design

## 競品分析相關表

### 1. competitor_analysis_groups (競品分析組)
```sql
CREATE TABLE competitor_analysis_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    main_product_id UUID REFERENCES products(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_competitor_groups_user_id ON competitor_analysis_groups(user_id);
CREATE INDEX idx_competitor_groups_main_product ON competitor_analysis_groups(main_product_id);
```

### 2. competitor_products (競品產品關聯)
```sql
CREATE TABLE competitor_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT competitor_products_unique UNIQUE (analysis_group_id, product_id)
);

CREATE INDEX idx_competitor_products_group ON competitor_products(analysis_group_id);
CREATE INDEX idx_competitor_products_product ON competitor_products(product_id);
```

### 3. competitor_analysis_reports (競品分析報告)
```sql
CREATE TABLE competitor_analysis_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_group_id UUID NOT NULL REFERENCES competitor_analysis_groups(id) ON DELETE CASCADE,
    report_type VARCHAR(50) NOT NULL,
    analysis_data JSONB NOT NULL,
    summary TEXT,
    recommendations TEXT,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data_source VARCHAR(50) DEFAULT 'system'
);

CREATE INDEX idx_reports_group_type ON competitor_analysis_reports(analysis_group_id, report_type);
CREATE INDEX idx_reports_generated ON competitor_analysis_reports(generated_at);
```

## 相關服務

- **API定義**: `api/openapi/competitor.api`
- **服務實現**: `internal/competitor/`
- **模型定義**: `internal/pkg/models/competitor.go`

---

**狀態**: 🔄 設計完成，待實現
**最後更新**: 2025-09-13