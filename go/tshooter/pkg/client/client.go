package client

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc/metadata"

	"tshooter/pkg/backend"
	"tshooter/pkg/frontend"
	"tshooter/proto/abi"
)

const (
	positionHistoryLimit = 5
)

// GameClient is used to stream game information to a server and update the
// game state as needed.
type GameClient struct {
	CurrentPlayer   uuid.UUID
	Stream          abi.Game_StreamClient
	Game            *backend.Game
	View            *frontend.View
	positionHistory []backend.Coordinate
}

// NewGameClient constructs a new game client struct.
func NewGameClient(game *backend.Game, view *frontend.View) *GameClient {
	return &GameClient{
		Game:            game,
		View:            view,
		positionHistory: make([]backend.Coordinate, positionHistoryLimit),
	}
}

// Connect connects a new player to the server.
func (c *GameClient) Connect(grpcClient abi.GameClient, playerID uuid.UUID, playerName string, password string) error {
	// Connect to server.
	req := abi.ConnectRequest{
		Id:       playerID.String(),
		Name:     playerName,
		Password: password,
	}
	resp, err := grpcClient.Connect(context.Background(), &req)
	if err != nil {
		return err
	}

	// Add initial entity state.
	for _, entity := range resp.Entities {
		backendEntity := abi.GetBackendEntity(entity)
		if backendEntity == nil {
			return fmt.Errorf("can not get backend entity from %+v", entity)
		}
		c.Game.AddEntity(backendEntity)
	}

	// Initialize stream with token.
	header := metadata.New(map[string]string{"authorization": resp.Token})
	ctx := metadata.NewOutgoingContext(context.Background(), header)
	stream, err := grpcClient.Stream(ctx)
	if err != nil {
		return err
	}

	c.CurrentPlayer = playerID
	c.View.CurrentPlayer = playerID
	c.Stream = stream

	return nil
}

// Exit stops the tview application and prints a message.
// This is needed as stdout is mangled while tview is running.
func (c *GameClient) Exit(message string) {
	c.View.App.Stop()
	log.Println(message)
}

// Start begins the goroutines needed to recieve server changes and send game
// changes.
func (c *GameClient) Start() {
	// Handle local game engine changes.
	go func() {
		for {
			change := <-c.Game.ChangeChannel
			switch change.(type) {
			case backend.MoveChange:
				change := change.(backend.MoveChange)
				c.handleMoveChange(change)
			case backend.AddEntityChange:
				change := change.(backend.AddEntityChange)
				c.handleAddEntityChange(change)
			}
		}
	}()
	// Handle stream messages.
	go func() {
		for {
			resp, err := c.Stream.Recv()
			if err != nil {
				c.Exit(fmt.Sprintf("can not receive, error: %v", err))
				return
			}

			c.Game.Mu.Lock()
			switch resp.GetAction().(type) {
			case *abi.Response_AddEntity:
				c.handleAddEntityResponse(resp)
			case *abi.Response_UpdateEntity:
				c.handleUpdateEntityResponse(resp)
			case *abi.Response_RemoveEntity:
				c.handleRemoveEntityResponse(resp)
			case *abi.Response_PlayerRespawn:
				c.handlePlayerRespawnResponse(resp)
			case *abi.Response_RoundOver:
				c.handleRoundOverResponse(resp)
			case *abi.Response_RoundStart:
				c.handleRoundStartResponse(resp)
			}
			c.Game.Mu.Unlock()
		}
	}()
}

func (c *GameClient) handleMoveChange(change backend.MoveChange) {
	req := abi.Request{
		Action: &abi.Request_Move{
			Move: &abi.Move{
				Direction: abi.GetProtoDirection(change.Direction),
			},
		},
	}
	c.Stream.Send(&req)
	// Store position history to help with stuttering.
	c.positionHistory = append([]backend.Coordinate{change.Position}, c.positionHistory[:positionHistoryLimit]...)
}

