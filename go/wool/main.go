package main

import (
	"flag"
	"log"
	"net/http"

	_ "net/http/pprof"
)

func main() {
	go func() {
		log.Println(http.ListenAndServe("localhost:6060", nil))
	}()

	port := flag.Int("p", 8081, "listen port")
	script := flag.String("f", "robot.lua", "lua script")
	flag.Parse()

	server := &ProxyServer{
		Port:   *port,
		Script: *script,
	}

	server.Run()
}
