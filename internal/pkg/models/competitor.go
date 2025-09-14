package models

import (
	"time"

	"gorm.io/datatypes"
)

// CompetitorAnalysisGroup 竞品分析组
type CompetitorAnalysisGroup struct {
	ID              string         `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	UserID          string         `gorm:"not null;type:uuid" json:"user_id"`
	Name            string         `gorm:"not null;size:255" json:"name"`
	Description     *string        `gorm:"type:text" json:"description,omitempty"`
	MainProductID   string         `gorm:"not null;type:uuid" json:"main_product_id"`
	AnalysisMetrics datatypes.JSON `gorm:"type:jsonb;default:'[\"price\", \"bsr\", \"rating\", \"features\"]'" json:"analysis_metrics"`
	IsActive        bool           `gorm:"default:true" json:"is_active"`
	CreatedAt       time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt       time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	LastAnalysisAt  *time.Time     `json:"last_analysis_at,omitempty"`
	NextAnalysisAt  *time.Time     `json:"next_analysis_at,omitempty"`

	// 关联
	User            User                        `gorm:"foreignKey:UserID" json:"user,omitempty"`
	MainProduct     Product                     `gorm:"foreignKey:MainProductID" json:"main_product,omitempty"`
	Competitors     []CompetitorProduct         `gorm:"foreignKey:AnalysisGroupID" json:"competitors,omitempty"`
	AnalysisResults []CompetitorAnalysisResult  `gorm:"foreignKey:AnalysisGroupID" json:"analysis_results,omitempty"`
}

// TableName 表名
func (CompetitorAnalysisGroup) TableName() string {
	return "competitor_analysis_groups"
}

// CompetitorProduct 竞品产品关联
type CompetitorProduct struct {
	ID              string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	AnalysisGroupID string    `gorm:"not null;type:uuid" json:"analysis_group_id"`
	ProductID       string    `gorm:"not null;type:uuid" json:"product_id"`
	AddedAt         time.Time `gorm:"default:now()" json:"added_at"`

	// 关联
	AnalysisGroup CompetitorAnalysisGroup `gorm:"foreignKey:AnalysisGroupID" json:"analysis_group,omitempty"`
	Product       Product                 `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// TableName 表名
func (CompetitorProduct) TableName() string {
	return "competitor_products"
}

// CompetitorAnalysisResult 分析结果
type CompetitorAnalysisResult struct {
	ID              string         `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	AnalysisGroupID string         `gorm:"not null;type:uuid" json:"analysis_group_id"`
	AnalysisData    datatypes.JSON `gorm:"type:jsonb;not null" json:"analysis_data"`
	Insights        datatypes.JSON `gorm:"type:jsonb" json:"insights,omitempty"`
	Recommendations datatypes.JSON `gorm:"type:jsonb" json:"recommendations,omitempty"`
	Status          string         `gorm:"default:pending;size:20" json:"status"`
	StartedAt       time.Time      `gorm:"default:now()" json:"started_at"`
	CompletedAt     *time.Time     `json:"completed_at,omitempty"`
	ErrorMessage    *string        `gorm:"type:text" json:"error_message,omitempty"`

	// 关联
	AnalysisGroup CompetitorAnalysisGroup `gorm:"foreignKey:AnalysisGroupID" json:"analysis_group,omitempty"`
}

// TableName 表名
func (CompetitorAnalysisResult) TableName() string {
	return "competitor_analysis_results"
}