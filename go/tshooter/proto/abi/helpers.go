package abi

import (
	"log"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"tshooter/pkg/backend"
)

func GetBackendDirection(protoDirection Direction) backend.Direction {
	direction := backend.DirectionStop
	switch protoDirection {
	case Direction_UP:
		direction = backend.DirectionUp
	case Direction_DOWN:
		direction = backend.DirectionDown
	case Direction_LEFT:
		direction = backend.DirectionLeft
	case Direction_RIGHT:
		direction = backend.DirectionRight
	}
	return direction
}

func GetProtoDirection(direction backend.Direction) Direction {
	protoDirection := Direction_STOP
	switch direction {
	case backend.DirectionUp:
		protoDirection = Direction_UP
	case backend.DirectionDown:
		protoDirection = Direction_DOWN
	case backend.DirectionLeft:
		protoDirection = Direction_LEFT
	case backend.DirectionRight:
		protoDirection = Direction_RIGHT
	}
	return protoDirection
}

func GetBackendCoordinate(protoCoordinate *Coordinate) backend.Coordinate {
	return backend.Coordinate{
		X: int(protoCoordinate.X),
		Y: int(protoCoordinate.Y),
	}
}

func GetProtoCoordinate(coordinate backend.Coordinate) *Coordinate {
	return &Coordinate{
		X: int32(coordinate.X),
		Y: int32(coordinate.Y),
	}
}

func GetBackendEntity(protoEntity *Entity) backend.Identifier {
	switch protoEntity.Entity.(type) {
	case *Entity_Player:
		protoPlayer := protoEntity.Entity.(*Entity_Player).Player
		return GetBackendPlayer(protoPlayer)
	case *Entity_Laser:
		protoLaser := protoEntity.Entity.(*Entity_Laser).Laser
		return GetBackendLaser(protoLaser)
	}
	log.Printf("cannot get backend entity for %T -> %+v", protoEntity, protoEntity)
	return nil
}

func GetBackendPlayer(protoPlayer *Player) *backend.Player {
	entityID, err := uuid.Parse(protoPlayer.Id)
	if err != nil {
		log.Printf("failed to convert proto UUID: %+v", err)
		return nil
	}
	icon, _ := utf8.DecodeRuneInString(protoPlayer.Icon)
	player := &backend.Player{
		IdentifierBase: backend.IdentifierBase{UUID: entityID},
		Name:           protoPlayer.Name,
		Icon:           icon,
	}
	player.Move(GetBackendCoordinate(protoPlayer.Position))
	return player
}

func GetBackendLaser(protoLaser *Laser) *backend.Laser {
	entityID, err := uuid.Parse(protoLaser.Id)
	if err != nil {
		log.Printf("failed to convert proto UUID: %+v", err)
		return nil
	}
	ownerID, err := uuid.Parse(protoLaser.OwnerId)
	if err != nil {
		log.Printf("failed to convert proto UUID: %+v", err)
		return nil
	}
	laser := &backend.Laser{
		IdentifierBase:  backend.IdentifierBase{UUID: entityID},
		InitialPosition: GetBackendCoordinate(protoLaser.InitialPosition),
		Direction:       GetBackendDirection(protoLaser.Direction),
		StartTime:       time.Unix(protoLaser.StartTime, 0),
		OwnerID:         ownerID,
	}
	return laser
}

func GetProtoEntity(entity backend.Identifier) *Entity {
	switch entity := entity.(type) {
	case *backend.Player:
		protoPlayer := Entity_Player{
			Player: GetProtoPlayer(entity),
		}
		return &Entity{Entity: &protoPlayer}
	case *backend.Laser:
		protoLaser := Entity_Laser{
			Laser: GetProtoLaser(entity),
		}
		return &Entity{Entity: &protoLaser}
	}
	log.Printf("cannot get proto entity for %T -> %+v", entity, entity)
	return nil
}

func GetProtoPlayer(player *backend.Player) *Player {
	return &Player{
		Id:       player.ID().String(),
		Name:     player.Name,
		Position: GetProtoCoordinate(player.Position()),
		Icon:     string(player.Icon),
	}
}

func GetProtoLaser(laser *backend.Laser) *Laser {
	return &Laser{
		Id:              laser.ID().String(),
		StartTime:       laser.StartTime.Unix(),
		InitialPosition: GetProtoCoordinate(laser.InitialPosition),
		Direction:       GetProtoDirection(laser.Direction),
		OwnerId:         laser.OwnerID.String(),
	}
}
