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
		Logger: jsonLogger,
	})
	if err != nil {
		return nil, err
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, err
	}

	sqlDB.SetMaxIdleConns(config.MaxIdleConns)
	sqlDB.SetMaxOpenConns(config.MaxOpenConns)
	sqlDB.SetConnMaxLifetime(time.Duration(config.ConnMaxLifetime) * time.Second)

	return db, nil
}