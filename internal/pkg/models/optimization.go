package models

import (
	"time"

	"gorm.io/datatypes"
)

// OptimizationAnalysis 优化分析表
type OptimizationAnalysis struct {
	ID           string         `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	UserID       string         `gorm:"not null;type:uuid" json:"user_id"`
	ProductID    string         `gorm:"not null;type:uuid" json:"product_id"`
	AnalysisType string         `gorm:"default:comprehensive;size:50" json:"analysis_type"`
	FocusAreas   datatypes.JSON `gorm:"type:jsonb;default:'[\"title\", \"pricing\", \"description\", \"images\", \"keywords\"]'" json:"focus_areas"`
	Status       string         `gorm:"default:pending;size:20" json:"status"`
	OverallScore *int           `json:"overall_score,omitempty"`
	StartedAt    time.Time      `gorm:"default:now()" json:"started_at"`
	CompletedAt  *time.Time     `json:"completed_at,omitempty"`

	// 关联
	User        User                     `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Product     Product                  `gorm:"foreignKey:ProductID" json:"product,omitempty"`
	Suggestions []OptimizationSuggestion `gorm:"foreignKey:AnalysisID" json:"suggestions,omitempty"`
}

// TableName 表名
func (OptimizationAnalysis) TableName() string {
	return "optimization_analyses"
}

// OptimizationSuggestion 优化建议表
type OptimizationSuggestion struct {
	ID          string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	AnalysisID  string    `gorm:"not null;type:uuid" json:"analysis_id"`
	Category    string    `gorm:"not null;size:50" json:"category"`
	Priority    string    `gorm:"not null;size:10" json:"priority"`
	ImpactScore int       `gorm:"not null" json:"impact_score"`
	Title       string    `gorm:"not null;size:255" json:"title"`
	Description string    `gorm:"not null;type:text" json:"description"`
	ActionItems datatypes.JSON `gorm:"type:jsonb" json:"action_items,omitempty"`
	CreatedAt   time.Time `gorm:"autoCreateTime" json:"created_at"`

	// 关联
	Analysis OptimizationAnalysis `gorm:"foreignKey:AnalysisID" json:"analysis,omitempty"`
}

// TableName 表名
func (OptimizationSuggestion) TableName() string {
	return "optimization_suggestions"
}

// OptimizationTask 优化任务 (前端使用的聚合模型)
type OptimizationTask struct {
	ID               string                     `json:"id"`
	Title            string                     `json:"title"`
	Description      string                     `json:"description,omitempty"`
	ProductASIN      string                     `json:"product_asin"`
	OptimizationType string                     `json:"optimization_type"`
	Priority         string                     `json:"priority"`
	Status           string                     `json:"status"`
	AISuggestions    []string                   `json:"ai_suggestions,omitempty"`
	ImpactScore      *float64                   `json:"impact_score,omitempty"`
	EstimatedHours   *int                       `json:"estimated_hours,omitempty"`
	CreatedAt        string                     `json:"created_at"`
	UpdatedAt        string                     `json:"updated_at,omitempty"`
}

// OptimizationStats 优化统计数据
type OptimizationStats struct {
	TotalTasks         int     `json:"total_tasks"`
	PendingTasks       int     `json:"pending_tasks"`
	CompletedTasks     int     `json:"completed_tasks"`
	AverageImpactScore float64 `json:"average_impact_score"`
}