package leetcode

import (
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
)

var ErrIndexOutOfRange = errors.New("index out of range")

type node struct {
	val  int
	prev *node
	next *node
}

type MyLinkedList struct {
	count int
	head  *node
	tail  *node
}

func Constructor() MyLinkedList {
	return MyLinkedList{}
}

func (ths *MyLinkedList) Get(index int) (int, error) {
	node := ths.getNode(index)
	if node == nil {
		return -1, ErrIndexOutOfRange
	} else {
		return node.val, nil
	}
}

func (ths *MyLinkedList) AddAtHead(val int) {
	head := ths.head
	node := &node{val: val, next: head}
	ths.head = node
	if ths.tail == nil {
		ths.tail = node
	}
	if head != nil {
		head.prev = node
	}
	ths.count += 1
}

func (ths *MyLinkedList) AddAtTail(val int) {
	tail := ths.tail
	if tail == nil {
		ths.AddAtHead(val)
	} else {
		node := &node{val: val, prev: tail}
		ths.tail = node
		tail.next = node
		ths.count += 1
	}
}

// [0, ...]
func (ths *MyLinkedList) getNode(index int) *node {
	if index < 0 {
		return nil
	}
	node := ths.head
	for i := 0; i < index; i++ {
		if nil == node {
			break
		}
		node = node.next
	}
	return node
}

// 在链表中的第 index 个节点之前添加值为 val  的节点。如果 index 等于链表的长度，则该节点将附加到链表的末尾
func (ths *MyLinkedList) AddAtIndex(index int, val int) {
	if index <= 0 {
		ths.AddAtHead(val)
		return
	} else if index == ths.count {
		ths.AddAtTail(val)
		return
	} else if index > ths.count {
		return
	}
	before := ths.getNode(index)
	node := &node{val: val, prev: before.prev, next: before}
	before.prev.next = node
	before.prev = node
	ths.count += 1
}

func (ths *MyLinkedList) DeleteAtIndex(index int) {
	node := ths.getNode(index)
	if node == nil {
		return
	}
	if ths.tail == node {
		ths.tail = node.prev
	}
	if ths.head == node {
		ths.head = node.next
	}
	if node.next != nil {
		node.next.prev = node.prev
	}
	if node.prev != nil {
		node.prev.next = node.next
	}
	ths.count -= 1
}

func TestMyLinkedList(t *testing.T) {
	l := Constructor() //[]
	v, e := l.Get(0)
	if assert.Error(t, e) {
		assert.Equal(t, ErrIndexOutOfRange, e)
	}
	assert.Equal(t, -1, v)
	l.AddAtHead(1)     //[1]
	l.AddAtTail(3)     //[1,3]
	l.AddAtIndex(1, 2) //[1,2,3]
	v, e = l.Get(-1)
	if assert.Error(t, e) {
		assert.Equal(t, ErrIndexOutOfRange, e)
	}
	assert.Equal(t, -1, v)
	v, e = l.Get(0)
	assert.Nil(t, e)
	assert.Equal(t, 1, v)
	v, e = l.Get(1)
	assert.Nil(t, e)
	assert.Equal(t, 2, v)
	v, e = l.Get(2)
	assert.Nil(t, e)
	assert.Equal(t, 3, v)
	v, e = l.Get(3)
	if assert.Error(t, e) {
		assert.Equal(t, ErrIndexOutOfRange, e)
	}
	assert.Equal(t, -1, v)
	l.DeleteAtIndex(1) //[1,3]
	v, e = l.Get(1)
	assert.Nil(t, e)
	assert.Equal(t, 3, v)
	v, e = l.Get(2)
	if assert.Error(t, e) {
		assert.Equal(t, ErrIndexOutOfRange, e)
	}
	assert.Equal(t, -1, v)
	l.DeleteAtIndex(0) //[3]
	v, e = l.Get(0)
	assert.Nil(t, e)
	assert.Equal(t, 3, v)
	l.DeleteAtIndex(0) //[]
	v, e = l.Get(0)
	if assert.Error(t, e) {
		assert.Equal(t, ErrIndexOutOfRange, e)
	}
	assert.Equal(t, -1, v)
	l.AddAtTail(3) //[3]
	v, e = l.Get(0)
	assert.Nil(t, e)
	assert.Equal(t, 3, v)
	l.AddAtIndex(1, 4) //[3,4]
	v, e = l.Get(0)
	assert.Nil(t, e)
	assert.Equal(t, 3, v)
	v, e = l.Get(1)
	assert.Nil(t, e)
	assert.Equal(t, 4, v)
}

func TestMyLinkedList2(t *testing.T) {
	l := Constructor() //[]
	l.AddAtIndex(0, 10)
	l.AddAtIndex(0, 20)
	l.AddAtIndex(0, 30)
	v, e := l.Get(0)
	assert.Nil(t, e)
	assert.Equal(t, 30, v)
	v, e = l.Get(1)
	assert.Nil(t, e)
	assert.Equal(t, 20, v)
	v, e = l.Get(2)
	assert.Nil(t, e)
	assert.Equal(t, 10, v)
}
