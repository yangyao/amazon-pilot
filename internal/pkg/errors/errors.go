package errors

import (
	"fmt"
	"net/http"
)

// AppError 应用错误
type AppError struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Details interface{} `json:"details,omitempty"`
}

func (e *AppError) Error() string {
	return fmt.Sprintf("AppError: code=%d, message=%s", e.Code, e.Message)
}

// 预定义错误
var (
	ErrInternalServer = &AppError{Code: http.StatusInternalServerError, Message: "Internal server error"}
	ErrBadRequest     = &AppError{Code: http.StatusBadRequest, Message: "Bad request"}
	ErrUnauthorized   = &AppError{Code: http.StatusUnauthorized, Message: "Unauthorized"}
	ErrForbidden      = &AppError{Code: http.StatusForbidden, Message: "Forbidden"}
	ErrNotFound       = &AppError{Code: http.StatusNotFound, Message: "Not found"}
)

// NewError 创建新错误
func NewError(code int, message string) *AppError {
	return &AppError{Code: code, Message: message}
}

// NewErrorWithDetails 创建带详情的错误
func NewErrorWithDetails(code int, message string, details interface{}) *AppError {
	return &AppError{Code: code, Message: message, Details: details}
}