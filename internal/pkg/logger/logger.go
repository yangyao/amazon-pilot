package logger

import (
	"context"

	"github.com/zeromicro/go-zero/core/logx"
)

// Logger 统一日志接口
type Logger interface {
	Info(v ...interface{})
	Infof(format string, v ...interface{})
	Error(v ...interface{})
	Errorf(format string, v ...interface{})
	Debug(v ...interface{})
	Debugf(format string, v ...interface{})
}

// ZeroLogger 基于 go-zero 的日志实现
type ZeroLogger struct {
	logger logx.Logger
}

// NewZeroLogger 创建基于 go-zero 的日志器
func NewZeroLogger(ctx context.Context) *ZeroLogger {
	return &ZeroLogger{
		logger: logx.WithContext(ctx),
	}
}

func (l *ZeroLogger) Info(v ...interface{}) {
	l.logger.Info(v...)
}

func (l *ZeroLogger) Infof(format string, v ...interface{}) {
	l.logger.Infof(format, v...)
}

func (l *ZeroLogger) Error(v ...interface{}) {
	l.logger.Error(v...)
}

func (l *ZeroLogger) Errorf(format string, v ...interface{}) {
	l.logger.Errorf(format, v...)
}

func (l *ZeroLogger) Debug(v ...interface{}) {
	l.logger.Info(v...) // go-zero 中 Debug 级别使用 Info
}

func (l *ZeroLogger) Debugf(format string, v ...interface{}) {
	l.logger.Infof(format, v...)
}