package leetcode

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func canFormArray(arr []int, pieces [][]int) bool {
	var idx_map = make(map[int]int)
	for i, piece := range pieces {
		idx_map[piece[0]] = i
	}
	for i := 0; i < len(arr); {
		if idx, ok := idx_map[arr[i]]; ok {
			piece := pieces[idx]
			i++
			for j := 1; j < len(piece); j++ {
				if i >= len(arr) || arr[i] != piece[j] {
					return false
				}
				i++
			}
		} else {
			return false
		}
	}
	return true
}

func TestPiecesToArray(t *testing.T) {
	{
		arr := []int{15, 88}
		pieces := [][]int{{88}, {15}}
		assert.True(t, canFormArray(arr, pieces))
	}
	{
		arr := []int{49, 18, 16}
		pieces := [][]int{{16, 18, 49}}
		assert.False(t, canFormArray(arr, pieces))
	}
	{
		arr := []int{91, 4, 64, 78}
		pieces := [][]int{{78}, {4, 64}, {91}}
		assert.True(t, canFormArray(arr, pieces))
	}
}
