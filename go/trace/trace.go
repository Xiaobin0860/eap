package trace

import (
	"bytes"
	"fmt"
	"runtime"
	"strconv"
	"sync"
)

var mu sync.Mutex
var m = make(map[uint64]int)

var goroutineSpace = []byte("goroutine ")

func curGoroutineID() uint64 {
	b := make([]byte, 64)
	b = b[:runtime.Stack(b, false)]
	// Parse the 4707 out of "goroutine 4707 ["
	b = bytes.TrimPrefix(b, goroutineSpace)
	i := bytes.IndexByte(b, ' ')
	if i < 0 {
		panic(fmt.Sprintf("No space found in %q", b))
	}
	b = b[:i]
	n, err := strconv.ParseUint(string(b), 10, 64)
	if err != nil {
		panic(fmt.Sprintf("Failed to parse goroutine ID out of %q: %v", b, err))
	}
	return n
}

func printTracingInfo(gid uint64, name string, arrow string, indent int) {
	indents := ""
	for i := 0; i < indent; i++ {
		indents += "    "
	}
	fmt.Printf("g[%05d]:%s%s%s\n", gid, indents, arrow, name)
}

func Trace() func() {
	pc, _, _, ok := runtime.Caller(1)

	if !ok {
		panic("no caller")
	}

	f := runtime.FuncForPC(pc)

	if f == nil {
		panic("no func")
	}
	name := f.Name()

	gid := curGoroutineID()
	mu.Lock()
	indent := m[gid]
	m[gid] = indent + 1
	mu.Unlock()

	printTracingInfo(gid, name, "->", indent)

	return func() {
		gid := curGoroutineID()
		mu.Lock()
		indent := m[gid] - 1
		m[gid] = indent
		mu.Unlock()
		printTracingInfo(gid, name, "<-", indent)
	}
}
