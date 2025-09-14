package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"

	"amazonpilot/internal/product/config"
	"amazonpilot/internal/product/handler"
	"amazonpilot/internal/product/svc"

	"github.com/joho/godotenv"
	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/rest"
)

var configFile = flag.String("f", "cmd/product/etc/product-api.yaml", "the config file")

func main() {
	flag.Parse()

	// 加载.env文件
	if err := godotenv.Load(".env"); err != nil {
		log.Printf("Warning: .env file not found: %v", err)
	}

	var c config.Config
	conf.MustLoad(*configFile, &c)

	// 从环境变量设置到config中，供自动生成的routes.go使用
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		panic("JWT_SECRET environment variable is required")
	}

	accessExpireStr := os.Getenv("JWT_ACCESS_EXPIRE")
	if accessExpireStr == "" {
		panic("JWT_ACCESS_EXPIRE environment variable is required")
	}
	accessExpire, err := strconv.ParseInt(accessExpireStr, 10, 64)
	if err != nil {
		panic("Invalid JWT_ACCESS_EXPIRE: " + err.Error())
	}

	// 设置Auth配置到config中
	c.Auth.JWTSecret = jwtSecret
	c.Auth.AccessSecret = jwtSecret
	c.Auth.AccessExpire = accessExpire

	server := rest.MustNewServer(c.RestConf)
	defer server.Stop()

	ctx := svc.NewServiceContext(c)
	handler.RegisterHandlers(server, ctx)

	fmt.Printf("Starting product server at %s:%d...\n", c.Host, c.Port)
	server.Start()
}
