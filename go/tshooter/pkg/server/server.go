package server

import (
	"context"
	"errors"
	"log"
	"math/rand"
	"regexp"
	"strings"
	"sync"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"google.golang.org/grpc/metadata"

	"tshooter/pkg/backend"
	"tshooter/proto/abi"
)

const (
	clientTimeout = 15
	maxClients    = 8
)

// client contains information about connected clients.
type client struct {
	streamServer abi.Game_StreamServer
	lastMessage  time.Time
	done         chan error
	playerID     uuid.UUID
	id           uuid.UUID
}

// GameServer is used to stream game information with clients.
type GameServer struct {
	abi.UnimplementedGameServer
	game     *backend.Game
	clients  map[uuid.UUID]*client
	mu       sync.RWMutex
	password string
}

// NewGameServer constructs a new game server struct.
func NewGameServer(game *backend.Game, password string) *GameServer {
	server := &GameServer{
		game:     game,
		clients:  make(map[uuid.UUID]*client),
		password: password,
	}
	server.watchChanges()
	server.watchTimeout()
	return server
}

func (s *GameServer) removeClient(id uuid.UUID) {
	s.mu.Lock()
	delete(s.clients, id)
	s.mu.Unlock()
}

func (s *GameServer) removePlayer(playerID uuid.UUID) {
	s.game.Mu.Lock()
	s.game.RemoveEntity(playerID)
	s.game.Mu.Unlock()

	resp := abi.Response{
		Action: &abi.Response_RemoveEntity{
			RemoveEntity: &abi.RemoveEntity{
				Id: playerID.String(),
			},
		},
	}
	s.broadcast(&resp)
}

func (s *GameServer) getClientFromContext(ctx context.Context) (*client, error) {
	headers, ok := metadata.FromIncomingContext(ctx)
	tokenRaw := headers["authorization"]
	if len(tokenRaw) == 0 {
		return nil, errors.New("no token provided")
	}
	token, err := uuid.Parse(tokenRaw[0])
	if err != nil {
		return nil, errors.New("cannot parse token")
	}
	s.mu.RLock()
	currentClient, ok := s.clients[token]
	s.mu.RUnlock()
	if !ok {
		return nil, errors.New("token not recognized")
	}
	return currentClient, nil
}

// Stream is the main loop for dealing with individual players.
func (s *GameServer) Stream(srv abi.Game_StreamServer) error {
	ctx := srv.Context()
	currentClient, err := s.getClientFromContext(ctx)
	if err != nil {
		return err
	}
	if currentClient.streamServer != nil {
		return errors.New("stream already active")
	}
	currentClient.streamServer = srv

	log.Println("start new server")

	// Wait for stream requests.
	go func() {
		for {
			req, err := srv.Recv()
			if err != nil {
				log.Printf("receive error %v", err)
				currentClient.done <- errors.New("failed to receive request")
				return
			}
			log.Printf("got message %+v", req)
			currentClient.lastMessage = time.Now()

			switch req.GetAction().(type) {
			case *abi.Request_Move:
				s.handleMoveRequest(req, currentClient)
			case *abi.Request_Laser:
				s.handleLaserRequest(req, currentClient)
			}
		}
	}()

	// Wait for stream to be done.
	var doneError error
	select {
	case <-ctx.Done():
		doneError = ctx.Err()
	case doneError = <-currentClient.done:
	}
	log.Printf(`stream done with error "%v"`, doneError)

	log.Printf("%s - removing client", currentClient.id)
	s.removeClient(currentClient.id)
	s.removePlayer(currentClient.playerID)

	return doneError
}

func (s *GameServer) Connect(ctx context.Context, req *abi.ConnectRequest) (*abi.ConnectResponse, error) {
	if len(s.clients) >= maxClients {
		return nil, errors.New("The server is full")
	}

	playerID, err := uuid.Parse(req.Id)
	if err != nil {
		return nil, err
	}

	// Exit as early as possible if password is wrong.
	if req.Password != s.password {
		return nil, errors.New("invalid password provided")
	}

	// Check if player already exists.
	s.game.Mu.RLock()
	if s.game.GetEntity(playerID) != nil {
		return nil, errors.New("duplicate player ID provided")
	}
	s.game.Mu.RUnlock()

	re := regexp.MustCompile("^[a-zA-Z0-9]+$")
	if !re.MatchString(req.Name) {
		return nil, errors.New("invalid name provided")
	}
	icon, _ := utf8.DecodeRuneInString(strings.ToUpper(req.Name))

	// Choose a random spawn point.
	spawnPoints := s.game.GetMapByType()[backend.MapTypeSpawn]
	rand.Seed(time.Now().Unix())
	i := rand.Int() % len(spawnPoints)
	startCoordinate := spawnPoints[i]

	// Add the player.
	player := &backend.Player{
		Name:            req.Name,
		Icon:            icon,
		IdentifierBase:  backend.IdentifierBase{UUID: playerID},
		CurrentPosition: startCoordinate,
	}
	s.game.Mu.Lock()
	s.game.AddEntity(player)
	s.game.Mu.Unlock()

	// Build a slice of current entities.
	s.game.Mu.RLock()
	entities := make([]*abi.Entity, 0)
	for _, entity := range s.game.Entities {
		protoEntity := abi.GetProtoEntity(entity)
		if protoEntity != nil {
			entities = append(entities, protoEntity)
		}
	}
	s.game.Mu.RUnlock()

	// Inform all other clients of the new player.
	resp := abi.Response{
		Action: &abi.Response_AddEntity{
			AddEntity: &abi.AddEntity{
				Entity: abi.GetProtoEntity(player),
			},
		},
	}
	s.broadcast(&resp)

	// Add the new client.
	s.mu.Lock()
	token := uuid.New()
	s.clients[token] = &client{
		id:          token,
		playerID:    playerID,
		done:        make(chan error),
		lastMessage: time.Now(),
	}
	s.mu.Unlock()

	return &abi.ConnectResponse{
		Token:    token.String(),
		Entities: entities,
	}, nil
}

