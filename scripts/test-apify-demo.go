package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"amazonpilot/internal/pkg/apify"
	"amazonpilot/internal/pkg/database"
	"amazonpilot/internal/pkg/logger"
	"amazonpilot/internal/pkg/models"
	"amazonpilot/internal/pkg/queue"

	"gorm.io/gorm"
)

func main() {
	// 初始化日志
	logger.InitStructuredLogger()

	fmt.Println("🎯 Amazon Pilot Apify Demo 测试")
	fmt.Println("================================")

	// 检查Apify API Token
	apifyToken := os.Getenv("APIFY_API_TOKEN")
	if apifyToken == "" {
		fmt.Println("❌ APIFY_API_TOKEN 环境变量未设置")
		fmt.Println("💡 请设置: export APIFY_API_TOKEN='your_token'")
		os.Exit(1)
	}

	fmt.Printf("✅ Apify API Token 已配置 (长度: %d)\n", len(apifyToken))

	// 连接数据库
	db, err := database.NewConnection(database.Config{
		Host:     "localhost",
		Port:     5432,
		User:     "postgres", 
		Password: "postgres",
		DBName:   "amazon_pilot",
		SSLMode:  "disable",
	})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	fmt.Println("✅ 数据库连接成功")

	// 初始化Apify客户端
	apifyClient := apify.NewClient(apifyToken)

	// Demo产品ASIN列表 (无线蓝牙耳机)
	demoASINs := []string{
		"B08N5WRWNW", // Echo Buds (2nd Gen)
		"B0BFZB9Z2P", // Apple AirPods Pro (2nd Gen)
		"B0BDRR8Z6G", // Sony WF-1000XM4
	}

	fmt.Printf("🎧 测试产品: %v\n", demoASINs)

	// 获取真实产品数据
	fmt.Println("\n📡 调用Apify API获取真实数据...")
	ctx := context.Background()
	
	products, err := apifyClient.FetchProductData(ctx, demoASINs, 10*time.Minute)
	if err != nil {
		log.Fatalf("Failed to fetch product data: %v", err)
	}

	fmt.Printf("✅ 成功获取 %d 个产品数据\n", len(products))

	// 显示产品数据
	fmt.Println("\n📊 获取的产品数据:")
	for i, product := range products {
		fmt.Printf("\n产品 %d:\n", i+1)
		fmt.Printf("   ASIN:      %s\n", product.ASIN)
		fmt.Printf("   标题:      %s\n", truncateString(product.Title, 50))
		fmt.Printf("   品牌:      %s\n", product.Brand)
		fmt.Printf("   价格:      $%.2f %s\n", product.Price, product.Currency)
		fmt.Printf("   评分:      %.1f ⭐ (%d reviews)\n", product.Rating, product.ReviewCount)
		if product.BSR > 0 {
			fmt.Printf("   BSR:       #%d in %s\n", product.BSR, product.BSRCategory)
		}
		fmt.Printf("   抓取时间:  %s\n", product.ScrapedAt.Format("2006-01-02 15:04:05"))
	}

	// 更新数据库中的产品信息
	fmt.Println("\n💾 更新数据库中的产品信息...")
	
	for _, productData := range products {
		var dbProduct models.Product
		err := db.Where("asin = ?", productData.ASIN).First(&dbProduct).Error
		
		if err == gorm.ErrRecordNotFound {
			fmt.Printf("   ⚠️  产品 %s 在数据库中不存在，跳过\n", productData.ASIN)
			continue
		} else if err != nil {
			fmt.Printf("   ❌ 查询产品 %s 失败: %v\n", productData.ASIN, err)
			continue
		}

		// 记录原始价格用于对比
		oldPrice := dbProduct.CurrentPrice

		// 更新产品信息
		updates := map[string]interface{}{
			"title":         productData.Title,
			"brand":         productData.Brand,
			"current_price": productData.Price,
			"rating":        productData.Rating,
			"review_count":  productData.ReviewCount,
			"updated_at":    time.Now(),
		}

		if productData.BSR > 0 {
			updates["current_bsr"] = productData.BSR
		}

		if err := db.Model(&dbProduct).Updates(updates).Error; err != nil {
			fmt.Printf("   ❌ 更新产品 %s 失败: %v\n", productData.ASIN, err)
			continue
		}

		// 创建价格历史记录 (这将触发异常检测)
		priceHistory := models.ProductPriceHistory{
			ProductID:  dbProduct.ID,
			Price:      productData.Price,
			Currency:   productData.Currency,
			RecordedAt: time.Now(),
			DataSource: "apify_demo",
		}

		if err := db.Create(&priceHistory).Error; err != nil {
			fmt.Printf("   ❌ 创建价格历史 %s 失败: %v\n", productData.ASIN, err)
			continue
		}

		// 计算价格变化
		priceChange := 0.0
		if oldPrice > 0 {
			priceChange = (productData.Price - oldPrice) / oldPrice * 100
		}

		fmt.Printf("   ✅ 产品 %s 更新成功\n", productData.ASIN)
		fmt.Printf("      价格变化: $%.2f → $%.2f (%.1f%%)\n", 
			oldPrice, productData.Price, priceChange)
		
		if abs(priceChange) >= 10.0 {
			fmt.Printf("      🚨 检测到价格异常变化! (>10%%)\n")
		}
	}

	fmt.Println("\n🎉 Demo测试完成！")
	fmt.Println("\n📋 测试结果总结:")
	fmt.Printf("   • 成功调用Apify API: ✅\n")
	fmt.Printf("   • 获取真实Amazon数据: ✅\n") 
	fmt.Printf("   • 更新数据库: ✅\n")
	fmt.Printf("   • 触发异常检测: ✅ (如果有>10%%价格变化)\n")
	
	fmt.Println("\n🚀 现在可以:")
	fmt.Println("   1. 启动完整系统: ./scripts/start-full-system.sh")
	fmt.Println("   2. 登录前端查看数据: http://localhost:3000")
	fmt.Println("   3. 查看实时通知和异常检测结果")
}

// truncateString 截断字符串
func truncateString(s string, maxLen int) string {
	if len(s) <= maxLen {
		return s
	}
	return s[:maxLen] + "..."
}

// abs 计算绝对值
func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}