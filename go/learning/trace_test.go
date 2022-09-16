package learning

import (
	"sync"
	"testing"

	"github.com/Xiaobin0860/trace"
)

func a() {
	defer trace.Trace()()
}

func b() {
	defer trace.Trace()()
	c()
}

func c() {
	defer trace.Trace()()
	a()
}

func e() {
	defer trace.Trace()()
	println("eeeeeeeee")
}

func TestTrace(t *testing.T) {

	var wg sync.WaitGroup
	wg.Add(2)
	go func() {
		c()
		a()
		wg.Done()
	}()
	go func() {
		b()
		wg.Done()
	}()

	b()
	e()

	wg.Wait()
}
