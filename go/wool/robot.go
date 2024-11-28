package main

import (
	"log"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
	lua "github.com/yuin/gopher-lua"
)

type ProxyRobot struct {
	Socket *ProxySocket
	LState *lua.LState
	Mutex  sync.Mutex
	Script string
}

func (robot *ProxyRobot) Run() {
	robot.LState = lua.NewState()
	robot.registerFuncs()
	robot.loadLuaScript()
}

func (robot *ProxyRobot) isSkipMessage(message *Message) bool {
	robot.Mutex.Lock()
	defer robot.Mutex.Unlock()

	L := robot.LState
	table := robot.messageToTable(message)

	LP := lua.P{Fn: L.GetGlobal("isSkipMessage"), Protect: true, NRet: 1}
	err := L.CallByParam(LP, table)
	if err != nil {
		log.Println("lua call isSkipMessage fail, err:", err)
		return false
	}

	ret := L.Get(-1)
	L.Pop(1)

	return ret == lua.LTrue
}

func (robot *ProxyRobot) onSendMessage(message *Message) {
	robot.Mutex.Lock()
	defer robot.Mutex.Unlock()

	L := robot.LState
	table := robot.messageToTable(message)

	LP := lua.P{Fn: L.GetGlobal("onSendMessage"), Protect: true}
	err := L.CallByParam(LP, table)
	if err != nil {
		log.Println("onSendMessage err:", err)
	}
}

func (robot *ProxyRobot) onRecvMessage(message *Message) {
	robot.Mutex.Lock()
	defer robot.Mutex.Unlock()

	L := robot.LState
	table := robot.messageToTable(message)

	LP := lua.P{Fn: L.GetGlobal("onRecvMessage"), Protect: true}
	err := L.CallByParam(LP, table)
	if err != nil {
		log.Println("onRecvMessage err:", err)
	}
}

func (robot *ProxyRobot) registerFuncs() {
	L := robot.LState
	L.SetGlobal("SendMessage", L.NewFunction(func(L *lua.LState) int {
		table := L.Get(1)
		if table.Type() == lua.LTTable {
			message := robot.tableToMessage(table)
			robot.Socket.SendMessage(message)
		}
		return 0
	}))

	L.SetGlobal("RecvMessage", L.NewFunction(func(L *lua.LState) int {
		table := L.Get(1)
		if table.Type() == lua.LTTable {
			message := robot.tableToMessage(table)
			robot.Socket.RecvMessage(message)
		}
		return 0
	}))
}

func (robot *ProxyRobot) loadLuaScript() {
	log.Println("load script:", robot.Script)
	L := robot.LState
	err := L.DoFile(robot.Script)
	if err != nil {
		log.Println("lua do file fail, err:", err)
	}

	go func() {
		for !robot.Socket.Closed {
			time.Sleep(100 * time.Millisecond)
			robot.Mutex.Lock()
			LP := lua.P{Fn: L.GetGlobal("onUpdate"), Protect: true}
			err := L.CallByParam(LP)
			robot.Mutex.Unlock()
			if err != nil {
				log.Println("onUpdate err:", err)
			}
		}
	}()

	go func() {
		watcher, _ := fsnotify.NewWatcher()
		watcher.Add(robot.Script)
		defer watcher.Close()

		for event := range watcher.Events {
			log.Println(event)
			robot.Mutex.Lock()
			err := L.DoFile(robot.Script)
			robot.Mutex.Unlock()
			if err != nil {
				log.Println("lua do file fail, err:", err)
				continue
			}
		}
	}()
}

func (robot *ProxyRobot) messageToTable(message *Message) lua.LValue {
	L := robot.LState
	table := L.NewTable()
	L.SetField(table, "Recog", lua.LNumber(message.Recog))
	L.SetField(table, "Ident", lua.LNumber(message.Ident))
	L.SetField(table, "Param", lua.LNumber(message.Param))
	L.SetField(table, "Tag", lua.LNumber(message.Tag))
	L.SetField(table, "Series", lua.LNumber(message.Series))
	L.SetField(table, "Data", lua.LString(message.Data))
	L.SetField(table, "Text", lua.LString(message.getText()))
	return table
}

func (robot *ProxyRobot) tableToMessage(table lua.LValue) *Message {
	L := robot.LState
	recog := L.GetField(table, "Recog")
	ident := L.GetField(table, "Ident")
	param := L.GetField(table, "Param")
	tag := L.GetField(table, "Tag")
	series := L.GetField(table, "Series")
	data := L.GetField(table, "Data")
	text := L.GetField(table, "Text")

	message := &Message{}
	if recog.Type() == lua.LTNumber {
		message.Recog = uint32(recog.(lua.LNumber))
	}
	if ident.Type() == lua.LTNumber {
		message.Ident = uint16(ident.(lua.LNumber))
	}
	if param.Type() == lua.LTNumber {
		message.Param = uint16(param.(lua.LNumber))
	}
	if tag.Type() == lua.LTNumber {
		message.Tag = uint16(tag.(lua.LNumber))
	}
	if series.Type() == lua.LTNumber {
		message.Series = uint16(series.(lua.LNumber))
	}
	if data.Type() == lua.LTString {
		message.Data = []byte((data.(lua.LString)))
	}
	if text.Type() == lua.LTString {
		message.setText(string(text.(lua.LString)))
	}

	return message
}
