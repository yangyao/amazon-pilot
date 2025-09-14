package utils

import (
	"encoding/json"
	"net/http"

	"amazonpilot/internal/pkg/errors"
)

// HandleError 统一错误处理函数
func HandleError(w http.ResponseWriter, err error) {
	// 检查是否是自定义APIError
	if apiErr, ok := err.(*errors.APIError); ok {
		// 设置正确的HTTP状态码
		statusCode := GetHTTPStatusFromCode(apiErr.ErrorDetail.Code)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(statusCode)
		json.NewEncoder(w).Encode(apiErr)
	} else {
		// 其他类型错误，转换为内部服务器错误
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusInternalServerError)
		internalErr := errors.ErrInternalServer
		json.NewEncoder(w).Encode(internalErr)
	}
}

// GetHTTPStatusFromCode 根据错误代码返回HTTP状态码
func GetHTTPStatusFromCode(code string) int {
	switch code {
	case errors.CodeValidationError:
		return http.StatusBadRequest
	case errors.CodeUnauthorized:
		return http.StatusUnauthorized
	case errors.CodeForbidden:
		return http.StatusForbidden
	case errors.CodeNotFound:
		return http.StatusNotFound
	case errors.CodeConflict:
		return http.StatusConflict
	case errors.CodeUnprocessableEntity:
		return http.StatusUnprocessableEntity
	case errors.CodeRateLimitExceeded:
		return http.StatusTooManyRequests
	case errors.CodeServiceUnavailable:
		return http.StatusServiceUnavailable
	case errors.CodeInternalError:
		return http.StatusInternalServerError
	default:
		return http.StatusInternalServerError
	}
}