func (c *GameClient) handleAddEntityChange(change backend.AddEntityChange) {
	// Note: while abstracting changes like this can be nice, it's odd that we
	// assume that all add entity changes come as a result of the player
	// creating the entity. Maybe more granular changes or the concept of an
	// owner makes sense here.
	switch change.Entity.(type) {
	case *backend.Laser:
		laser := change.Entity.(*backend.Laser)
		req := abi.Request{
			Action: &abi.Request_Laser{
				Laser: abi.GetProtoLaser(laser),
			},
		}
		c.Stream.Send(&req)
	}
}

func (c *GameClient) handleAddEntityResponse(resp *abi.Response) {
	add := resp.GetAddEntity()
	entity := abi.GetBackendEntity(add.Entity)
	if entity == nil {
		c.Exit(fmt.Sprintf("can not get backend entity from %+v", entity))
		return
	}
	// To prevent jittering, ignore lasers we created.
	laser, ok := entity.(*backend.Laser)
	if ok && laser.OwnerID == c.CurrentPlayer {
		return
	}
	c.Game.AddEntity(entity)
}

func (c *GameClient) handleUpdateEntityResponse(resp *abi.Response) {
	update := resp.GetUpdateEntity()
	entity := abi.GetBackendEntity(update.Entity)
	if entity == nil {
		c.Exit(fmt.Sprintf("can not get backend entity from %+v", entity))
		return
	}
	// To prevent jittering, ignore updates for recent positions.
	// Note: This feels OK, but isn't perfect. I think if I refactored the
	// networking to use more targeted responses, i.e. "move confirmed" sent
	// after a player moves, you could compare recent moves instead of
	// positions and do something like rollback networking.
	player, ok := entity.(*backend.Player)
	if ok && player.ID() == c.CurrentPlayer {
		for _, position := range c.positionHistory {
			if player.Position() == position {
				return
			}
		}
	}
	c.Game.UpdateEntity(entity)
}

func (c *GameClient) handleRemoveEntityResponse(resp *abi.Response) {
	remove := resp.GetRemoveEntity()
	id, err := uuid.Parse(remove.Id)
	if err != nil {
		c.Exit(fmt.Sprintf("error when parsing UUID: %v", err))
		return
	}
	c.Game.RemoveEntity(id)
}

func (c *GameClient) handlePlayerRespawnResponse(resp *abi.Response) {
	respawn := resp.GetPlayerRespawn()
	killedByID, err := uuid.Parse(respawn.KillerId)
	if err != nil {
		c.Exit(fmt.Sprintf("error when parsing UUID: %v", err))
		return
	}
	player := abi.GetBackendPlayer(respawn.Player)
	if player == nil {
		c.Exit(fmt.Sprintf("can not get backend player from %+v", respawn.Player))
		return
	}
	c.Game.AddScore(killedByID)
	c.Game.UpdateEntity(player)
}

func (c *GameClient) handleRoundOverResponse(resp *abi.Response) {
	respawn := resp.GetRoundOver()
	roundWinner, err := uuid.Parse(respawn.WinnerId)
	if err != nil {
		c.Exit(fmt.Sprintf("error when parsing UUID: %v", err))
		return
	}
	c.Game.RoundWinner = roundWinner
	c.Game.NewRoundAt = time.Unix(respawn.NewRoundTime, 0)
	c.Game.WaitForRound = true
	c.Game.Score = make(map[uuid.UUID]int)
}

func (c *GameClient) handleRoundStartResponse(resp *abi.Response) {
	roundStart := resp.GetRoundStart()
	c.Game.WaitForRound = false
	for _, protoPlayer := range roundStart.Players {
		player := abi.GetBackendPlayer(protoPlayer)
		if player == nil {
			c.Exit(fmt.Sprintf("can not get backend player from %+v", protoPlayer))
			return
		}
		c.Game.AddEntity(player)
	}
}
