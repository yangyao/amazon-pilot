package models

import (
	"time"

	"gorm.io/datatypes"
)

// Notification 通知表
type Notification struct {
	ID         string         `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	UserID     string         `gorm:"not null;type:uuid" json:"user_id"`
	Type       string         `gorm:"not null;size:50" json:"type"`
	Title      string         `gorm:"not null;size:255" json:"title"`
	Message    string         `gorm:"not null;type:text" json:"message"`
	Severity   string         `gorm:"not null;size:20" json:"severity"`
	ProductID  *string        `gorm:"type:uuid" json:"product_id,omitempty"`
	AnalysisID *string        `gorm:"type:uuid" json:"analysis_id,omitempty"`
	Data       datatypes.JSON `gorm:"type:jsonb" json:"data,omitempty"`
	IsRead     bool           `gorm:"default:false" json:"is_read"`
	ReadAt     *time.Time     `json:"read_at,omitempty"`
	CreatedAt  time.Time      `gorm:"autoCreateTime" json:"created_at"`
	ExpiresAt  *time.Time     `json:"expires_at,omitempty"`

	// 关联
	User    User     `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Product *Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// TableName 表名
func (Notification) TableName() string {
	return "notifications"
}

// MarkAsRead 标记为已读
func (n *Notification) MarkAsRead() {
	now := time.Now()
	n.IsRead = true
	n.ReadAt = &now
}

// ChangeEvent 变更事件表 (分区表)
type ChangeEvent struct {
	ID               string         `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	ProductID        string         `gorm:"not null;type:uuid" json:"product_id"`
	EventType        string         `gorm:"not null;size:50" json:"event_type"`
	OldValue         *float64       `gorm:"type:decimal(15,2)" json:"old_value,omitempty"`
	NewValue         *float64       `gorm:"type:decimal(15,2)" json:"new_value,omitempty"`
	ChangePercentage *float64       `gorm:"type:decimal(10,2)" json:"change_percentage,omitempty"`
	Metadata         datatypes.JSON `gorm:"type:jsonb" json:"metadata,omitempty"`
	Processed        bool           `gorm:"default:false" json:"processed"`
	ProcessedAt      *time.Time     `json:"processed_at,omitempty"`
	CreatedAt        time.Time      `gorm:"not null;autoCreateTime" json:"created_at"`

	// 关联
	Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// TableName 表名 (分区表)
func (ChangeEvent) TableName() string {
	return "change_events"
}

// MarkAsProcessed 标记为已处理
func (ce *ChangeEvent) MarkAsProcessed() {
	now := time.Now()
	ce.Processed = true
	ce.ProcessedAt = &now
}