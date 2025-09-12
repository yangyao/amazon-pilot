package main

import (
	"fmt"
	"log"
	"os"

	"amazonpilot/internal/pkg/database"
	"amazonpilot/internal/pkg/models"

	"github.com/joho/godotenv"
)

func main() {
	// 加载环境变量
	if err := godotenv.Load(); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	// 获取数据库连接字符串
	dsn := os.Getenv("SUPABASE_URL")
	if dsn == "" {
		log.Fatal("SUPABASE_URL environment variable is required")
	}

	fmt.Printf("Connecting to database...\n")

	// 连接数据库
	db, err := database.NewConnectionWithDSN(dsn, &database.Config{
		MaxIdleConns:    10,
		MaxOpenConns:    100,
		ConnMaxLifetime: 3600,
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	fmt.Printf("Connected successfully!\n")

	// 自动迁移模型
	fmt.Printf("Running auto migrations...\n")

	err = db.AutoMigrate(
		&models.User{},
		&models.UserSettings{},
		&models.Product{},
		&models.TrackedProduct{},
		&models.PriceHistory{},
		&models.RankingHistory{},
	)
	if err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	fmt.Printf("✅ Database migration completed successfully!\n")

	// 验证表是否存在
	fmt.Printf("Verifying tables...\n")

	tables := []string{"users", "user_settings", "products", "tracked_products"}
	for _, table := range tables {
		if db.Migrator().HasTable(table) {
			fmt.Printf("✅ Table '%s' exists\n", table)
		} else {
			fmt.Printf("❌ Table '%s' missing\n", table)
		}
	}

	fmt.Printf("\n🎉 Migration process completed!\n")
}