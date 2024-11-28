package main

import (
	"bytes"
	"encoding/binary"
	"log"
	"net"
)

type ProxySocket struct {
	Closed  bool
	MsgFlag byte
	Script  string
	Sending bytes.Buffer
	Recving bytes.Buffer

	Local  net.Conn
	Remote net.Conn
	Robot  *ProxyRobot
}

func (socket *ProxySocket) Run() {
	socket.Robot = &ProxyRobot{
		Socket: socket,
		Script: socket.Script,
	}

	socket.Robot.Run()
	go socket.handleRemote()

	socket.MsgFlag = '3'
	socket.handleLocal()
}

func (socket *ProxySocket) handleLocal() {
	buffer := make([]byte, 8192)
	for !socket.Closed {
		n, err := socket.Local.Read(buffer)
		if err != nil || n <= 0 {
			socket.Closed = true
			return
		}

		socket.onSendBuffer(buffer[:n])
	}
}

func (socket *ProxySocket) handleRemote() {
	buffer := make([]byte, 8192)
	for !socket.Closed {
		n, err := socket.Remote.Read(buffer)
		if err != nil || n <= 0 {
			socket.Closed = true
			return
		}

		socket.onRecvBuffer(buffer[:n])
	}
}

func (socket *ProxySocket) onSendBuffer(buffer []byte) {
	for i := 0; i < len(buffer); i++ {
		if buffer[i] == '#' {
			socket.Sending.Reset()
		}
		socket.Sending.WriteByte(buffer[i])
		if buffer[i] == '!' {
			bytes := socket.Sending.Bytes()
			data := DecodePacket(bytes[2 : len(bytes)-1])
			message := unpackMessage(data)
			socket.Sending.Reset()

			if !socket.Robot.isSkipMessage(message) {
				socket.SendMessage(message)
			}

			socket.Robot.onSendMessage(message)
		}
	}
}

func (socket *ProxySocket) onRecvBuffer(buffer []byte) {
	for i := 0; i < len(buffer); i++ {
		if buffer[i] == '#' {
			socket.Recving.Reset()
		}
		socket.Recving.WriteByte(buffer[i])
		if buffer[i] == '!' {
			bytes := socket.Recving.Bytes()
			data := DecodePacket(bytes[1 : len(bytes)-1])
			message := unpackMessage(data)
			socket.Recving.Reset()

			if !socket.Robot.isSkipMessage(message) {
				socket.RecvPackage(bytes)
			}

			socket.Robot.onRecvMessage(message)
		}
	}
}

func (socket *ProxySocket) NextMsgFlag() byte {
	socket.MsgFlag += 1
	if socket.MsgFlag > '9' {
		socket.MsgFlag = '1'
	}
	return socket.MsgFlag
}

func (socket *ProxySocket) SendPackage(bytes []byte) {
	// log.Println("send bytes:", bytes)
	n, err := socket.Remote.Write(bytes)
	if err != nil || n != len(bytes) {
		log.Println("socket SendPackage fail, err:", err)
		return
	}
}

func (socket *ProxySocket) RecvPackage(bytes []byte) {
	// log.Println("send bytes:", bytes)
	n, err := socket.Local.Write(bytes)
	if err != nil || n != len(bytes) {
		log.Println("socket RecvPackage fail, err:", err)
		return
	}
}

func (socket *ProxySocket) SendMessage(message *Message) {
	// log.Println("send message:", message)
	data := EncodePacket(packMessage(message))

	var buffer bytes.Buffer
	buffer.WriteByte('#')
	buffer.WriteByte(socket.NextMsgFlag())
	binary.Write(&buffer, binary.LittleEndian, data)
	buffer.WriteByte('!')
	socket.SendPackage(buffer.Bytes())
}

func (socket *ProxySocket) RecvMessage(message *Message) {
	// log.Println("recv message:", message)
	data := EncodePacket(packMessage(message))

	var buffer bytes.Buffer
	buffer.WriteByte('#')
	binary.Write(&buffer, binary.LittleEndian, data)
	buffer.WriteByte('!')
	socket.RecvPackage(buffer.Bytes())
}
