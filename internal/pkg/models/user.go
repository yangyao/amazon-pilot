package models

import (
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// User 用户模型
type User struct {
	ID            string     `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	Email         string     `gorm:"uniqueIndex;not null;size:255" json:"email"`
	PasswordHash  string     `gorm:"not null;size:255" json:"-"`
	CompanyName   *string    `gorm:"size:255" json:"company_name,omitempty"`
	PlanType      string     `gorm:"not null;default:basic;size:50" json:"plan_type"`
	IsActive      bool       `gorm:"default:true" json:"is_active"`
	EmailVerified bool       `gorm:"default:false" json:"email_verified"`
	CreatedAt     time.Time  `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt     time.Time  `gorm:"autoUpdateTime" json:"updated_at"`
	LastLoginAt   *time.Time `json:"last_login_at,omitempty"`

	// 关联 (暂时注释，避免循环引用)
	// Settings         UserSettings         `gorm:"foreignKey:UserID" json:"settings,omitempty"`
	// TrackedProducts  []TrackedProduct     `gorm:"foreignKey:UserID" json:"tracked_products,omitempty"`
}

// TableName 表名
func (User) TableName() string {
	return "users"
}

// BeforeCreate 创建前钩子
func (u *User) BeforeCreate(tx *gorm.DB) error {
	// 验证邮箱格式等可以在这里实现
	return nil
}

// SetPassword 设置密码
func (u *User) SetPassword(password string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	u.PasswordHash = string(hashedPassword)
	return nil
}

// CheckPassword 验证密码
func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.PasswordHash), []byte(password))
	return err == nil
}

// UserSettings 用户设置模型
type UserSettings struct {
	ID                       string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	UserID                   string    `gorm:"uniqueIndex;not null;type:uuid" json:"user_id"`
	NotificationEmail        bool      `gorm:"default:true" json:"notification_email"`
	NotificationPush         bool      `gorm:"default:false" json:"notification_push"`
	Timezone                 string    `gorm:"default:UTC;size:50" json:"timezone"`
	Currency                 string    `gorm:"default:USD;size:3" json:"currency"`
	DefaultTrackingFrequency string    `gorm:"default:daily;size:20" json:"default_tracking_frequency"`
	CreatedAt                time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt                time.Time `gorm:"autoUpdateTime" json:"updated_at"`

	// 关联 (暂时注释，避免循环引用)
	// User User `gorm:"foreignKey:UserID" json:"user,omitempty"`
}

// TableName 表名
func (UserSettings) TableName() string {
	return "user_settings"
}