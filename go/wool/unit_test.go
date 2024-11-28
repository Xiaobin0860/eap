package main

import (
	"testing"
	"time"

	"github.com/fsnotify/fsnotify"
	lua "github.com/yuin/gopher-lua"
)

func Test_Encode(t *testing.T) {
	input := []byte{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20}
	output := EncodePacket(input)
	input = DecodePacket(output)
	t.Log(input)
}

func Test_Pack(t *testing.T) {
	message := &Message{
		Recog: 354580869,
		Ident: 1011,
	}

	message.setText("@exit")
	data := packMessage(message)
	t.Log(data)
}

func Test_Unpack(t *testing.T) {
	data := []byte{133, 121, 34, 21, 242, 3, 0, 0, 0, 0, 0, 0, 64, 101, 120, 105, 116}
	message := unpackMessage(data)
	t.Log(message)
}

func Test_Watch(t *testing.T) {
	watcher, _ := fsnotify.NewWatcher()
	watcher.Add("robot.lua")
	defer watcher.Close()

	for event := range watcher.Events {
		t.Log(event)
	}
}

func Test_Resume(t *testing.T) {
	L := lua.NewState()
	L.DoString(`
		function Test_Resume()
			print("start")
			Sleep(300)
			print("finish")
		end
	`)

	L.SetGlobal("Sleep", L.NewFunction(func(L *lua.LState) int {
		number := L.Get(1)
		ms := time.Duration(number.(lua.LNumber))
		co := L.G.CurrentThread
		go func() {
			time.Sleep(ms * time.Millisecond)
			state, err, _ := L.Resume(co, nil)
			if state == lua.ResumeError {
				t.Log("lua call after Sleep fail, err:", err)
				return
			}
		}()

		return L.Yield()
	}))

	co, _ := L.NewThread()
	fn := L.GetGlobal("Test_Resume").(*lua.LFunction)
	state, err, _ := L.Resume(co, fn)
	t.Log("Test_Resume", state, err)

	time.Sleep(3 * time.Second)
}
