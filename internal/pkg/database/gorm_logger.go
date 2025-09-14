package database

import (
	"context"
	"encoding/json"
	"log/slog"
	"time"

	"gorm.io/gorm/logger"
)

// JSONLogger GORM的JSON结构化日志适配器
type JSONLogger struct {
	SlowThreshold         time.Duration
	IgnoreRecordNotFoundError bool
}

// NewJSONLogger 创建JSON格式的GORM日志器
func NewJSONLogger() logger.Interface {
	return &JSONLogger{
		SlowThreshold:         200 * time.Millisecond, // 200ms以上的查询记录为慢查询
		IgnoreRecordNotFoundError: true,
	}
}

// LogMode 设置日志级别
func (l *JSONLogger) LogMode(level logger.LogLevel) logger.Interface {
	return l
}

// Info 记录信息日志
func (l *JSONLogger) Info(ctx context.Context, msg string, data ...interface{}) {
	slog.InfoContext(ctx, "gorm_info", "message", msg, "data", data)
}

// Warn 记录警告日志
func (l *JSONLogger) Warn(ctx context.Context, msg string, data ...interface{}) {
	slog.WarnContext(ctx, "gorm_warn", "message", msg, "data", data)
}

// Error 记录错误日志
func (l *JSONLogger) Error(ctx context.Context, msg string, data ...interface{}) {
	slog.ErrorContext(ctx, "gorm_error", "message", msg, "data", data)
}

// Trace 记录SQL查询日志 (JSON格式)
func (l *JSONLogger) Trace(ctx context.Context, begin time.Time, fc func() (sql string, rowsAffected int64), err error) {
	elapsed := time.Since(begin)
	sql, rowsAffected := fc()

	// 构建结构化日志数据
	logData := map[string]interface{}{
		"sql":           sql,
		"duration_ms":   float64(elapsed.Nanoseconds()) / 1e6,
		"rows_affected": rowsAffected,
		"timestamp":     begin.Format(time.RFC3339),
	}

	switch {
	case err != nil && (!l.IgnoreRecordNotFoundError || !isRecordNotFoundError(err)):
		// SQL错误
		logData["error"] = err.Error()
		logData["level"] = "error"

		logJSON, _ := json.Marshal(logData)
		slog.ErrorContext(ctx, "gorm_sql_error", "sql_log", string(logJSON))

	case elapsed > l.SlowThreshold:
		// 慢查询
		logData["level"] = "slow"
		logData["slow_threshold_ms"] = float64(l.SlowThreshold.Nanoseconds()) / 1e6

		logJSON, _ := json.Marshal(logData)
		slog.WarnContext(ctx, "gorm_slow_query", "sql_log", string(logJSON))

	default:
		// 正常查询 (可选：在生产环境中禁用)
		logData["level"] = "info"

		logJSON, _ := json.Marshal(logData)
		slog.DebugContext(ctx, "gorm_sql_query", "sql_log", string(logJSON))
	}
}

// isRecordNotFoundError 检查是否是记录未找到错误
func isRecordNotFoundError(err error) bool {
	return err.Error() == "record not found"
}