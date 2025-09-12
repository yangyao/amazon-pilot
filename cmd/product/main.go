package main

import (
	"flag"
	"fmt"

	"amazonpilot/internal/product/config"
	"amazonpilot/internal/product/handler"
	"amazonpilot/internal/product/svc"

	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/rest"
)

var configFile = flag.String("f", "etc/product-api.yaml", "the config file")

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c)

	server := rest.MustNewServer(c.RestConf)
	defer server.Stop()

	ctx := svc.NewServiceContext(c)
	handler.RegisterHandlers(server, ctx)

	fmt.Printf("Starting product server at %s:%d...\n", c.Host, c.Port)
	server.Start()
}
