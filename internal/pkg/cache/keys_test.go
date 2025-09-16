package cache

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestProductDataKey(t *testing.T) {
	productID := "test-product-id"
	expected := "amazon_pilot:product_data:test-product-id"

	result := ProductDataKey(productID)

	assert.Equal(t, expected, result)
	assert.Contains(t, result, ProductDataPrefix)
	assert.Contains(t, result, productID)
}

func TestPriceCacheKey(t *testing.T) {
	productID := "test-product-id"
	expected := "amazon_pilot:price:test-product-id"

	result := PriceCacheKey(productID)

	assert.Equal(t, expected, result)
	assert.Contains(t, result, PriceCachePrefix)
	assert.Contains(t, result, productID)
}

func TestRankingCacheKey(t *testing.T) {
	productID := "test-product-id"
	expected := "amazon_pilot:ranking:test-product-id"

	result := RankingCacheKey(productID)

	assert.Equal(t, expected, result)
	assert.Contains(t, result, RankingCachePrefix)
	assert.Contains(t, result, productID)
}

func TestCacheKeyPrefixes(t *testing.T) {
	// 测试所有缓存键前缀的一致性
	assert.Equal(t, "amazon_pilot:product_data:", ProductDataPrefix)
	assert.Equal(t, "amazon_pilot:product:", ProductCachePrefix)
	assert.Equal(t, "amazon_pilot:product_price:", ProductPricePrefix)
	assert.Equal(t, "amazon_pilot:price:", PriceCachePrefix)
	assert.Equal(t, "amazon_pilot:product_ranking:", ProductRankingPrefix)
	assert.Equal(t, "amazon_pilot:ranking:", RankingCachePrefix)

	// 确保所有前缀都以 "amazon_pilot:" 开头
	prefixes := []string{
		ProductDataPrefix, ProductCachePrefix, ProductPricePrefix,
		PriceCachePrefix, ProductRankingPrefix, RankingCachePrefix,
	}

	for _, prefix := range prefixes {
		assert.True(t, len(prefix) > 0, "Prefix should not be empty")
		assert.Contains(t, prefix, "amazon_pilot:", "All prefixes should contain amazon_pilot:")
		assert.True(t, len(prefix) > 14, "Prefix should be longer than just amazon_pilot:")
	}
}

func TestCacheKeyUniqueness(t *testing.T) {
	productID := "same-product-id"

	// 确保不同类型的缓存键不会冲突
	productDataKey := ProductDataKey(productID)
	priceKey := PriceCacheKey(productID)
	rankingKey := RankingCacheKey(productID)

	assert.NotEqual(t, productDataKey, priceKey)
	assert.NotEqual(t, productDataKey, rankingKey)
	assert.NotEqual(t, priceKey, rankingKey)

	// 但都应该包含相同的产品ID
	assert.Contains(t, productDataKey, productID)
	assert.Contains(t, priceKey, productID)
	assert.Contains(t, rankingKey, productID)
}