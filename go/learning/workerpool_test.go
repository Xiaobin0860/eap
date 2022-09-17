package learning

import (
	"fmt"
	"math/rand"
	"testing"
	"time"

	"github.com/Xiaobin0860/workerpool"
)

func TestWorkerPool(t *testing.T) {
	rand.Seed(time.Now().UnixNano())
	p := workerpool.New(5)
	for i := 0; i < 10; i++ {
		t := func(x int) func() {
			return func() {
				fmt.Printf("  task[%02d] started\n", x)
				time.Sleep(time.Millisecond * time.Duration(rand.Intn(500)+100))
				fmt.Printf("  task[%02d] ended\n", x)
			}
		}
		p.Schedule(t(i))
	}
	p.Free()
}
