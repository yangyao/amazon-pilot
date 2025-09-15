package cache

import "fmt"

// Cache key prefixes
const (
	// Product related cache keys
	ProductCachePrefix       = "amazon_pilot:product:"
	PriceCachePrefix        = "amazon_pilot:price:"
	RankingCachePrefix      = "amazon_pilot:ranking:"

	// User related cache keys
	UserTrackedPrefix       = "amazon_pilot:user_tracked:"

	// Product-specific cache keys (new approach)
	ProductDataPrefix       = "amazon_pilot:product_data:"
	ProductPricePrefix      = "amazon_pilot:product_price:"
	ProductRankingPrefix    = "amazon_pilot:product_ranking:"
)

// Product cache key builders
func ProductCacheKey(productID string) string {
	return fmt.Sprintf("%s%s", ProductCachePrefix, productID)
}

func ProductDataKey(productID string) string {
	return fmt.Sprintf("%s%s", ProductDataPrefix, productID)
}

func ProductPriceKey(productID string) string {
	return fmt.Sprintf("%s%s", ProductPricePrefix, productID)
}

func ProductRankingKey(productID string) string {
	return fmt.Sprintf("%s%s", ProductRankingPrefix, productID)
}

// Price cache key builders
func PriceCacheKey(productID string) string {
	return fmt.Sprintf("%s%s", PriceCachePrefix, productID)
}

func RankingCacheKey(productID string) string {
	return fmt.Sprintf("%s%s", RankingCachePrefix, productID)
}

// User cache key builders
func UserTrackedKey(userID string) string {
	return fmt.Sprintf("%s%s", UserTrackedPrefix, userID)
}

// Legacy cache key builders (for backward compatibility)
func LegacyTrackedKey(userID string) string {
	return fmt.Sprintf("amazon_pilot:tracked:%s", userID)
}

// Pattern builders for batch operations
func ProductCachePattern() string {
	return ProductCachePrefix + "*"
}

func UserTrackedPattern(userID string) string {
	return fmt.Sprintf("%s%s", UserTrackedPrefix, userID)
}

func AllProductDataPattern() string {
	return ProductDataPrefix + "*"
}

func AllProductPricePattern() string {
	return ProductPricePrefix + "*"
}

func AllProductRankingPattern() string {
	return ProductRankingPrefix + "*"
}