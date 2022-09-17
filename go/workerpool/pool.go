package workerpool

import (
	"errors"
	"fmt"
	"runtime"
	"sync"
)

var ErrWorkerPoolFreed = errors.New("workerpool freed")
var ErrNoIdleWorker = errors.New("no idle worker")

func New(capacity int, opts ...Option) *Pool {
	p := &Pool{
		capacity: capacity,
		active:   make(chan struct{}, capacity),
		tasks:    make(chan Task),
		quit:     make(chan struct{}),
	}
	for _, opt := range opts {
		opt(p)
	}
	go p.run()
	for {
		if len(p.active) == p.capacity {
			break
		}
		runtime.Gosched()
	}
	return p
}

func WithBlock(block bool) func(*Pool) {
	return func(p *Pool) {
		p.block = block
	}
}

type Pool struct {
	capacity int
	block    bool

	active chan struct{}
	tasks  chan Task

	wg   sync.WaitGroup
	quit chan struct{}
}

func (p *Pool) Schedule(task Task) error {
	select {
	case <-p.quit:
		return ErrWorkerPoolFreed
	case p.tasks <- task:
		return nil
	default:
		if p.block {
			p.tasks <- task
			return nil
		}
		return ErrNoIdleWorker
	}
}

func (p *Pool) Free() {
	close(p.quit)
	p.wg.Wait()
	fmt.Printf("pool freed, block=%v\n", p.block)
}

type Task func()

type Option func(*Pool)

func (p *Pool) run() {
	idx := 0
	for {
		idx++
		select {
		case <-p.quit:
			return
		case p.active <- struct{}{}:
			p.newWorker(idx)
		}
	}
}

func (p *Pool) newWorker(idx int) {
	p.wg.Add(1)
	go func() {
		defer func() {
			if e := recover(); e != nil {
				fmt.Printf("worker[%03d] recover panic[%s]\n", idx, e)
				// panic退出需要创建新的worker
				<-p.active
			}
			fmt.Printf("worker[%03d] exited\n", idx)
			p.wg.Done()
		}()
		fmt.Printf("worker[%03d] started\n", idx)
		for {
			select {
			case <-p.quit:
				fmt.Printf("worker[%03d] quit\n", idx)
				return
			case t := <-p.tasks:
				t()
			}
		}
	}()
}
