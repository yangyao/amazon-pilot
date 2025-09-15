package tasks

import (
	"encoding/json"
	"testing"

	"amazonpilot/internal/pkg/apify"
	"github.com/stretchr/testify/assert"
)


func TestNormalizeApifyResponse_WithFeatures(t *testing.T) {
	// 测试数据：API 返回 features（实际字段名）
	jsonData := `{
		"asin": "B08N5WRWNW",
		"title": "Echo Dot",
		"brand": "Amazon",
		"price": 27.99,
		"currency": "USD",
		"features": [
			"Voice Assistant Built-in: Alexa",
			"Color: Charcoal",
			"Connectivity: Wi-Fi, Bluetooth"
		]
	}`

	data, err := apify.NormalizeApifyResponse([]byte(jsonData))
	assert.NoError(t, err)
	assert.NotNil(t, data)
	assert.Equal(t, "B08N5WRWNW", data.ASIN)
	assert.Equal(t, 3, len(data.BulletPoints))
	assert.Equal(t, "Voice Assistant Built-in: Alexa", data.BulletPoints[0])
}


func TestMapApifyDataToProduct_WithBulletPoints(t *testing.T) {
	// 测试 MapApifyDataToProduct 函数
	data := &apify.ProductData{
		Title:       "Echo Dot",
		Brand:       "Amazon",
		Category:    "Smart Home",
		Description: "Smart speaker with Alexa",
		BulletPoints: []string{
			"Voice control your music",
			"Ready to help",
			"Connect with others",
		},
		Images: []string{
			"https://example.com/image1.jpg",
			"https://example.com/image2.jpg",
		},
	}

	updates := MapApifyDataToProduct(data, nil)

	assert.Equal(t, "Echo Dot", updates["title"])
	assert.Equal(t, "Amazon", updates["brand"])
	assert.Equal(t, "Smart Home", updates["category"])
	assert.Equal(t, "Smart speaker with Alexa", updates["description"])

	// 检查 bullet_points 是否正确序列化
	bulletPointsJSON, ok := updates["bullet_points"].([]byte)
	assert.True(t, ok)

	var bulletPoints []string
	err := json.Unmarshal(bulletPointsJSON, &bulletPoints)
	assert.NoError(t, err)
	assert.Equal(t, 3, len(bulletPoints))
	assert.Equal(t, "Voice control your music", bulletPoints[0])

	// 检查 images 是否正确序列化
	imagesJSON, ok := updates["images"].([]byte)
	assert.True(t, ok)

	var images []string
	err = json.Unmarshal(imagesJSON, &images)
	assert.NoError(t, err)
	assert.Equal(t, 2, len(images))
	assert.Equal(t, "https://example.com/image1.jpg", images[0])
}

func TestMapApifyDataToProduct_WithFeaturesInRawJSON(t *testing.T) {
	// 测试通过 NormalizeApifyResponse 先处理原始 JSON，然后映射到产品
	rawJSON := []byte(`{
		"asin": "B08N5WRWNW",
		"title": "Echo Dot",
		"brand": "Amazon",
		"category": "Smart Home",
		"productDescription": "Smart speaker with Alexa",
		"price": 27.99,
		"currency": "USD",
		"features": [
			"Voice Assistant Built-in: Alexa",
			"Color: Charcoal",
			"Connectivity: Wi-Fi, Bluetooth"
		]
	}`)

	// 先使用标准化函数处理原始数据
	normalizedData, err := apify.NormalizeApifyResponse(rawJSON)
	assert.NoError(t, err)

	// 然后映射到产品更新
	updates := MapApifyDataToProduct(normalizedData, nil)

	// 检查是否正确映射了 features 作为 bullet_points
	bulletPointsJSON, ok := updates["bullet_points"].([]byte)
	assert.True(t, ok)

	var bulletPoints []string
	err = json.Unmarshal(bulletPointsJSON, &bulletPoints)
	assert.NoError(t, err)
	assert.Equal(t, 3, len(bulletPoints))
	assert.Equal(t, "Voice Assistant Built-in: Alexa", bulletPoints[0])
}

func TestMapApifyDataToProduct_EmptyBulletPoints(t *testing.T) {
	// 测试没有 bullet points 的情况
	data := &apify.ProductData{
		Title:       "Echo Dot",
		Brand:       "Amazon",
		Category:    "Smart Home",
		Description: "Smart speaker with Alexa",
	}

	updates := MapApifyDataToProduct(data, nil)

	assert.Equal(t, "Echo Dot", updates["title"])
	// bullet_points 不应该存在于 updates 中
	_, exists := updates["bullet_points"]
	assert.False(t, exists)
}

func TestMapApifyDataToProduct_CompleteData(t *testing.T) {
	// 测试完整数据映射
	data := &apify.ProductData{
		Title:       "Echo Dot (3rd Gen)",
		Brand:       "Amazon",
		Category:    "Electronics > Smart Home",
		Description: "Our most popular smart speaker with a fabric design",
		BulletPoints: []string{
			"Meet Echo Dot - Our most popular smart speaker",
			"Improved speaker quality",
			"Voice control your music",
			"Ready to help",
			"Connect with others",
		},
		Images: []string{
			"https://m.media-amazon.com/images/I/61IxjvmXDtL._AC_SX679_.jpg",
			"https://m.media-amazon.com/images/I/61MbLLagiVL._AC_SX679_.jpg",
			"https://m.media-amazon.com/images/I/61RNVt9kXUL._AC_SX679_.jpg",
		},
	}

	updates := MapApifyDataToProduct(data, nil)

	// 验证所有字段
	assert.Equal(t, "Echo Dot (3rd Gen)", updates["title"])
	assert.Equal(t, "Amazon", updates["brand"])
	assert.Equal(t, "Electronics > Smart Home", updates["category"])
	assert.Equal(t, "Our most popular smart speaker with a fabric design", updates["description"])

	// 验证 bullet_points
	bulletPointsJSON := updates["bullet_points"].([]byte)
	var bulletPoints []string
	json.Unmarshal(bulletPointsJSON, &bulletPoints)
	assert.Equal(t, 5, len(bulletPoints))

	// 验证 images
	imagesJSON := updates["images"].([]byte)
	var images []string
	json.Unmarshal(imagesJSON, &images)
	assert.Equal(t, 3, len(images))
}