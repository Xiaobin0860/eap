package workerpool

import (
	"fmt"
	"runtime"
	"sync"
)

func New(capacity int) *Pool {
	p := &Pool{
		capacity: capacity,
		active:   make(chan struct{}, capacity),
		tasks:    make(chan Task),
		quit:     make(chan struct{}),
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

type Pool struct {
	capacity int

	active chan struct{}
	tasks  chan Task

	wg   sync.WaitGroup
	quit chan struct{}
}

func (p *Pool) Schedule(task Task) {
	p.tasks <- task
}

func (p *Pool) Free() {
	close(p.quit)
	p.wg.Wait()
}

type Task func()

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
