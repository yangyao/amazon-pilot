package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"
)

// 简化的产品数据结构
type ProductData struct {
	ASIN        string  `json:"asin"`
	Title       string  `json:"title"`
	Brand       string  `json:"brand"`
	Price       float64 `json:"price"`
	Currency    string  `json:"currency"`
	Rating      float64 `json:"rating"`
	ReviewCount int     `json:"reviewCount"`
	BSR         int     `json:"salesRank"`
	BSRCategory string  `json:"salesRankCategory"`
}

func main() {
	fmt.Println("🚀 获取真实Amazon产品数据")
	fmt.Println("========================")

	apiToken := os.Getenv("APIFY_API_TOKEN")
	if apiToken == "" {
		fmt.Println("❌ APIFY_API_TOKEN 未设置")
		fmt.Println("请设置: export APIFY_API_TOKEN='apify_api_pi5ywKkUE97U9DBYreWcIRfOTVOkz04bI9UP'")
		return
	}

	// 真实的Amazon产品ASIN (无线蓝牙耳机)
	asins := []string{
		"B08N5WRWNW", // Echo Buds (2nd Gen)
		"B0BFZB9Z2P", // Apple AirPods Pro (2nd Gen)
		"B0CKX16C6Z", // Sony WF-1000XM4 (更新的ASIN)
	}

	fmt.Printf("📦 获取产品数据: %v\n", asins)

	// 使用一个简单可用的Apify Actor
	actorID := "epctex/amazon-scraper" // 这个Actor更稳定
	
	input := map[string]interface{}{
		"productUrls": []string{
			"https://www.amazon.com/dp/B08N5WRWNW",
			"https://www.amazon.com/dp/B0BFZB9Z2P", 
			"https://www.amazon.com/dp/B0CKX16C6Z",
		},
		"maxItems": 3,
		"country":  "US",
	}

	// 启动Actor
	runURL := fmt.Sprintf("https://api.apify.com/v2/acts/%s/runs", actorID)
	inputBytes, _ := json.Marshal(input)

	fmt.Printf("🚀 启动Actor: %s\n", actorID)

	req, _ := http.NewRequest("POST", runURL, bytes.NewBuffer(inputBytes))
	req.Header.Set("Authorization", "Bearer "+apiToken)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("❌ 请求失败: %v\n", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != 201 {
		body, _ := io.ReadAll(resp.Body)
		fmt.Printf("❌ Actor启动失败 %d: %s\n", resp.StatusCode, string(body))
		return
	}

	var runResult struct {
		Data struct {
			ID     string `json:"id"`
			Status string `json:"status"`
		} `json:"data"`
	}

	json.NewDecoder(resp.Body).Decode(&runResult)
	runID := runResult.Data.ID

	fmt.Printf("✅ Actor运行ID: %s\n", runID)
	fmt.Println("⏳ 等待数据获取完成...")

	// 等待运行完成
	for i := 0; i < 30; i++ { // 最多等待5分钟
		time.Sleep(10 * time.Second)
		
		statusURL := fmt.Sprintf("https://api.apify.com/v2/acts/runs/%s", runID)
		statusReq, _ := http.NewRequest("GET", statusURL, nil)
		statusReq.Header.Set("Authorization", "Bearer "+apiToken)

		statusResp, err := client.Do(statusReq)
		if err != nil {
			continue
		}

		var statusResult struct {
			Data struct {
				Status string `json:"status"`
			} `json:"data"`
		}

		json.NewDecoder(statusResp.Body).Decode(&statusResult)
		statusResp.Body.Close()

		fmt.Printf("📊 状态检查 %d/30: %s\n", i+1, statusResult.Data.Status)

		if statusResult.Data.Status == "SUCCEEDED" {
			fmt.Println("✅ 数据获取完成!")
			break
		} else if statusResult.Data.Status == "FAILED" {
			fmt.Println("❌ 数据获取失败")
			return
		}
	}

	// 获取结果数据
	resultsURL := fmt.Sprintf("https://api.apify.com/v2/acts/runs/%s/dataset/items", runID)
	resultsReq, _ := http.NewRequest("GET", resultsURL, nil)
	resultsReq.Header.Set("Authorization", "Bearer "+apiToken)

	resultsResp, err := client.Do(resultsReq)
	if err != nil {
		fmt.Printf("❌ 获取结果失败: %v\n", err)
		return
	}
	defer resultsResp.Body.Close()

	if resultsResp.StatusCode != 200 {
		body, _ := io.ReadAll(resultsResp.Body)
		fmt.Printf("❌ 结果获取失败 %d: %s\n", resultsResp.StatusCode, string(body))
		return
	}

	var products []map[string]interface{}
	if err := json.NewDecoder(resultsResp.Body).Decode(&products); err != nil {
		fmt.Printf("❌ 解析结果失败: %v\n", err)
		return
	}

	fmt.Printf("📊 获取到 %d 个产品数据:\n", len(products))

	for i, product := range products {
		fmt.Printf("\n产品 %d:\n", i+1)
		if asin, ok := product["asin"].(string); ok {
			fmt.Printf("   ASIN: %s\n", asin)
		}
		if title, ok := product["title"].(string); ok {
			fmt.Printf("   标题: %s\n", truncate(title, 50))
		}
		if price, ok := product["price"].(float64); ok {
			fmt.Printf("   价格: $%.2f\n", price)
		}
		if rating, ok := product["rating"].(float64); ok {
			fmt.Printf("   评分: %.1f⭐\n", rating)
		}
		if bsr, ok := product["salesRank"].(float64); ok && bsr > 0 {
			fmt.Printf("   BSR: #%.0f\n", bsr)
		}
	}

	fmt.Println("\n🎉 真实Amazon数据获取成功!")
	fmt.Println("\n💡 现在可以将这些数据集成到系统中:")
	fmt.Println("   1. 启动系统: ./scripts/start-full-system.sh")
	fmt.Println("   2. 访问前端: http://localhost:3000")
	fmt.Println("   3. 登录并查看实时数据更新")
}

func truncate(s string, max int) string {
	if len(s) <= max {
		return s
	}
	return s[:max] + "..."
}