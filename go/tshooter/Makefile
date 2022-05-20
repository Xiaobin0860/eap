.PHONY: all build run run-client run-client-local run-server proto fmt release

all: proto fmt build 

build:
	# Linux
	for command in client_local client server; do \
		GOOS=linux GOARCH=amd64 go build -ldflags "-s -w" -o "bin/tshooter_linux_$${command}" "cmd/$${command}/main.go"; \
		GOOS=linux GOARCH=amd64 go build -ldflags "-s -w -X main.Command=$${command}" -o "bin/tshooter_linux_launcher_$${command}" cmd/launcher/main.go; \
	done
	# Mac
	for command in client_local client server; do \
		GOOS=darwin GOARCH=amd64 go build -ldflags "-s -w" -o "bin/tshooter_darwin_$${command}" "cmd/$${command}/main.go"; \
		GOOS=darwin GOARCH=amd64 go build -ldflags "-s -w -X main.Command=$${command}" -o "bin/tshooter_darwin_launcher_$${command}" cmd/launcher/main.go; \
	done
	# @todo package .app and .dmg
	# Windows
	for command in client_local client server; do \
		GOOS=windows GOARCH=amd64 go build -ldflags "-s -w" -o "bin/tshooter_windows_$${command}.exe" "cmd/$${command}/main.go"; \
		GOOS=windows GOARCH=amd64 go build -ldflags "-s -w -X main.Command=$${command}.exe" -o "bin/tshooter_windows_launcher_$${command}.exe" cmd/launcher/main.go; \
	done

run-client-local:
run:
	go run cmd/client_local/main.go

run-client:
	go run cmd/client/main.go

run-server:
	go run cmd/server/main.go

proto:
	protoc --go_out=. --go-grpc_out=. proto/*.proto

fmt:
	gofmt -s -w cmd/*/*.go proto/abi/*.go pkg/*/*.go
