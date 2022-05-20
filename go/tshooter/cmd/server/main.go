package main

// Runs a game server.

import (
	"flag"
	"fmt"
	"log"
	"net"

	"google.golang.org/grpc"

	"tshooter/pkg/backend"
	"tshooter/pkg/bot"
	"tshooter/pkg/server"
	"tshooter/proto/abi"
)

func main() {
	port := flag.Int("port", 8888, "The port to listen on.")
	password := flag.String("password", "", "The server password.")
	numBots := flag.Int("bots", 0, "The number of bots to add to the server.")
	flag.Parse()

	log.Printf("listening on port %d", *port)
	lis, err := net.Listen("tcp", fmt.Sprintf(":%d", *port))
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	game := backend.NewGame()

	bots := bot.NewBots(game)
	for i := 0; i < *numBots; i++ {
		bots.AddBot(fmt.Sprintf("Bob %d", i))
	}

	game.Start()
	bots.Start()

	s := grpc.NewServer()
	server := server.NewGameServer(game, *password)
	abi.RegisterGameServer(s, server)

	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
