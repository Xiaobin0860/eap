package learning

import "testing"

type MyInt int
type Int = int

func TestType(t *testing.T) {
	var a MyInt
	var b Int
	var c = 1
	a = MyInt(c)
	b = c
	t.Log(a, b, c)
}
