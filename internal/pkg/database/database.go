package database

import (
	"fmt"
	"os"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// Config 数据库配置
type Config struct {
	Host            string `json:"host"`
	Port            int    `json:"port"`
	User            string `json:"user"`
	Password        string `json:"password"`
	Database        string `json:"database"`
	SSLMode         string `json:"sslMode,default=disable"`
	MaxIdleConns    int    `json:"maxIdleConns,default=10"`
	MaxOpenConns    int    `json:"maxOpenConns,default=100"`
	ConnMaxLifetime int    `json:"connMaxLifetime,default=3600"` // seconds
	PrepareStmt     bool   `json:"prepareStmt,default=false"`     // 默认禁用，避免缓存冲突
}

// NewConnection 创建数据库连接 (优先使用DSN)
func NewConnection(config *Config) (*gorm.DB, error) {
	// 优先从环境变量读取DSN
	dsn := os.Getenv("SUPABASE_URL")
	
	if dsn == "" {
		// 回退到配置参数构建DSN
		dsn = fmt.Sprintf("postgresql://%s:%s@%s:%d/%s?sslmode=%s",
			config.User, config.Password, config.Host, config.Port, config.Database, config.SSLMode)
	}

	return NewConnectionWithDSN(dsn, config)
}

// NewConnectionWithDSN 使用DSN创建数据库连接
func NewConnectionWithDSN(dsn string, config *Config) (*gorm.DB, error) {
	// 使用自定义JSON格式日志器
	jsonLogger := NewJSONLogger()

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger:                 jsonLogger,
		PrepareStmt:           config.PrepareStmt, // 可配置的prepared statement缓存
		DisableForeignKeyConstraintWhenMigrating: true,
	})
	if err != nil {
		return nil, err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}

	// 设置连接池参数，避免连接复用导致的prepared statement冲突
	sqlDB.SetMaxIdleConns(config.MaxIdleConns)
	sqlDB.SetMaxOpenConns(config.MaxOpenConns)
	sqlDB.SetConnMaxLifetime(time.Duration(config.ConnMaxLifetime) * time.Second)
	sqlDB.SetConnMaxIdleTime(10 * time.Minute) // 设置连接空闲超时

	return db, nil
}

// NewConnectionSafe 创建安全的数据库连接（禁用prepared statement缓存）
// 用于解决高并发环境下的prepared statement冲突问题
func NewConnectionSafe(dsn string) (*gorm.DB, error) {
	safeConfig := &Config{
		MaxIdleConns:    5,     // 减少空闲连接数
		MaxOpenConns:    25,    // 减少最大连接数
		ConnMaxLifetime: 1800,  // 30分钟生命周期
		PrepareStmt:     false, // 禁用prepared statement缓存
	}

	return NewConnectionWithDSN(dsn, safeConfig)
}