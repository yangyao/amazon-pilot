package main

import (
	"flag"
	"fmt"

	"amazonpilot/pkg/optimization/config"
	"amazonpilot/pkg/optimization/handler"
	"amazonpilot/pkg/optimization/svc"

	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/rest"
)

var configFile = flag.String("f", "etc/optimization-api.yaml", "the config file")

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c)

	server := rest.MustNewServer(c.RestConf)
	defer server.Stop()

	ctx := svc.NewServiceContext(c)
	handler.RegisterHandlers(server, ctx)

	fmt.Printf("Starting optimization server at %s:%d...\n", c.Host, c.Port)
	server.Start()
}
