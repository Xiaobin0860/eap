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

func arraySign(nums []int) int {
	sign := 1
	for i := 0; i < len(nums); i++ {
		n := nums[i]
		if n == 0 {
			return 0
		} else if n < 0 {
			sign *= -1
		}
	}
	return sign
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

func TestArraySign(t *testing.T) {
	assert.Equal(t, 1, arraySign([]int{-1, -2, -3, -4, 3, 2, 1}))
	assert.Equal(t, 0, arraySign([]int{1, 5, 0, 2, -3}))
	assert.Equal(t, -1, arraySign([]int{-1, 1, -1, 1, -1}))
}
