package errors

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestErrorCodes(t *testing.T) {
	// 测试所有错误代码常量
	assert.Equal(t, "VALIDATION_ERROR", CodeValidationError)
	assert.Equal(t, "UNAUTHORIZED", CodeUnauthorized)
	assert.Equal(t, "FORBIDDEN", CodeForbidden)
	assert.Equal(t, "NOT_FOUND", CodeNotFound)
	assert.Equal(t, "CONFLICT", CodeConflict)
	assert.Equal(t, "UNPROCESSABLE_ENTITY", CodeUnprocessableEntity)
	assert.Equal(t, "RATE_LIMIT_EXCEEDED", CodeRateLimitExceeded)
	assert.Equal(t, "INTERNAL_ERROR", CodeInternalError)
	assert.Equal(t, "SERVICE_UNAVAILABLE", CodeServiceUnavailable)
}

func TestAPIErrorCreation(t *testing.T) {
	testCases := []struct {
		name        string
		code        string
		message     string
		expectError bool
	}{
		{
			name:        "Valid API Error",
			code:        CodeValidationError,
			message:     "Test validation error",
			expectError: false,
		},
		{
			name:        "Valid Unauthorized Error",
			code:        CodeUnauthorized,
			message:     "Test unauthorized error",
			expectError: false,
		},
		{
			name:        "Valid Not Found Error",
			code:        CodeNotFound,
			message:     "Test not found error",
			expectError: false,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := NewAPIError(400, tc.code, tc.message)

			assert.NotNil(t, err)
			assert.Equal(t, tc.code, err.ErrorDetail.Code)
			assert.Equal(t, tc.message, err.ErrorDetail.Message)
			assert.NotEmpty(t, err.ErrorDetail.RequestID)
			assert.Contains(t, err.ErrorDetail.RequestID, "req-")

			// 测试 Error() 方法
			errorStr := err.Error()
			assert.Contains(t, errorStr, tc.code)
			assert.Contains(t, errorStr, tc.message)
		})
	}
}

func TestPreDefinedErrors(t *testing.T) {
	// 测试预定义错误实例
	errors := map[string]*APIError{
		"InternalServer": ErrInternalServer,
		"Unauthorized":   ErrUnauthorized,
		"Forbidden":      ErrForbidden,
		"NotFound":       ErrNotFound,
	}

	for name, err := range errors {
		t.Run(name, func(t *testing.T) {
			assert.NotNil(t, err)
			assert.NotEmpty(t, err.ErrorDetail.Code)
			assert.NotEmpty(t, err.ErrorDetail.Message)
			assert.NotEmpty(t, err.ErrorDetail.RequestID)
		})
	}
}

func TestValidationErrorWithDetails(t *testing.T) {
	fieldErrors := []FieldError{
		{Field: "email", Message: "Email is required"},
		{Field: "password", Message: "Password must be at least 8 characters"},
	}

	err := NewValidationError("Multiple validation errors", fieldErrors)

	assert.NotNil(t, err)
	assert.Equal(t, CodeValidationError, err.ErrorDetail.Code)
	assert.Equal(t, "Multiple validation errors", err.ErrorDetail.Message)
	assert.Len(t, err.ErrorDetail.Details, 2)

	// 验证字段错误
	assert.Equal(t, "email", err.ErrorDetail.Details[0].Field)
	assert.Equal(t, "Email is required", err.ErrorDetail.Details[0].Message)
	assert.Equal(t, "password", err.ErrorDetail.Details[1].Field)
	assert.Equal(t, "Password must be at least 8 characters", err.ErrorDetail.Details[1].Message)
}

func TestRateLimitError(t *testing.T) {
	retryAfter := 60
	err := NewRateLimitError(retryAfter)

	assert.NotNil(t, err)
	assert.Equal(t, CodeRateLimitExceeded, err.ErrorDetail.Code)
	assert.Equal(t, "Too many requests", err.ErrorDetail.Message)
	assert.NotNil(t, err.ErrorDetail.RetryAfter)
	assert.Equal(t, 60, *err.ErrorDetail.RetryAfter)
}