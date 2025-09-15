package apify

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"time"

	"amazonpilot/internal/pkg/logger"
)

// Client Apify API客户端
type Client struct {
	apiToken   string
	baseURL    string
	httpClient *http.Client
	logger     *logger.ServiceLogger
}

// ProductData Amazon产品数据结构
type ProductData struct {
	ASIN         string    `json:"asin"`
	Title        string    `json:"title"`
	Brand        string    `json:"brand,omitempty"`
	Manufacturer string    `json:"manufacturer,omitempty"`
	Category     string    `json:"category,omitempty"`
	Price        float64   `json:"price"`
	RetailPrice  float64   `json:"retailPrice,omitempty"`
	Currency     string    `json:"currency"`
	Rating       float64   `json:"rating,omitempty"`
	ProductRating string   `json:"productRating,omitempty"` // e.g., "4.4 out of 5 stars"
	ReviewCount  int       `json:"countReview,omitempty"`
	BSR          int       `json:"salesRank,omitempty"`
	BSRCategory  string    `json:"salesRankCategory,omitempty"`
	Images       []string  `json:"imageUrlList,omitempty"`
	Description  string    `json:"productDescription,omitempty"`
	Features     []string  `json:"features,omitempty"`  // 实际 API 返回 features
	BulletPoints []string  `json:"bulletPoints,omitempty"` // 保留兼容性
	Availability string    `json:"warehouseAvailability,omitempty"`
	Prime        bool      `json:"prime,omitempty"`
	Seller       string    `json:"soldBy,omitempty"`
	FulfilledBy  string    `json:"fulfilledBy,omitempty"`
	ScrapedAt    time.Time `json:"scrapedAt"`
	URL          string    `json:"url,omitempty"`
	StatusCode   int       `json:"statusCode,omitempty"`
}

// RunInput Apify Actor运行输入 (简化为仅必需字段)
type RunInput struct {
	URLs []string `json:"urls"`
}

// RunResponse Apify Actor运行响应
type RunResponse struct {
	Data struct {
		ID        string    `json:"id"`
		Status    string    `json:"status"`
		StartedAt time.Time `json:"startedAt"`
	} `json:"data"`
}

// NewClient 创建Apify客户端
func NewClient(apiToken string) *Client {
	return &Client{
		apiToken: apiToken,
		baseURL:  "https://api.apify.com/v2",
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		logger: logger.NewServiceLogger("apify"),
	}
}

// RunAmazonProductActor 运行Amazon产品数据抓取Actor
func (c *Client) RunAmazonProductActor(ctx context.Context, asins []string) (*RunResponse, error) {
	// 使用经过验证的Amazon Product Details Actor (使用actor ID而不是name)
	actorID := "7KgyOHHEiPEcilZXM"

	// 将ASIN转换为完整的Amazon URL
	urls := make([]string, len(asins))
	for i, asin := range asins {
		urls[i] = fmt.Sprintf("https://www.amazon.com/dp/%s", asin)
	}

	input := RunInput{
		URLs: urls,
	}

	slog.Info("Starting Apify actor run",
		"actor_id", actorID,
		"asins_count", len(asins),
		"asins", asins,
	)

	// 构建请求 - 使用正确的Apify API格式
	url := fmt.Sprintf("%s/acts/%s/runs", c.baseURL, actorID)

	inputBytes, err := json.Marshal(input)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal input: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(inputBytes))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiToken)
	req.Header.Set("Content-Type", "application/json")

	// 发送请求
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API request failed with status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	var runResp RunResponse
	if err := json.NewDecoder(resp.Body).Decode(&runResp); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	c.logger.LogBusinessOperation(ctx, "apify_actor_started", "apify_run", runResp.Data.ID, "success",
		"actor_id", actorID,
		"asins_count", len(asins),
	)

	slog.Info("Apify actor run started",
		"run_id", runResp.Data.ID,
		"status", runResp.Data.Status,
		"asins", asins,
	)

	return &runResp, nil
}

