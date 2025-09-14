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

// DeepSeekClient DeepSeek API客户端
type DeepSeekClient struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
}

// NewDeepSeekClient 创建DeepSeek客户端
func NewDeepSeekClient(apiKey string) *DeepSeekClient {
	return &DeepSeekClient{
		apiKey:  apiKey,
		baseURL: "https://api.deepseek.com/v1",
		httpClient: &http.Client{
			Timeout: 60 * time.Second,
		},
	}
}

// GenerateCompetitorReport 生成竞争定位报告
func (c *DeepSeekClient) GenerateCompetitorReport(ctx context.Context, data CompetitorAnalysisData) (*CompetitorReport, error) {
	// 构建提示词
	prompt := c.buildCompetitorAnalysisPrompt(data)

	// 调用DeepSeek API
	response, err := c.callChatCompletion(ctx, prompt)
	if err != nil {
		return nil, fmt.Errorf("failed to call DeepSeek API: %w", err)
	}

	// 严格解析JSON，失败时直接报错
	report, err := c.parseCompetitorReport(response)
	if err != nil {
		return nil, fmt.Errorf("failed to parse DeepSeek response: %w", err)
	}

	return report, nil
}

// buildCompetitorAnalysisPrompt 构建竞品分析提示词
func (c *DeepSeekClient) buildCompetitorAnalysisPrompt(data CompetitorAnalysisData) string {
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
请返回严格的JSON格式竞品分析报告：
{
  "summary": "竞争地位总结",
  "recommendations": [
    {
      "type": "pricing",
      "priority": "high",
      "title": "建议标题",
      "description": "具体建议",
      "impact": "预期影响"
    }
  ],
  "market_insights": ["洞察1", "洞察2"]
}

必须严格按照JSON格式返回，不要添加任何解释文字。`

	return prompt
}

// callChatCompletion 调用DeepSeek聊天完成API
func (c *DeepSeekClient) callChatCompletion(ctx context.Context, prompt string) (string, error) {
	requestBody := map[string]interface{}{
		"model": "deepseek-chat",
		"messages": []map[string]interface{}{
			{
				"role":    "user",
				"content": prompt,
			},
		},
		"temperature": 0.3, // 降低随机性，确保JSON格式
		"max_tokens":  1500,
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
		return "", fmt.Errorf("DeepSeek API error: %s", string(body))
	}

	var deepSeekResp struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}

	if err := json.Unmarshal(body, &deepSeekResp); err != nil {
		return "", fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if len(deepSeekResp.Choices) == 0 {
		return "", fmt.Errorf("no response from DeepSeek")
	}

	return deepSeekResp.Choices[0].Message.Content, nil
}

// parseCompetitorReport 解析DeepSeek响应，支持预处理
func (c *DeepSeekClient) parseCompetitorReport(response string) (*CompetitorReport, error) {
	var report CompetitorReport

	// 第一次尝试：直接解析JSON
	if err := json.Unmarshal([]byte(response), &report); err == nil {
		return &report, nil
	}

	// 第二次尝试：记录原始格式并进行预处理
	fmt.Printf("DeepSeek原始返回格式:\n%s\n", response)

	// 预处理：提取JSON部分
	cleanedResponse := preprocessDeepSeekResponse(response)
	fmt.Printf("预处理后格式:\n%s\n", cleanedResponse)

	// 尝试解析预处理后的内容
	if err := json.Unmarshal([]byte(cleanedResponse), &report); err != nil {
		return nil, fmt.Errorf("DeepSeek response parsing failed even after preprocessing. Original: %s, Cleaned: %s, Error: %w", response, cleanedResponse, err)
	}

	return &report, nil
}

// preprocessDeepSeekResponse 预处理DeepSeek响应，提取JSON部分
func preprocessDeepSeekResponse(response string) string {
	// 查找JSON开始和结束位置
	startIdx := -1
	endIdx := -1

	// 寻找第一个 {
	for i, char := range response {
		if char == '{' {
			startIdx = i
			break
		}
	}

	// 从后往前寻找最后一个 }
	for i := len(response) - 1; i >= 0; i-- {
		if response[i] == '}' {
			endIdx = i + 1
			break
		}
	}

	// 如果找到JSON边界，提取JSON部分
	if startIdx >= 0 && endIdx > startIdx {
		return response[startIdx:endIdx]
	}

	// 如果没找到，返回原始内容
	return response
}