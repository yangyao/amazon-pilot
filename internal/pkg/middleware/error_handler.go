package middleware

import (
	"encoding/json"
	"net/http"

	"amazonpilot/internal/pkg/errors"
)

// ErrorHandler 统一错误处理middleware
func ErrorHandler() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if err := recover(); err != nil {
					switch e := err.(type) {
					case *errors.APIError:
						// 设置JSON响应头
						w.Header().Set("Content-Type", "application/json")
						
						// 根据错误代码设置HTTP状态码
						statusCode := getHTTPStatusFromCode(e.ErrorDetail.Code)
						w.WriteHeader(statusCode)
						
						// 序列化并返回JSON错误
						json.NewEncoder(w).Encode(e)
					case error:
						// 其他类型的错误，转换为内部服务器错误
						w.Header().Set("Content-Type", "application/json")
						w.WriteHeader(http.StatusInternalServerError)
						
						internalErr := errors.ErrInternalServer
						json.NewEncoder(w).Encode(internalErr)
					default:
						// 未知错误类型
						w.Header().Set("Content-Type", "application/json")
						w.WriteHeader(http.StatusInternalServerError)
						
						internalErr := errors.ErrInternalServer
						json.NewEncoder(w).Encode(internalErr)
					}
				}
			}()
			
			next.ServeHTTP(w, r)
		})
	}
}

// getHTTPStatusFromCode 根据错误代码返回HTTP状态码
func getHTTPStatusFromCode(code string) int {
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