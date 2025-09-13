package middleware

import (
	"encoding/json"
	"net/http"

	"amazonpilot/internal/pkg/errors"

	"github.com/google/uuid"
)

// GatewayErrorHandler Gateway错误处理器
func GatewayErrorHandler(w http.ResponseWriter, code int, message string) {
	// 创建符合API设计文档的错误格式
	apiError := &errors.APIError{
		ErrorDetail: errors.ErrorDetail{
			Code:      getErrorCode(code),
			Message:   message,
			RequestID: "req-" + uuid.New().String(),
		},
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json.NewEncoder(w).Encode(apiError)
}

// getErrorCode 根据HTTP状态码获取错误代码
func getErrorCode(httpCode int) string {
	switch httpCode {
	case http.StatusBadRequest:
		return errors.CodeValidationError
	case http.StatusUnauthorized:
		return errors.CodeUnauthorized
	case http.StatusForbidden:
		return errors.CodeForbidden
	case http.StatusNotFound:
		return errors.CodeNotFound
	case http.StatusConflict:
		return errors.CodeConflict
	case http.StatusTooManyRequests:
		return errors.CodeRateLimitExceeded
	case http.StatusInternalServerError:
		return errors.CodeInternalError
	case http.StatusServiceUnavailable:
		return errors.CodeServiceUnavailable
	default:
		return errors.CodeInternalError
	}
}