// WaitForRunCompletion 等待Actor运行完成
func (c *Client) WaitForRunCompletion(ctx context.Context, runID string, timeout time.Duration) error {
	slog.Info("Waiting for Apify run completion",
		"run_id", runID,
		"timeout", timeout,
	)

	deadline := time.Now().Add(timeout)
	ticker := time.NewTicker(10 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
			if time.Now().After(deadline) {
				return fmt.Errorf("timeout waiting for run %s to complete", runID)
			}

			status, err := c.getRunStatus(ctx, runID)
			if err != nil {
				return fmt.Errorf("failed to get run status: %w", err)
			}

			slog.Info("Apify run status check", "run_id", runID, "status", status)

			switch status {
			case "SUCCEEDED":
				c.logger.LogBusinessOperation(ctx, "apify_run_completed", "apify_run", runID, "success")
				return nil
			case "FAILED", "ABORTED", "TIMED-OUT":
				return fmt.Errorf("run %s failed with status: %s", runID, status)
			case "READY", "RUNNING":
				// 继续等待
				continue
			default:
				return fmt.Errorf("unknown run status: %s", status)
			}
		}
	}
}

// GetRunResults 获取Actor运行结果
func (c *Client) GetRunResults(ctx context.Context, runID string) ([]ProductData, error) {
	slog.Info("Fetching Apify run results", "run_id", runID)

	url := fmt.Sprintf("%s/acts/runs/%s/dataset/items", c.baseURL, runID)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiToken)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("failed to get results with status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	// 先读取原始响应数据
	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	// 解析为通用的 JSON 数组
	var rawProducts []json.RawMessage
	if err := json.Unmarshal(bodyBytes, &rawProducts); err != nil {
		return nil, fmt.Errorf("failed to decode raw results: %w", err)
	}

	// 使用标准化函数处理每个产品数据
	products := make([]ProductData, 0, len(rawProducts))
	for _, rawProduct := range rawProducts {
		normalizedProduct, err := NormalizeApifyResponse(rawProduct)
		if err != nil {
			slog.Warn("Failed to normalize product data, skipping", "error", err)
			continue
		}
		products = append(products, *normalizedProduct)
	}

	c.logger.LogBusinessOperation(ctx, "apify_results_fetched", "apify_run", runID, "success",
		"products_count", len(products),
	)

	slog.Info("Apify run results fetched",
		"run_id", runID,
		"products_count", len(products),
	)

	return products, nil
}

