package logger

import (
	"context"
	"log/slog"
	"os"
)

// InitStructuredLogger 初始化结构化日志
func InitStructuredLogger() {
	// 创建JSON格式的logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
		AddSource: true,
	}))
	
	// 设置为默认logger
	slog.SetDefault(logger)
}

// ServiceLogger 带服务信息的日志记录器
type ServiceLogger struct {
	serviceName string
	logger      *slog.Logger
}

// NewServiceLogger 创建服务日志记录器
func NewServiceLogger(serviceName string) *ServiceLogger {
	logger := slog.With(
		"service", serviceName,
		"component", "business_logic",
	)
	
	return &ServiceLogger{
		serviceName: serviceName,
		logger:      logger,
	}
}

// Info 记录信息日志
func (sl *ServiceLogger) Info(ctx context.Context, msg string, args ...any) {
	sl.logWithContext(ctx, slog.LevelInfo, msg, args...)
}

// Error 记录错误日志
func (sl *ServiceLogger) Error(ctx context.Context, msg string, args ...any) {
	sl.logWithContext(ctx, slog.LevelError, msg, args...)
}

// Warn 记录警告日志
func (sl *ServiceLogger) Warn(ctx context.Context, msg string, args ...any) {
	sl.logWithContext(ctx, slog.LevelWarn, msg, args...)
}

// Debug 记录调试日志
func (sl *ServiceLogger) Debug(ctx context.Context, msg string, args ...any) {
	sl.logWithContext(ctx, slog.LevelDebug, msg, args...)
}

// logWithContext 带上下文的日志记录
func (sl *ServiceLogger) logWithContext(ctx context.Context, level slog.Level, msg string, args ...any) {
	// 从context提取用户信息
	var logArgs []any
	
	if userID := ctx.Value("user_id"); userID != nil {
		logArgs = append(logArgs, "user_id", userID)
	}
	
	if email := ctx.Value("email"); email != nil {
		logArgs = append(logArgs, "user_email", email)
	}
	
	if plan := ctx.Value("plan"); plan != nil {
		logArgs = append(logArgs, "user_plan", plan)
	}
	
	// 添加业务相关参数
	logArgs = append(logArgs, args...)
	
	sl.logger.Log(ctx, level, msg, logArgs...)
}

// LogBusinessOperation 记录业务操作日志
func (sl *ServiceLogger) LogBusinessOperation(ctx context.Context, operation string, resourceType string, resourceID string, result string, args ...any) {
	logArgs := []any{
		"operation", operation,
		"resource_type", resourceType,
		"resource_id", resourceID,
		"result", result,
	}
	logArgs = append(logArgs, args...)
	
	sl.Info(ctx, "Business operation completed", logArgs...)
}

// LogAPICall 记录API调用日志
func (sl *ServiceLogger) LogAPICall(ctx context.Context, method string, path string, statusCode int, duration int64, args ...any) {
	logArgs := []any{
		"method", method,
		"path", path,
		"status_code", statusCode,
		"duration_ms", duration,
	}
	logArgs = append(logArgs, args...)
	
	level := slog.LevelInfo
	if statusCode >= 400 {
		level = slog.LevelError
	}
	
	sl.logWithContext(ctx, level, "API call completed", logArgs...)
}