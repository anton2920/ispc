package main

import (
	"slices"
	"strconv"
	"testing"
)

const (
	TestN  = 1024
	BenchN = TestN
)

func PowerOfTwo(n int) bool {
	return (n & (n - 1)) == 0
}

func TestLinearSearch(t *testing.T) {
	array, needles := GetTestData(TestN)
	for i := 0; i < len(array); i++ {
		needle := needles[i]

		expected := int32(slices.Index(array, needle))
		actual := LinearSearch(array, needle)

		if expected != actual {
			t.Errorf("expected to find element %d at position %d, but found at position %d", needle, expected, actual)
		}
	}
}

func TestBinarySearch(t *testing.T) {
	array, needles := GetTestData(TestN)
	for i := 0; i < len(array); i++ {
		needle := needles[i]

		expected := int32(slices.Index(array, needle))
		actual := BinarySearch(array, needle)

		if expected != actual {
			t.Errorf("expected to find element %d at position %d, but found at position %d", needle, expected, actual)
		}
	}
}

func TestBSearch(t *testing.T) {
	array, needles := GetTestData(TestN)
	for i := 0; i < len(array); i++ {
		needle := needles[i]

		expected := int32(slices.Index(array, needle))
		actual := BSearch(array, needle)

		if expected != actual {
			t.Errorf("expected to find element %d at position %d, but found at position %d", needle, expected, actual)
		}
	}
}

func TestBSearchProper(t *testing.T) {
	array, needles := GetTestData(TestN)
	for i := 0; i < len(array); i++ {
		needle := needles[i]

		expected := int32(slices.Index(array, needle))
		actual := BSearchProper(array, needle)

		if expected != actual {
			t.Errorf("expected to find element %d at position %d, but found at position %d", needle, expected, actual)
		}
	}
}

/*
func BenchmarkLinearSearch(b *testing.B) {
	array, needles := GetTestData(BenchN)
	if !PowerOfTwo(len(needles)) {
		b.Fatalf("expected array of length that is power of two, got %d", len(needles))
	}

	var i int
	for b.Loop() {
		_ = LinearSearch(array, needles[i&(len(needles)-1)])
		i++
	}
}
*/

// var steps = []int{1 << 5, 1 << 10, 1 << 13, 1 << 18, 1 << 21, 1 << 23, 1 << 25, 1 << 26, 1 << 27, 1 << 28, 1 << 29}
var steps = []int{1 << 5, 1 << 10, 1 << 13, 1 << 18, 1 << 21}

func BenchmarkBinarySearch(b *testing.B) {
	for i := 0; i < len(steps); i++ {
		array, needles := GetTestData(steps[i])
		if !PowerOfTwo(len(needles)) {
			b.Fatalf("expected array of length that is power of two, got %d", len(needles))
		}
		b.Run(strconv.Itoa(steps[i]), func(b *testing.B) {
			var i int
			for b.Loop() {
				_ = BinarySearch(array, needles[i&(len(needles)-1)])
				i++
			}
		})
	}
}

func BenchmarkBSearch(b *testing.B) {
	for i := 0; i < len(steps); i++ {
		array, needles := GetTestData(steps[i])
		if !PowerOfTwo(len(needles)) {
			b.Fatalf("expected array of length that is power of two, got %d", len(needles))
		}
		b.Run(strconv.Itoa(steps[i]), func(b *testing.B) {
			var i int
			for b.Loop() {
				_ = BSearch(array, needles[i&(len(needles)-1)])
				i++
			}
		})
	}
}

func BenchmarkBSearchProper(b *testing.B) {
	for i := 0; i < len(steps); i++ {
		array, needles := GetTestData(steps[i])
		if !PowerOfTwo(len(needles)) {
			b.Fatalf("expected array of length that is power of two, got %d", len(needles))
		}
		b.Run(strconv.Itoa(steps[i]), func(b *testing.B) {
			var i int
			for b.Loop() {
				_ = BSearchProper(array, needles[i&(len(needles)-1)])
				i++
			}
		})
	}
}
