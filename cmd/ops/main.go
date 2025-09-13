package main

import (
	"flag"
	"fmt"

	"amazonpilot/internal/ops/config"
	"amazonpilot/internal/ops/handler"
	"amazonpilot/internal/ops/svc"

	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/rest"
)

var configFile = flag.String("f", "cmd/ops/etc/ops-api.yaml", "the config file")

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c)

	server := rest.MustNewServer(c.RestConf)
	defer server.Stop()

	ctx := svc.NewServiceContext(c)
	handler.RegisterHandlers(server, ctx)

	fmt.Printf("Starting Ops server at %s:%d...\n", c.Host, c.Port)
	server.Start()
}