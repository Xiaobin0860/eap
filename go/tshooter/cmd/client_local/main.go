package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	termutil "github.com/andrew-d/go-termutil"
	"github.com/google/uuid"

	"tshooter/pkg/backend"
	"tshooter/pkg/bot"
	"tshooter/pkg/frontend"
)

func main() {
	if !termutil.Isatty(os.Stdin.Fd()) {
		panic("this program must be run in a terminal")
	}

	numBots := flag.Int("bots", 1, "The number of bots to play against.")
	flag.Parse()

	currentPlayer := backend.Player{
		IdentifierBase:  backend.IdentifierBase{UUID: uuid.New()},
		Positioner:      nil,
		Mover:           nil,
		CurrentPosition: backend.Coordinate{X: -1, Y: -5},
		Name:            "Alice",
		Icon:            'A',
	}
	game := backend.NewGame()
	game.AddEntity(&currentPlayer)

	view := frontend.NewView(game)
	view.CurrentPlayer = currentPlayer.ID()

	bots := bot.NewBots(game)
	for i := 0; i < *numBots; i++ {
		bots.AddBot(fmt.Sprintf("Bot %d", i))
	}

	game.Start()
	view.Start()
	bots.Start()

	err := <-view.Done
	if err != nil {
		log.Fatal(err)
	}

}