func (s *GameServer) watchTimeout() {
	timeoutTicker := time.NewTicker(1 * time.Minute)
	go func() {
		for {
			for _, client := range s.clients {
				if time.Now().Sub(client.lastMessage).Minutes() > clientTimeout {
					client.done <- errors.New("you have been timed out")
					return
				}
			}
			<-timeoutTicker.C
		}
	}()
}

// WatchChanges waits for new game engine changes and broadcasts to clients.
func (s *GameServer) watchChanges() {
	go func() {
		for {
			change := <-s.game.ChangeChannel
			switch change.(type) {
			case backend.MoveChange:
				change := change.(backend.MoveChange)
				s.handleMoveChange(change)
			case backend.AddEntityChange:
				change := change.(backend.AddEntityChange)
				s.handleAddEntityChange(change)
			case backend.RemoveEntityChange:
				change := change.(backend.RemoveEntityChange)
				s.handleRemoveEntityChange(change)
			case backend.PlayerRespawnChange:
				change := change.(backend.PlayerRespawnChange)
				s.handlePlayerRespawnChange(change)
			case backend.RoundOverChange:
				change := change.(backend.RoundOverChange)
				s.handleRoundOverChange(change)
			case backend.RoundStartChange:
				change := change.(backend.RoundStartChange)
				s.handleRoundStartChange(change)
			}
		}
	}()
}

// broadcast sends a response to all clients.
func (s *GameServer) broadcast(resp *abi.Response) {
	s.mu.Lock()
	for id, currentClient := range s.clients {
		if currentClient.streamServer == nil {
			continue
		}
		if err := currentClient.streamServer.Send(resp); err != nil {
			log.Printf("%s - broadcast error %v", id, err)
			currentClient.done <- errors.New("failed to broadcast message")
			continue
		}
		log.Printf("%s - broadcasted %+v", resp, id)
	}
	s.mu.Unlock()
}

// handleMoveRequest makes a request to the game engine to move a player.
func (s *GameServer) handleMoveRequest(req *abi.Request, currentClient *client) {
	move := req.GetMove()
	s.game.ActionChannel <- backend.MoveAction{
		ID:        currentClient.playerID,
		Direction: abi.GetBackendDirection(move.Direction),
		Created:   time.Now(),
	}
}

func (s *GameServer) handleLaserRequest(req *abi.Request, currentClient *client) {
	laser := req.GetLaser()
	id, err := uuid.Parse(laser.Id)
	if err != nil {
		currentClient.done <- errors.New("invalid laser ID provided")
		return
	}
	s.game.Mu.RLock()
	if s.game.GetEntity(id) != nil {
		currentClient.done <- errors.New("duplicate laser ID provided")
		return
	}
	s.game.Mu.RUnlock()
	s.game.ActionChannel <- backend.LaserAction{
		OwnerID:   currentClient.playerID,
		ID:        id,
		Direction: abi.GetBackendDirection(laser.Direction),
		Created:   time.Now(),
	}
}

func (s *GameServer) handleMoveChange(change backend.MoveChange) {
	resp := abi.Response{
		Action: &abi.Response_UpdateEntity{
			UpdateEntity: &abi.UpdateEntity{
				Entity: abi.GetProtoEntity(change.Entity),
			},
		},
	}
	s.broadcast(&resp)
}

func (s *GameServer) handleAddEntityChange(change backend.AddEntityChange) {
	resp := abi.Response{
		Action: &abi.Response_AddEntity{
			AddEntity: &abi.AddEntity{
				Entity: abi.GetProtoEntity(change.Entity),
			},
		},
	}
	s.broadcast(&resp)
}

func (s *GameServer) handleRemoveEntityChange(change backend.RemoveEntityChange) {
	resp := abi.Response{
		Action: &abi.Response_RemoveEntity{
			RemoveEntity: &abi.RemoveEntity{
				Id: change.Entity.ID().String(),
			},
		},
	}
	s.broadcast(&resp)
}

func (s *GameServer) handlePlayerRespawnChange(change backend.PlayerRespawnChange) {
	resp := abi.Response{
		Action: &abi.Response_PlayerRespawn{
			PlayerRespawn: &abi.PlayerRespawn{
				Player:   abi.GetProtoPlayer(change.Player),
				KillerId: change.KilledByID.String(),
			},
		},
	}
	s.broadcast(&resp)
}

func (s *GameServer) handleRoundOverChange(change backend.RoundOverChange) {
	s.game.Mu.RLock()
	defer s.game.Mu.RUnlock()
	resp := abi.Response{
		Action: &abi.Response_RoundOver{
			RoundOver: &abi.RoundOver{
				WinnerId:     s.game.RoundWinner.String(),
				NewRoundTime: s.game.NewRoundAt.Unix(),
			},
		},
	}
	s.broadcast(&resp)
}

func (s *GameServer) handleRoundStartChange(change backend.RoundStartChange) {
	players := []*abi.Player{}
	s.game.Mu.RLock()
	for _, entity := range s.game.Entities {
		player, ok := entity.(*backend.Player)
		if !ok {
			continue
		}
		players = append(players, abi.GetProtoPlayer(player))
	}
	s.game.Mu.RUnlock()
	resp := abi.Response{
		Action: &abi.Response_RoundStart{
			RoundStart: &abi.RoundStart{
				Players: players,
			},
		},
	}
	s.broadcast(&resp)
}
