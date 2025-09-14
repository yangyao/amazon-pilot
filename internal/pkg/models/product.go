package models

import (
	"time"

	"gorm.io/datatypes"
)

// Product 产品模型
type Product struct {
	ID            string         `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	ASIN          string         `gorm:"uniqueIndex;not null;size:10" json:"asin"`
	Title         *string        `gorm:"type:text" json:"title,omitempty"`
	Brand         *string        `gorm:"size:255" json:"brand,omitempty"`
	Category      *string        `gorm:"size:255" json:"category,omitempty"`
	Subcategory   *string        `gorm:"size:255" json:"subcategory,omitempty"`
	Description   *string        `gorm:"type:text" json:"description,omitempty"`
	BulletPoints  datatypes.JSON `gorm:"type:jsonb" json:"bullet_points,omitempty"`
	Images        datatypes.JSON `gorm:"type:jsonb" json:"images,omitempty"`
	Dimensions    datatypes.JSON `gorm:"type:jsonb" json:"dimensions,omitempty"`
	Weight        *float64       `gorm:"type:decimal(10,2)" json:"weight,omitempty"`

	// 基本信息
	Manufacturer *string `gorm:"size:255" json:"manufacturer,omitempty"`
	ModelNumber  *string `gorm:"size:100" json:"model_number,omitempty"`
	UPC          *string `gorm:"size:20" json:"upc,omitempty"`
	EAN          *string `gorm:"size:20" json:"ean,omitempty"`

	// 时间戳
	FirstSeenAt   time.Time  `gorm:"default:now()" json:"first_seen_at"`
	LastUpdatedAt time.Time  `gorm:"default:now()" json:"last_updated_at"`
	DataSource    string     `gorm:"default:apify;size:50" json:"data_source"`

	// 关联
	TrackedBy      []TrackedProduct `gorm:"foreignKey:ProductID" json:"tracked_by,omitempty"`
	PriceHistory   []PriceHistory   `gorm:"foreignKey:ProductID" json:"price_history,omitempty"`
	RankingHistory []RankingHistory `gorm:"foreignKey:ProductID" json:"ranking_history,omitempty"`
}

// TableName 表名
func (Product) TableName() string {
	return "products"
}

// TrackedProduct 用户追踪的产品
type TrackedProduct struct {
	ID                    string     `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	UserID                string     `gorm:"not null;type:uuid" json:"user_id"`
	ProductID             string     `gorm:"not null;type:uuid" json:"product_id"`
	Alias                 *string    `gorm:"size:255" json:"alias,omitempty"`
	IsActive              bool       `gorm:"default:true" json:"is_active"`
	TrackingFrequency     string     `gorm:"default:daily;size:20" json:"tracking_frequency"`
	PriceChangeThreshold  float64    `gorm:"default:10.0;type:decimal(5,2)" json:"price_change_threshold"`
	BSRChangeThreshold    float64    `gorm:"default:30.0;type:decimal(5,2)" json:"bsr_change_threshold"`
	CreatedAt             time.Time  `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt             time.Time  `gorm:"autoUpdateTime" json:"updated_at"`
	LastCheckedAt         *time.Time `json:"last_checked_at,omitempty"`
	NextCheckAt           *time.Time `json:"next_check_at,omitempty"`

	// 关联
	User    User    `gorm:"foreignKey:UserID" json:"user,omitempty"`
	Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// TableName 表名
func (TrackedProduct) TableName() string {
	return "tracked_products"
}

// PriceHistory 价格历史记录
type PriceHistory struct {
	ID                 string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	ProductID          string    `gorm:"not null;type:uuid" json:"product_id"`
	Price              float64   `gorm:"not null;type:decimal(10,2)" json:"price"`
	Currency           string    `gorm:"not null;default:USD;size:3" json:"currency"`
	BuyBoxPrice        *float64  `gorm:"type:decimal(10,2)" json:"buy_box_price,omitempty"`
	IsOnSale           bool      `gorm:"default:false" json:"is_on_sale"`
	DiscountPercentage *float64  `gorm:"type:decimal(5,2)" json:"discount_percentage,omitempty"`
	RecordedAt         time.Time `gorm:"default:now()" json:"recorded_at"`
	DataSource         string    `gorm:"default:apify;size:50" json:"data_source"`

	// 关联
	Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// TableName 表名
func (PriceHistory) TableName() string {
	return "product_price_history"
}

// RankingHistory 排名历史记录
type RankingHistory struct {
	ID          string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	ProductID   string    `gorm:"not null;type:uuid" json:"product_id"`
	Category    string    `gorm:"not null;size:255" json:"category"`
	BSRRank     *int      `json:"bsr_rank,omitempty"`
	BSRCategory *string   `gorm:"size:255" json:"bsr_category,omitempty"`
	Rating      *float64  `gorm:"type:decimal(3,2)" json:"rating,omitempty"`
	ReviewCount int       `gorm:"default:0" json:"review_count"`
	RecordedAt  time.Time `gorm:"default:now()" json:"recorded_at"`
	DataSource  string    `gorm:"default:apify;size:50" json:"data_source"`

	// 关联
	Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// TableName 表名
func (RankingHistory) TableName() string {
	return "product_ranking_history"
}

// ReviewHistory 评论历史记录
type ReviewHistory struct {
	ID              string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	ProductID       string    `gorm:"not null;type:uuid" json:"product_id"`
	ReviewCount     int       `gorm:"default:0" json:"review_count"`
	AverageRating   *float64  `gorm:"type:decimal(3,2)" json:"average_rating,omitempty"`
	FiveStarCount   int       `gorm:"default:0" json:"five_star_count"`
	FourStarCount   int       `gorm:"default:0" json:"four_star_count"`
	ThreeStarCount  int       `gorm:"default:0" json:"three_star_count"`
	TwoStarCount    int       `gorm:"default:0" json:"two_star_count"`
	OneStarCount    int       `gorm:"default:0" json:"one_star_count"`
	RecordedAt      time.Time `gorm:"default:now()" json:"recorded_at"`
	DataSource      string    `gorm:"default:apify;size:50" json:"data_source"`

	// 关联
	Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// TableName 表名
func (ReviewHistory) TableName() string {
	return "product_review_history"
}

// BuyBoxHistory Buy Box历史记录
type BuyBoxHistory struct {
	ID               string    `gorm:"primaryKey;type:uuid;default:gen_random_uuid()" json:"id"`
	ProductID        string    `gorm:"not null;type:uuid" json:"product_id"`
	WinnerSeller     *string   `gorm:"size:255" json:"winner_seller,omitempty"`
	WinnerPrice      *float64  `gorm:"type:decimal(10,2)" json:"winner_price,omitempty"`
	Currency         string    `gorm:"not null;default:USD;size:3" json:"currency"`
	IsPrime          bool      `gorm:"default:false" json:"is_prime"`
	IsFBA            bool      `gorm:"default:false" json:"is_fba"`
	ShippingInfo     *string   `gorm:"type:text" json:"shipping_info,omitempty"`
	AvailabilityText *string   `gorm:"size:255" json:"availability_text,omitempty"`
	RecordedAt       time.Time `gorm:"default:now()" json:"recorded_at"`
	DataSource       string    `gorm:"default:apify;size:50" json:"data_source"`

	// 关联
	Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}

// TableName 表名
func (BuyBoxHistory) TableName() string {
	return "product_buybox_history"
}