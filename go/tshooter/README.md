# [Making a multiplayer game with Go and gRPC](https://mortenson.coffee/blog/making-multiplayer-game-go-and-grpc/)

## Game description

This is “tshooter” - a local or online multiplayer shooting game you play
in your terminal. Players can move in a map and fire lasers at other players.
When a player is hit, they respawn on the map and the shooting player’s score
is increased. When a player reaches 10 kills, the round ends and a new round
begins. You can play the game offline with bots, or online with up to eight
players (but that limit is arbitrary).

## Prerequisites

```bash
# 1. protoc
# 2. plugins
go install google.golang.org/protobuf/cmprotoc-gen-go@v1.28
go install google.golang.org/grpc/cmprotoc-gen-go-grpc@v1.2
```

## Reference and use

Here's a quick reference for common operations on the project:

```bash
# Download go module dependencies
go mod tidy
# Generate protobuf
make proto
# Run gofmt
make fmt
# Build binaries
make build
# Run a local, offline game
make run
# Run a server with defaults
make run-server
# Run a client
make run-client
# Run a bot as a client
make run-bot-client
```

If you run the commands or binaries directly more command line options are
available:

```bash
# Run a server
go run cmd/server.go -port=9999 -bots=2 -password=foo
# Run a local, offline game
go run cmd/client_local.go -bots=2
# Run a bot as a client
go run cmd/bot_client.go -address=":9999"
```
