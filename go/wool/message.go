package main

import (
	"bytes"
	"encoding/binary"
	"io/ioutil"

	"golang.org/x/text/encoding/simplifiedchinese"
	"golang.org/x/text/transform"
)

type Message struct {
	Recog  uint32
	Ident  uint16
	Param  uint16
	Tag    uint16
	Series uint16
	Data   []byte
}

func (message *Message) getText() string {
	r := bytes.NewReader(message.Data)
	decoder := transform.NewReader(r, simplifiedchinese.GBK.NewDecoder())
	content, _ := ioutil.ReadAll(decoder)
	return string(content)
}

func (message *Message) setText(content string) {
	reader := bytes.NewReader([]byte(content))
	tfr := transform.NewReader(reader, simplifiedchinese.GBK.NewDecoder())
	message.Data, _ = ioutil.ReadAll(tfr)
}

func packMessage(message *Message) []byte {
	var buffer bytes.Buffer
	binary.Write(&buffer, binary.LittleEndian, message.Recog)
	binary.Write(&buffer, binary.LittleEndian, message.Ident)
	binary.Write(&buffer, binary.LittleEndian, message.Param)
	binary.Write(&buffer, binary.LittleEndian, message.Tag)
	binary.Write(&buffer, binary.LittleEndian, message.Series)

	if message.Data != nil {
		binary.Write(&buffer, binary.LittleEndian, message.Data)
	}

	return buffer.Bytes()
}

func unpackMessage(data []byte) *Message {
	for i := len(data); i < 12; i++ {
		data = append(data, 0)
	}

	message := &Message{}
	message.Recog = binary.LittleEndian.Uint32(data[0:4])
	message.Ident = binary.LittleEndian.Uint16(data[4:6])
	message.Param = binary.LittleEndian.Uint16(data[6:8])
	message.Tag = binary.LittleEndian.Uint16(data[8:10])
	message.Series = binary.LittleEndian.Uint16(data[10:12])

	if len(data) > 12 {
		message.Data = data[12:]
	}

	return message
}
