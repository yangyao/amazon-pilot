package llm

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

// OpenAIClient OpenAI API客户端
type OpenAIClient struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
}

// CompetitorAnalysisData 竞品分析数据
type CompetitorAnalysisData struct {
	MainProduct    ProductData   `json:"main_product"`
	Competitors    []ProductData `json:"competitors"`
	AnalysisMetrics []string     `json:"analysis_metrics"`
}

// ProductData 产品数据
type ProductData struct {
	ASIN        string   `json:"asin"`
	Title       string   `json:"title"`
	Price       float64  `json:"price"`
	Currency    string   `json:"currency"`
	BSR         int      `json:"bsr"`
	Rating      float64  `json:"rating"`
	ReviewCount int      `json:"review_count"`
	BulletPoints []string `json:"bullet_points,omitempty"`
}

// CompetitorReport 竞争定位报告
type CompetitorReport struct {
	Summary          string                 `json:"summary"`
	PriceAnalysis    PriceAnalysis         `json:"price_analysis"`
	BSRAnalysis      BSRAnalysis           `json:"bsr_analysis"`
	RatingAnalysis   RatingAnalysis        `json:"rating_analysis"`
	FeatureAnalysis  FeatureAnalysis       `json:"feature_analysis"`
	Recommendations  []Recommendation      `json:"recommendations"`
	MarketInsights   []string              `json:"market_insights"`
}

// 分析结构
type PriceAnalysis struct {
	MainProductPrice   float64 `json:"main_product_price"`
	AvgCompetitorPrice float64 `json:"avg_competitor_price"`
	PriceDifference    float64 `json:"price_difference"`
	PricePosition      string  `json:"price_position"` // "higher", "lower", "competitive"
	Insight            string  `json:"insight"`
}

type BSRAnalysis struct {
	MainProductBSR   int    `json:"main_product_bsr"`
	AvgCompetitorBSR int    `json:"avg_competitor_bsr"`
	RankingPosition  string `json:"ranking_position"` // "better", "worse", "competitive"
	Insight          string `json:"insight"`
}

type RatingAnalysis struct {
	MainProductRating   float64 `json:"main_product_rating"`
	AvgCompetitorRating float64 `json:"avg_competitor_rating"`
	RatingPosition      string  `json:"rating_position"` // "higher", "lower", "competitive"
	Insight             string  `json:"insight"`
}

type FeatureAnalysis struct {
	MainProductFeatures   []string `json:"main_product_features"`
	CommonCompetitorFeatures []string `json:"common_competitor_features"`
	UniqueFeatures        []string `json:"unique_features"`
	MissingFeatures       []string `json:"missing_features"`
	Insight               string   `json:"insight"`
}

type Recommendation struct {
	Type        string `json:"type"`        // "pricing", "features", "positioning"
	Priority    string `json:"priority"`    // "high", "medium", "low"
	Title       string `json:"title"`
	Description string `json:"description"`
	Impact      string `json:"impact"`
}

