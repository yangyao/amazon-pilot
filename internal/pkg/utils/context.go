package utils

import (
	"context"
	"log/slog"

	"amazonpilot/internal/pkg/errors"
)

// GetUserIDFromContext 从JWT context获取用户ID
func GetUserIDFromContext(ctx context.Context) (string, error) {
	userID := ctx.Value("user_id")
	if userID == nil {
		slog.Warn("User ID not found in context")
		return "", errors.ErrUnauthorized
	}
	
	userIDStr, ok := userID.(string)
	if !ok {
		slog.Error("Invalid user ID type in context", "type", userID)
		return "", errors.ErrUnauthorized
	}
	
	return userIDStr, nil
}

// GetUserEmailFromContext 从JWT context获取用户邮箱
func GetUserEmailFromContext(ctx context.Context) (string, error) {
	email := ctx.Value("email")
	if email == nil {
		return "", errors.ErrUnauthorized
	}
	
	emailStr, ok := email.(string)
	if !ok {
		return "", errors.ErrUnauthorized
	}
	
	return emailStr, nil
}

// GetUserPlanFromContext 从JWT context获取用户计划
func GetUserPlanFromContext(ctx context.Context) string {
	plan := ctx.Value("plan")
	if plan == nil {
		return "basic" // 默认计划
	}
	
	planStr, ok := plan.(string)
	if !ok {
		return "basic"
	}
	
	return planStr
}

// LogWithUserContext 带用户上下文的日志记录
func LogWithUserContext(ctx context.Context, level slog.Level, msg string, args ...any) {
	userID, _ := GetUserIDFromContext(ctx)
	email, _ := GetUserEmailFromContext(ctx)
	plan := GetUserPlanFromContext(ctx)
	
	// 添加用户上下文到日志
	logArgs := append([]any{
		"user_id", userID,
		"user_email", email,
		"user_plan", plan,
	}, args...)
	
	slog.Log(ctx, level, msg, logArgs...)
}

// LogInfo 信息级别日志
func LogInfo(ctx context.Context, msg string, args ...any) {
	LogWithUserContext(ctx, slog.LevelInfo, msg, args...)
}

// LogError 错误级别日志
func LogError(ctx context.Context, msg string, args ...any) {
	LogWithUserContext(ctx, slog.LevelError, msg, args...)
}

// LogWarn 警告级别日志
func LogWarn(ctx context.Context, msg string, args ...any) {
	LogWithUserContext(ctx, slog.LevelWarn, msg, args...)
}

// LogDebug 调试级别日志
func LogDebug(ctx context.Context, msg string, args ...any) {
	LogWithUserContext(ctx, slog.LevelDebug, msg, args...)
}