package utils

import (
	"net/http"
	"testing"

	"amazonpilot/internal/pkg/errors"

	"github.com/stretchr/testify/assert"
)

func TestGetHTTPStatusFromCode(t *testing.T) {
	testCases := []struct {
		name         string
		errorCode    string
		expectedHTTP int
	}{
		{
			name:         "Validation Error",
			errorCode:    errors.CodeValidationError,
			expectedHTTP: http.StatusBadRequest,
		},
		{
			name:         "Unauthorized",
			errorCode:    errors.CodeUnauthorized,
			expectedHTTP: http.StatusUnauthorized,
		},
		{
			name:         "Forbidden",
			errorCode:    errors.CodeForbidden,
			expectedHTTP: http.StatusForbidden,
		},
		{
			name:         "Not Found",
			errorCode:    errors.CodeNotFound,
			expectedHTTP: http.StatusNotFound,
		},
		{
			name:         "Conflict",
			errorCode:    errors.CodeConflict,
			expectedHTTP: http.StatusConflict,
		},
		{
			name:         "Unprocessable Entity",
			errorCode:    errors.CodeUnprocessableEntity,
			expectedHTTP: http.StatusUnprocessableEntity,
		},
		{
			name:         "Rate Limit Exceeded",
			errorCode:    errors.CodeRateLimitExceeded,
			expectedHTTP: http.StatusTooManyRequests,
		},
		{
			name:         "Service Unavailable",
			errorCode:    errors.CodeServiceUnavailable,
			expectedHTTP: http.StatusServiceUnavailable,
		},
		{
			name:         "Internal Error",
			errorCode:    errors.CodeInternalError,
			expectedHTTP: http.StatusInternalServerError,
		},
		{
			name:         "Unknown Error Code",
			errorCode:    "UNKNOWN_ERROR",
			expectedHTTP: http.StatusInternalServerError, // 默认返回500
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			result := GetHTTPStatusFromCode(tc.errorCode)
			assert.Equal(t, tc.expectedHTTP, result)
		})
	}
}

func TestGetHTTPStatusFromCode_AllErrorCodes(t *testing.T) {
	// 确保所有定义的错误代码都有对应的HTTP状态码
	errorCodes := map[string]int{
		errors.CodeValidationError:      http.StatusBadRequest,
		errors.CodeUnauthorized:        http.StatusUnauthorized,
		errors.CodeForbidden:           http.StatusForbidden,
		errors.CodeNotFound:            http.StatusNotFound,
		errors.CodeConflict:            http.StatusConflict,
		errors.CodeUnprocessableEntity: http.StatusUnprocessableEntity,
		errors.CodeRateLimitExceeded:   http.StatusTooManyRequests,
		errors.CodeServiceUnavailable:  http.StatusServiceUnavailable,
		errors.CodeInternalError:       http.StatusInternalServerError,
	}

	for errorCode, expectedStatus := range errorCodes {
		result := GetHTTPStatusFromCode(errorCode)
		assert.Equal(t, expectedStatus, result, "Error code %s should map to status %d", errorCode, expectedStatus)
	}
}