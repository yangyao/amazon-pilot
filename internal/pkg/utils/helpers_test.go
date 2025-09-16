package utils

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSanitizeInput(t *testing.T) {
	testCases := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "Normal Input",
			input:    "Hello World",
			expected: "Hello World",
		},
		{
			name:     "Input with Leading/Trailing Spaces",
			input:    "  Hello World  ",
			expected: "Hello World",
		},
		{
			name:     "Input with Script Tags",
			input:    "Hello <script>alert('xss')</script> World",
			expected: "Hello alert('xss') World",
		},
		{
			name:     "Input with JavaScript Protocol",
			input:    "javascript:alert('xss')",
			expected: "alert('xss')",
		},
		{
			name:     "Empty Input",
			input:    "",
			expected: "",
		},
		{
			name:     "Only Spaces",
			input:    "   ",
			expected: "",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := SanitizeInput(tc.input)
			assert.Equal(t, tc.expected, result)
		})
	}
}

func TestFormatPrice(t *testing.T) {
	testCases := []struct {
		name     string
		price    float64
		currency string
		expected string
	}{
		{
			name:     "USD Price",
			price:    29.99,
			currency: "USD",
			expected: "$29.99",
		},
		{
			name:     "EUR Price",
			price:    25.50,
			currency: "EUR",
			expected: "€25.50",
		},
		{
			name:     "GBP Price",
			price:    22.75,
			currency: "GBP",
			expected: "£22.75",
		},
		{
			name:     "Unknown Currency",
			price:    100.00,
			currency: "JPY",
			expected: "100.00 JPY",
		},
		{
			name:     "Empty Currency (Default to USD)",
			price:    15.00,
			currency: "",
			expected: "$15.00",
		},
		{
			name:     "Zero Price",
			price:    0.00,
			currency: "USD",
			expected: "$0.00",
		},
		{
			name:     "High Precision Price",
			price:    29.999,
			currency: "USD",
			expected: "$30.00", // 应该四舍五入到2位小数
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := FormatPrice(tc.price, tc.currency)
			assert.Equal(t, tc.expected, result)
		})
	}
}

func TestValidateProductAlias(t *testing.T) {
	testCases := []struct {
		name      string
		alias     string
		expectErr bool
	}{
		{
			name:      "Valid Alias",
			alias:     "My Favorite Product",
			expectErr: false,
		},
		{
			name:      "Empty Alias (Optional)",
			alias:     "",
			expectErr: false,
		},
		{
			name:      "Alias with Numbers",
			alias:     "Product 123",
			expectErr: false,
		},
		{
			name:      "Long Valid Alias",
			alias:     "This is a very long product alias but still under 100 characters",
			expectErr: false,
		},
		{
			name:      "Too Long Alias",
			alias:     string(make([]byte, 101)), // 101个字符
			expectErr: true,
		},
		{
			name:      "Alias with Dangerous Characters",
			alias:     "Product <script>",
			expectErr: true,
		},
		{
			name:      "Alias with Quotes",
			alias:     "Product \"Name\"",
			expectErr: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidateProductAlias(tc.alias)

			if tc.expectErr {
				assert.Error(t, err, "Expected error for alias: %s", tc.alias)
			} else {
				assert.NoError(t, err, "Expected no error for alias: %s", tc.alias)
			}
		})
	}
}

func TestValidateThreshold(t *testing.T) {
	testCases := []struct {
		name      string
		threshold float64
		fieldName string
		expectErr bool
	}{
		{
			name:      "Valid Threshold",
			threshold: 10.5,
			fieldName: "price_threshold",
			expectErr: false,
		},
		{
			name:      "Zero Threshold",
			threshold: 0.0,
			fieldName: "price_threshold",
			expectErr: false,
		},
		{
			name:      "Maximum Threshold",
			threshold: 100.0,
			fieldName: "bsr_threshold",
			expectErr: false,
		},
		{
			name:      "Negative Threshold",
			threshold: -5.0,
			fieldName: "price_threshold",
			expectErr: true,
		},
		{
			name:      "Threshold Over 100",
			threshold: 150.0,
			fieldName: "bsr_threshold",
			expectErr: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidateThreshold(tc.threshold, tc.fieldName)

			if tc.expectErr {
				assert.Error(t, err, "Expected error for threshold: %f", tc.threshold)
			} else {
				assert.NoError(t, err, "Expected no error for threshold: %f", tc.threshold)
			}
		})
	}
}

func TestValidatePaginationParams(t *testing.T) {
	testCases := []struct {
		name      string
		page      int
		limit     int
		expectErr bool
	}{
		{
			name:      "Valid Pagination",
			page:      1,
			limit:     20,
			expectErr: false,
		},
		{
			name:      "Large Page Number",
			page:      999,
			limit:     50,
			expectErr: false,
		},
		{
			name:      "Maximum Limit",
			page:      1,
			limit:     100,
			expectErr: false,
		},
		{
			name:      "Zero Page",
			page:      0,
			limit:     20,
			expectErr: true,
		},
		{
			name:      "Negative Page",
			page:      -1,
			limit:     20,
			expectErr: true,
		},
		{
			name:      "Zero Limit",
			page:      1,
			limit:     0,
			expectErr: true,
		},
		{
			name:      "Negative Limit",
			page:      1,
			limit:     -5,
			expectErr: true,
		},
		{
			name:      "Limit Too Large",
			page:      1,
			limit:     150,
			expectErr: true,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidatePaginationParams(tc.page, tc.limit)

			if tc.expectErr {
				assert.Error(t, err, "Expected error for page: %d, limit: %d", tc.page, tc.limit)
			} else {
				assert.NoError(t, err, "Expected no error for page: %d, limit: %d", tc.page, tc.limit)
			}
		})
	}
}