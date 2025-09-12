package main

import (
	"flag"
	"fmt"

	"amazonpilot/pkg/competitor/config"
	"amazonpilot/pkg/competitor/handler"
	"amazonpilot/pkg/competitor/svc"

	"github.com/zeromicro/go-zero/core/conf"
	"github.com/zeromicro/go-zero/rest"
)

var configFile = flag.String("f", "etc/competitor-api.yaml", "the config file")

func main() {
	flag.Parse()

	var c config.Config
	conf.MustLoad(*configFile, &c)

	server := rest.MustNewServer(c.RestConf)
	defer server.Stop()

	ctx := svc.NewServiceContext(c)
	handler.RegisterHandlers(server, ctx)

	fmt.Printf("Starting competitor server at %s:%d...\n", c.Host, c.Port)
	server.Start()
}
