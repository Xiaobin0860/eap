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
	{
		p := workerpool.New(5, workerpool.WithBlock(true))
		for i := 0; i < 20; i++ {
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
	println("------ no block ------")
	{
		p := workerpool.New(5)
		for i := 20; i < 40; i++ {
			t := func(x int) func() {
				return func() {
					fmt.Printf("  task[%02d] started\n", x)
					time.Sleep(time.Millisecond * time.Duration(rand.Intn(500)+100))
					fmt.Printf("  task[%02d] ended\n", x)
				}
			}
			if e := p.Schedule(t(i)); e != nil {
				fmt.Printf("task[%02d] schedule error[%s]\n", i, e)
			}
		}
		p.Free()
	}
}
