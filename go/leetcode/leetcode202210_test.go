package leetcode

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func checkOnesSegment(s string) bool {
	if zidx := strings.Index(s, "0"); zidx == -1 {
		return true
	} else {
		return !strings.Contains(s[zidx:], "1")
	}
}

func minAddToMakeValid(s string) int {
	left := 0
	right := 0
	for _, c := range s {
		switch c {
		case '(':
			left += 1
		case ')':
			if left > 0 {
				left -= 1
			} else {
				right += 1
			}
		default:
			panic("invalid")
		}
	}
	return left + right
}

func TestCheckOnesSegment(t *testing.T) {
	assert.False(t, checkOnesSegment("1001"))
	assert.True(t, checkOnesSegment("110"))
	assert.True(t, checkOnesSegment("1"))
	assert.True(t, checkOnesSegment("11"))
	assert.True(t, checkOnesSegment("10"))
	assert.False(t, checkOnesSegment("101"))
	assert.False(t, checkOnesSegment("10101"))
}

func TestMinAddToMakeValid(t *testing.T) {
	assert.Equal(t, 1, minAddToMakeValid("())"))
	assert.Equal(t, 2, minAddToMakeValid("()()))"))
	assert.Equal(t, 3, minAddToMakeValid("((("))
	assert.Equal(t, 0, minAddToMakeValid("()(())"))
	assert.Equal(t, 0, minAddToMakeValid(""))
	assert.Equal(t, 3, minAddToMakeValid(")()))"))
}
