package utils

import (
	"fmt"
	"regexp"
	"strings"

	"amazonpilot/internal/pkg/errors"
)

// ValidateASIN 验证Amazon ASIN格式
func ValidateASIN(asin string) error {
	if asin == "" {
		return errors.NewValidationError("ASIN cannot be empty", []errors.FieldError{
			{Field: "asin", Message: "ASIN is required"},
		})
	}

	if len(asin) != 10 {
		return errors.NewValidationError("Invalid ASIN format", []errors.FieldError{
			{Field: "asin", Message: "ASIN must be exactly 10 characters"},
		})
	}

	// ASIN 应该是字母数字组合，通常以B开头
	matched, _ := regexp.MatchString(`^[A-Z0-9]{10}$`, asin)
	if !matched {
		return errors.NewValidationError("Invalid ASIN format", []errors.FieldError{
			{Field: "asin", Message: "ASIN must contain only uppercase letters and numbers"},
		})
	}

	return nil
}

// ValidateEmail 验证邮箱格式
func ValidateEmail(email string) error {
	if email == "" {
		return errors.NewValidationError("Email cannot be empty", []errors.FieldError{
			{Field: "email", Message: "Email is required"},
		})
	}

	// 简单的邮箱格式验证
	emailRegex := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
	matched, _ := regexp.MatchString(emailRegex, email)
	if !matched {
		return errors.NewValidationError("Invalid email format", []errors.FieldError{
			{Field: "email", Message: "Please enter a valid email address"},
		})
	}

	return nil
}

// ValidatePassword 验证密码强度
func ValidatePassword(password string) error {
	if password == "" {
		return errors.NewValidationError("Password cannot be empty", []errors.FieldError{
			{Field: "password", Message: "Password is required"},
		})
	}

	if len(password) < 8 {
		return errors.NewValidationError("Password too short", []errors.FieldError{
			{Field: "password", Message: "Password must be at least 8 characters long"},
		})
	}

	return nil
}

// ValidateProductAlias 验证产品别名
func ValidateProductAlias(alias string) error {
	if alias == "" {
		return nil // 别名是可选的
	}

	if len(alias) > 100 {
		return errors.NewValidationError("Alias too long", []errors.FieldError{
			{Field: "alias", Message: "Alias must be less than 100 characters"},
		})
	}

	// 检查是否包含特殊字符
	if strings.ContainsAny(alias, "<>\"'&") {
		return errors.NewValidationError("Invalid alias format", []errors.FieldError{
			{Field: "alias", Message: "Alias cannot contain special characters like <, >, \", ', &"},
		})
	}

	return nil
}

// ValidateThreshold 验证阈值参数
func ValidateThreshold(threshold float64, fieldName string) error {
	if threshold < 0 {
		return errors.NewValidationError("Invalid threshold", []errors.FieldError{
			{Field: fieldName, Message: "Threshold cannot be negative"},
		})
	}

	if threshold > 100 {
		return errors.NewValidationError("Invalid threshold", []errors.FieldError{
			{Field: fieldName, Message: "Threshold cannot exceed 100%"},
		})
	}

	return nil
}

// ValidatePaginationParams 验证分页参数
func ValidatePaginationParams(page, limit int) error {
	if page < 1 {
		return errors.NewValidationError("Invalid pagination", []errors.FieldError{
			{Field: "page", Message: "Page must be greater than 0"},
		})
	}

	if limit < 1 {
		return errors.NewValidationError("Invalid pagination", []errors.FieldError{
			{Field: "limit", Message: "Limit must be greater than 0"},
		})
	}

	if limit > 100 {
		return errors.NewValidationError("Invalid pagination", []errors.FieldError{
			{Field: "limit", Message: "Limit cannot exceed 100"},
		})
	}

	return nil
}

// SanitizeInput 清理用户输入
func SanitizeInput(input string) string {
	// 移除前后空格
	input = strings.TrimSpace(input)

	// 移除危险字符
	input = strings.ReplaceAll(input, "<script>", "")
	input = strings.ReplaceAll(input, "</script>", "")
	input = strings.ReplaceAll(input, "javascript:", "")

	return input
}

// FormatPrice 格式化价格显示
func FormatPrice(price float64, currency string) string {
	if currency == "" {
		currency = "USD"
	}

	switch currency {
	case "USD":
		return fmt.Sprintf("$%.2f", price)
	case "EUR":
		return fmt.Sprintf("€%.2f", price)
	case "GBP":
		return fmt.Sprintf("£%.2f", price)
	default:
		return fmt.Sprintf("%.2f %s", price, currency)
	}
}