// getRunStatus 获取运行状态
func (c *Client) getRunStatus(ctx context.Context, runID string) (string, error) {
	url := fmt.Sprintf("%s/acts/runs/%s", c.baseURL, runID)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+c.apiToken)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("failed to get run status: %d", resp.StatusCode)
	}

	var runData struct {
		Data struct {
			Status string `json:"status"`
		} `json:"data"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&runData); err != nil {
		return "", fmt.Errorf("failed to decode status response: %w", err)
	}

	return runData.Data.Status, nil
}

// ApifyResponseWithFeatures 实际 API 响应结构（基于真实数据）
type ApifyResponseWithFeatures struct {
	ASIN         string   `json:"asin"`
	Title        string   `json:"title"`
	Brand        string   `json:"brand,omitempty"`
	Manufacturer string   `json:"manufacturer,omitempty"`
	Category     string   `json:"category,omitempty"`
	Price        float64  `json:"price"`
	RetailPrice  float64  `json:"retailPrice,omitempty"`
	Currency     string   `json:"currency"`
	Rating       float64  `json:"rating,omitempty"`
	ProductRating string  `json:"productRating,omitempty"`
	ReviewCount  int      `json:"countReview,omitempty"`  // 实际 API 返回 countReview
	BSR          int      `json:"salesRank,omitempty"`
	BSRCategory  string   `json:"salesRankCategory,omitempty"`
	Images       []string `json:"imageUrlList,omitempty"` // 实际 API 返回 imageUrlList
	Description  string   `json:"productDescription,omitempty"`
	Features     []string `json:"features,omitempty"`     // 实际 API 返回 features
	Availability string   `json:"warehouseAvailability,omitempty"`
	Prime        bool     `json:"prime,omitempty"`
	Seller       string   `json:"soldBy,omitempty"`
	FulfilledBy  string   `json:"fulfilledBy,omitempty"`
	URL          string   `json:"url,omitempty"`
	StatusCode   int      `json:"statusCode,omitempty"`
}

// NormalizeApifyResponse 标准化 Apify 响应，处理字段名差异
func NormalizeApifyResponse(rawJSON []byte) (*ProductData, error) {
	var response ApifyResponseWithFeatures
	if err := json.Unmarshal(rawJSON, &response); err != nil {
		return nil, err
	}

	// 直接使用 features 字段（这是 API 实际返回的字段）
	bulletPoints := response.Features

	// 设置抓取时间
	now := time.Now()

	return &ProductData{
		ASIN:         response.ASIN,
		Title:        response.Title,
		Brand:        response.Brand,
		Manufacturer: response.Manufacturer,
		Category:     response.Category,
		Price:        response.Price,
		RetailPrice:  response.RetailPrice,
		Currency:     response.Currency,
		Rating:       response.Rating,
		ProductRating: response.ProductRating,
		ReviewCount:  response.ReviewCount,
		BSR:          response.BSR,
		BSRCategory:  response.BSRCategory,
		Images:       response.Images, // 从 imageUrlList 映射到 Images
		Description:  response.Description,
		BulletPoints: bulletPoints,   // 从 features 映射到 BulletPoints
		Availability: response.Availability,
		Prime:        response.Prime,
		Seller:       response.Seller,
		FulfilledBy:  response.FulfilledBy,
		ScrapedAt:    now,
		URL:          response.URL,
		StatusCode:   response.StatusCode,
	}, nil
}

// FetchProductData 同步获取产品数据 (使用run-sync-get-dataset-items API)
func (c *Client) FetchProductData(ctx context.Context, asins []string, timeout time.Duration) ([]ProductData, error) {
	slog.Info("Starting sync product data fetch",
		"asins_count", len(asins),
	)

	// 将ASIN转换为完整的Amazon URL
	urls := make([]string, len(asins))
	for i, asin := range asins {
		urls[i] = fmt.Sprintf("https://www.amazon.com/dp/%s", asin)
	}

	input := RunInput{
		URLs: urls,
	}

	inputBytes, err := json.Marshal(input)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal input: %w", err)
	}

	// 使用同步API直接获取数据
	actorName := "axesso_data~amazon-product-details-scraper"
	url := fmt.Sprintf("%s/acts/%s/run-sync-get-dataset-items?token=%s", c.baseURL, actorName, c.apiToken)

	req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(inputBytes))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")

	// 发送同步请求
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusCreated {
		bodyBytes, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API request failed with status %d: %s", resp.StatusCode, string(bodyBytes))
	}

	// 先读取原始响应数据
	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	// 解析为通用的 JSON 数组
	var rawProducts []json.RawMessage
	if err := json.Unmarshal(bodyBytes, &rawProducts); err != nil {
		return nil, fmt.Errorf("failed to decode raw results: %w", err)
	}

	// 使用标准化函数处理每个产品数据
	products := make([]ProductData, 0, len(rawProducts))
	for _, rawProduct := range rawProducts {
		normalizedProduct, err := NormalizeApifyResponse(rawProduct)
		if err != nil {
			slog.Warn("Failed to normalize product data, skipping", "error", err)
			continue
		}
		products = append(products, *normalizedProduct)
	}

	// 设置抓取时间
	now := time.Now()
	for i := range products {
		products[i].ScrapedAt = now
	}

	c.logger.LogBusinessOperation(ctx, "product_data_fetch_complete", "apify", "sync", "success",
		"asins_requested", len(asins),
		"products_returned", len(products),
	)

	slog.Info("Sync product data fetch completed",
		"asins_count", len(asins),
		"products_count", len(products),
	)

	return products, nil
}
