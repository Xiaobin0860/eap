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

func TestCheckOnesSegment(t *testing.T) {
	assert.False(t, checkOnesSegment("1001"))
	assert.True(t, checkOnesSegment("110"))
	assert.True(t, checkOnesSegment("1"))
	assert.True(t, checkOnesSegment("11"))
	assert.True(t, checkOnesSegment("10"))
	assert.False(t, checkOnesSegment("101"))
	assert.False(t, checkOnesSegment("10101"))
}
