package leetcode

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func isFlipedString(s1 string, s2 string) bool {
	if len(s1) != len(s2) {
		return false
	}
	s := s1 + s1
	return strings.Contains(s, s2)
}

func TestStrFlip(t *testing.T) {
	assert.True(t, isFlipedString("waterbottle", "erbottlewat"))
	assert.True(t, isFlipedString("waterbottle", "waterbottle"))
	assert.False(t, isFlipedString("aa", "aba"))
	assert.False(t, isFlipedString("aa", "ba"))
	assert.False(t, isFlipedString("aa", "ab"))
	assert.True(t, isFlipedString("aba", "aab"))
}
