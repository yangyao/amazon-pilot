package tasks

import (
	"encoding/json"
	"amazonpilot/internal/pkg/apify"
)

// MapApifyDataToProduct 将 Apify 返回的数据映射到产品模型
// 处理字段名差异，如 features -> bullet_points
func MapApifyDataToProduct(data *apify.ProductData, rawJSON []byte) map[string]interface{} {
	updates := map[string]interface{}{
		"title":         data.Title,
		"brand":         data.Brand,
		"category":      data.Category,
		"description":   data.Description,
		"current_price": data.Price,
		"currency":      data.Currency,
		"rating":        data.Rating,
		"review_count":  data.ReviewCount,
		"bsr":           data.BSR,
	}

	// 添加 Buy Box 价格，可能为 nil
	if data.BuyBoxPrice != nil {
		updates["buy_box_price"] = *data.BuyBoxPrice
	} else {
		updates["buy_box_price"] = nil
	}

	// 处理 bullet points - 现在 BulletPoints 字段已经在 NormalizeApifyResponse 中处理了
	if len(data.BulletPoints) > 0 {
		bulletPointsJSON, _ := json.Marshal(data.BulletPoints)
		updates["bullet_points"] = bulletPointsJSON
	}

	// 映射图片
	if len(data.Images) > 0 {
		imagesJSON, _ := json.Marshal(data.Images)
		updates["images"] = imagesJSON
	}

	return updates
}

