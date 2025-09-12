package types

import "time"

// CommonResponse 统一响应结构
type CommonResponse struct {
	Code      int         `json:"code"`
	Message   string      `json:"message"`
	Data      interface{} `json:"data,omitempty"`
	Timestamp int64       `json:"timestamp"`
}

// NewSuccessResponse 创建成功响应
func NewSuccessResponse(data interface{}) *CommonResponse {
	return &CommonResponse{
		Code:      200,
		Message:   "success",
		Data:      data,
		Timestamp: time.Now().Unix(),
	}
}

// NewErrorResponse 创建错误响应
func NewErrorResponse(code int, message string) *CommonResponse {
	return &CommonResponse{
		Code:      code,
		Message:   message,
		Timestamp: time.Now().Unix(),
	}
}

// PageRequest 分页请求
type PageRequest struct {
	Page     int `json:"page,default=1" form:"page"`
	PageSize int `json:"pageSize,default=10" form:"pageSize"`
}

// PageResponse 分页响应
type PageResponse struct {
	Total    int64       `json:"total"`
	Page     int         `json:"page"`
	PageSize int         `json:"pageSize"`
	Items    interface{} `json:"items"`
}