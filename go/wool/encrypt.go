package main

func EncodePacket(inbuf []byte) []byte {
	var b1, b4 byte
	var bindex, outpos int
	outbuf := make([]byte, len(inbuf)*2)
	for i := 0; i < len(inbuf); i++ {
		b1 = inbuf[i] ^ 0xeb
		if bindex == 2 {
			outbuf[outpos] = (b1 & 0x3f) + 0x3b
			outpos++
			b4 |= ((b1 >> 2) & 0x30)
			outbuf[outpos] = b4 + 0x3b
			outpos++
			bindex = 0
			b4 = 0
		} else {
			outbuf[outpos] = ((b1&0xF0)>>2 | (b1 & 3)) + 0x3b
			outpos++
			b4 <<= 2
			b4 |= (b1 >> 2) & 3
			bindex++
		}
	}
	if bindex != 0 {
		outbuf[outpos] = b4 + 0x3b
		outpos++
	}
	outbuf[outpos] = 0
	return outbuf[:outpos]
}

func DecodePacket(inbuf []byte) []byte {
	var b1, b2, b3, b4 byte
	var outpos int
	outbuf := make([]byte, len(inbuf))

	kk := len(inbuf) / 4
	ll := len(inbuf) % 4
	for i := 0; i < kk; i++ {
		index := i << 2
		b1 = inbuf[index] - 0x3b
		b2 = inbuf[index+1] - 0x3b
		b3 = inbuf[index+2] - 0x3b
		b4 = inbuf[index+3] - 0x3b

		outbuf[outpos] = (((b1 << 2) & 0xF0) | (b1 & 0x03) | (b4 & 0x0C)) ^ 0xeb
		outpos++

		outbuf[outpos] = (((b2 << 2) & 0xF0) | (b2 & 0x03) | ((b4 << 2) & 0x0C)) ^ 0xeb
		outpos++

		outbuf[outpos] = (b3 | ((b4 << 2) & 0xC0)) ^ 0xeb
		outpos++
	}

	index := kk * 4
	if ll == 2 {
		b1 = inbuf[index] - 0x3b
		b4 = inbuf[index+1] - 0x3b

		outbuf[outpos] = (((b1 << 2) & 0xF0) | (b1 & 0x03) | ((b4 << 2) & 0x0C)) ^ 0xeb
		outpos++
	} else if ll == 3 {
		b1 = inbuf[index] - 0x3b
		b2 = inbuf[index+1] - 0x3b
		b4 = inbuf[index+2] - 0x3b

		outbuf[outpos] = (((b1 << 2) & 0xF0) | (b1 & 0x03) | (b4 & 0x0C)) ^ 0xeb
		outpos++

		outbuf[outpos] = (((b2 << 2) & 0xF0) | (b2 & 0x03) | ((b4 << 2) & 0x0C)) ^ 0xeb
		outpos++
	}
	outbuf[outpos] = 0
	return outbuf[:outpos]
}