// NewOpenAIClient 创建LLM客户端（支持OpenAI和DeepSeek）
func NewOpenAIClient(apiKey string) *OpenAIClient {
	baseURL := "https://api.openai.com/v1"
	// 如果是DeepSeek API Key，使用DeepSeek endpoint
	if len(apiKey) > 0 && apiKey[:3] == "sk-" && len(apiKey) < 60 {
		baseURL = "https://api.deepseek.com/v1"
	}

	return &OpenAIClient{
		apiKey:  apiKey,
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// GenerateCompetitorReport 生成竞争定位报告
func (c *OpenAIClient) GenerateCompetitorReport(ctx context.Context, data CompetitorAnalysisData) (*CompetitorReport, error) {
	// 构建提示词
	prompt := c.buildCompetitorAnalysisPrompt(data)

	// 调用OpenAI API
	response, err := c.callChatCompletion(ctx, prompt)
	if err != nil {
		return nil, fmt.Errorf("failed to call OpenAI API: %w", err)
	}

	// 解析响应为结构化报告
	report, err := c.parseCompetitorReport(response)
	if err != nil {
		return nil, fmt.Errorf("failed to parse OpenAI response: %w", err)
	}

	return report, nil
}

// buildCompetitorAnalysisPrompt 构建竞品分析提示词
func (c *OpenAIClient) buildCompetitorAnalysisPrompt(data CompetitorAnalysisData) string {
	prompt := fmt.Sprintf(`作为Amazon市场分析专家，请对以下产品进行深度竞品分析：

主产品：
- ASIN: %s
- 标题: %s
- 价格: %.2f %s
- BSR排名: %d
- 评分: %.1f (%d条评论)
`, data.MainProduct.ASIN, data.MainProduct.Title, data.MainProduct.Price, data.MainProduct.Currency, data.MainProduct.BSR, data.MainProduct.Rating, data.MainProduct.ReviewCount)

	prompt += "\n竞品产品：\n"
	for i, competitor := range data.Competitors {
		prompt += fmt.Sprintf(`%d. ASIN: %s, 价格: %.2f %s, BSR: %d, 评分: %.1f (%d条评论)
`, i+1, competitor.ASIN, competitor.Price, competitor.Currency, competitor.BSR, competitor.Rating, competitor.ReviewCount)
	}

	prompt += `
请按以下JSON格式返回详细的竞争定位分析报告：

{
  "summary": "简要总结主产品的竞争地位",
  "price_analysis": {
    "main_product_price": 主产品价格,
    "avg_competitor_price": 竞品平均价格,
    "price_difference": 价格差异百分比,
    "price_position": "higher/lower/competitive",
    "insight": "价格竞争力分析"
  },
  "bsr_analysis": {
    "main_product_bsr": 主产品BSR,
    "avg_competitor_bsr": 竞品平均BSR,
    "ranking_position": "better/worse/competitive",
    "insight": "排名竞争力分析"
  },
  "rating_analysis": {
    "main_product_rating": 主产品评分,
    "avg_competitor_rating": 竞品平均评分,
    "rating_position": "higher/lower/competitive",
    "insight": "用户满意度分析"
  },
  "recommendations": [
    {
      "type": "pricing/features/positioning",
      "priority": "high/medium/low",
      "title": "建议标题",
      "description": "具体建议内容",
      "impact": "预期影响"
    }
  ],
  "market_insights": ["市场洞察1", "市场洞察2", "市场洞察3"]
}

要求：
1. 数据分析要客观准确
2. 建议要具体可行
3. 严格按照JSON格式返回
4. 中文回复`

	return prompt
}

// callChatCompletion 调用OpenAI聊天完成API
func (c *OpenAIClient) callChatCompletion(ctx context.Context, prompt string) (string, error) {
	requestBody := map[string]interface{}{
		"model": "gpt-3.5-turbo",
		"messages": []map[string]interface{}{
			{
				"role":    "user",
				"content": prompt,
			},
		},
		"temperature": 0.7,
		"max_tokens":  2000,
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, "POST", c.baseURL+"/chat/completions", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to make request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("OpenAI API error: %s", string(body))
	}

	var openAIResp struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	if err := json.Unmarshal(body, &openAIResp); err != nil {
		return "", fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if len(openAIResp.Choices) == 0 {
		return "", fmt.Errorf("no response from OpenAI")
	}

	return openAIResp.Choices[0].Message.Content, nil
}

// parseCompetitorReport 解析OpenAI响应为结构化报告
func (c *OpenAIClient) parseCompetitorReport(response string) (*CompetitorReport, error) {
	var report CompetitorReport

	// 尝试直接解析JSON
	if err := json.Unmarshal([]byte(response), &report); err != nil {
		return nil, fmt.Errorf("failed to parse JSON response: %w", err)
	}

	return &report, nil
}