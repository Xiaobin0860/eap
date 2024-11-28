package main

import (
	"encoding/binary"
	"fmt"
	"log"
	"net"
)

type ProxyServer struct {
	Port   int
	Script string
}

func (server *ProxyServer) Run() {
	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", server.Port))
	if err != nil {
		log.Println("Listen server fail, err:", err)
		return
	}

	log.Println("Listen server at port:", server.Port)
	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Println("Server accept fail, err:", err)
			continue
		}

		log.Println("Server accept conn, address:", conn.RemoteAddr())
		go server.handleSocks5(conn)
	}
}

func (server *ProxyServer) parseAddress(buff []byte) (string, error) {
	if buff[3] == 0x01 {
		host := fmt.Sprintf("%d.%d.%d.%d", buff[4], buff[5], buff[6], buff[7])
		port := binary.BigEndian.Uint16(buff[8:10])
		return fmt.Sprintf("%s:%d", host, port), nil
	}

	if buff[3] == 0x03 {
		length := buff[4]
		host := string(buff[5 : 5+length])
		port := binary.BigEndian.Uint16(buff[5+length : 7+length])
		return fmt.Sprintf("%s:%d", host, port), nil
	}

	return "", fmt.Errorf("invalid ATYP:%d", buff[3])
}

// https://www.ddhigh.com/2019/08/24/socks5-protocol.html
func (server *ProxyServer) handleSocks5(conn net.Conn) {
	defer conn.Close()

	rbuf := make([]byte, 256)
	n, err := conn.Read(rbuf)
	if err != nil || n != 3 {
		log.Println("socks5 first recv fail")
		return
	}

	if rbuf[0] != 0x05 || rbuf[1] != 0x01 || rbuf[2] != 0x00 {
		log.Println("socks5 first check fail")
		return
	}

	wbuf := []byte{0x05, 0x00}
	conn.Write(wbuf)

	n, err = conn.Read(rbuf)
	if err != nil || n < 4 {
		log.Println("socks5 second recv fail")
		return
	}

	if rbuf[0] != 0x05 || rbuf[1] != 0x01 || rbuf[2] != 0x00 {
		log.Println("socks5 second check fail")
		return
	}

	address, err := server.parseAddress(rbuf)
	if err != nil {
		log.Println("socks5 parse address fail")
		return
	}

	remote, err := net.Dial("tcp", address)
	if err != nil {
		log.Println("socks5 connect address fail, err:", err)
		wbuf = []byte{0x05, 0x04, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
		conn.Write(wbuf)
		return
	}
	defer remote.Close()

	log.Println("socks5 conncet address:", address)
	wbuf = []byte{0x05, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	conn.Write(wbuf)

	socket := &ProxySocket{
		Local:  conn,
		Remote: remote,
		Script: server.Script,
	}
	socket.Run()
}
