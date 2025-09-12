package errors

import (
	"fmt"
	"net/http"

	"github.com/google/uuid"
)

// APIError 符合API设计文档的错误结构
type APIError struct {
	ErrorDetail ErrorDetail `json:"error"`
}

// ErrorDetail 错误详情
type ErrorDetail struct {
	Code      string           `json:"code"`
	Message   string           `json:"message"`
	Details   []FieldError     `json:"details,omitempty"`
	RequestID string           `json:"request_id"`
	RetryAfter *int             `json:"retry_after,omitempty"`
}

// FieldError 字段级错误
type FieldError struct {
	Field   string `json:"field"`
	Message string `json:"message"`
}

func (e *APIError) Error() string {
	return fmt.Sprintf("APIError: code=%s, message=%s", e.ErrorDetail.Code, e.ErrorDetail.Message)
}

// 预定义错误代码
const (
	CodeValidationError    = "VALIDATION_ERROR"
	CodeUnauthorized      = "UNAUTHORIZED"
	CodeForbidden         = "FORBIDDEN"
	CodeNotFound          = "NOT_FOUND"
	CodeConflict          = "CONFLICT"
	CodeUnprocessableEntity = "UNPROCESSABLE_ENTITY"
	CodeRateLimitExceeded = "RATE_LIMIT_EXCEEDED"
	CodeInternalError     = "INTERNAL_ERROR"
	CodeServiceUnavailable = "SERVICE_UNAVAILABLE"
)

// NewAPIError 创建符合文档格式的错误
func NewAPIError(httpStatus int, code, message string) *APIError {
	return &APIError{
		ErrorDetail: ErrorDetail{
			Code:      code,
			Message:   message,
			RequestID: generateRequestID(),
		},
	}
}

// NewValidationError 创建验证错误
func NewValidationError(message string, fieldErrors []FieldError) *APIError {
	return &APIError{
		ErrorDetail: ErrorDetail{
			Code:      CodeValidationError,
			Message:   message,
			Details:   fieldErrors,
			RequestID: generateRequestID(),
		},
	}
}

// NewRateLimitError 创建限流错误
func NewRateLimitError(retryAfter int) *APIError {
	return &APIError{
		ErrorDetail: ErrorDetail{
			Code:       CodeRateLimitExceeded,
			Message:    "Too many requests",
			RequestID:  generateRequestID(),
			RetryAfter: &retryAfter,
		},
	}
}

// 预定义错误
var (
	ErrInternalServer = NewAPIError(http.StatusInternalServerError, CodeInternalError, "Internal server error")
	ErrUnauthorized   = NewAPIError(http.StatusUnauthorized, CodeUnauthorized, "Invalid or expired token")
	ErrForbidden      = NewAPIError(http.StatusForbidden, CodeForbidden, "Insufficient permissions")
	ErrNotFound       = NewAPIError(http.StatusNotFound, CodeNotFound, "Resource not found")
)

// 便利函数
func NewBadRequestError(message string) *APIError {
	return NewAPIError(http.StatusBadRequest, CodeValidationError, message)
}

func NewUnauthorizedError(message string) *APIError {
	return NewAPIError(http.StatusUnauthorized, CodeUnauthorized, message)
}

func NewConflictError(message string) *APIError {
	return NewAPIError(http.StatusConflict, CodeConflict, message)
}

// generateRequestID 生成请求ID
func generateRequestID() string {
	return "req-" + uuid.New().String()
}