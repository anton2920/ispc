package main

import (
	"math/rand"
	"os"
	"runtime"
	"slices"
	"testing"
)

const (
	TestN  = 1024
	BenchN = TestN
)

func PowerOfTwo(n int) bool {
	return (n & (n - 1)) == 0
}

/*
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
*/

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

func TestBinarySearchOpt(t *testing.T) {
	array, needles := GetTestData(TestN)
	for i := 0; i < len(array); i++ {
		needle := needles[i]

		expected := int32(slices.Index(array, needle))
		actual := BinarySearchOpt(array, needle)

		if expected != actual {
			t.Errorf("expected to find element %d at position %d, but found at position %d", needle, expected, actual)
		}
	}
}

func TestBinarySearchOpt2(t *testing.T) {
	array, needles := GetTestData(TestN)
	for i := 0; i < len(array); i++ {
		needle := needles[i]

		expected := int32(slices.Index(array, needle))
		actual := BinarySearchOpt2(array, needle)

		if expected != actual {
			t.Errorf("expected to find element %d at position %d, but found at position %d", needle, expected, actual)
		}
	}
}

func TestQuadSearch(t *testing.T) {
	array, needles := GetTestData(TestN)
	for i := 0; i < len(array); i++ {
		needle := needles[i]

		expected := int32(slices.Index(array, needle))
		actual := QuadSearch(array, needle)

		if expected != actual {
			t.Errorf("expected to find element %d at position %d, but found at position %d", needle, expected, actual)
		}
	}
}

type testData struct {
	Array   []int32
	Needles []int32
}

const (
	usePreparedData = true
	randomInitial   = false
	flushCache      = false
)

var steps = []int{1 << 8, 1 << 9, 1 << 10, 1 << 13, 1 << 16, 1 << 18, 1 << 19, 1 << 20, 1 << 21, 1 << 23, 1 << 26, 1 << 28}
var steps2str = map[int]string{1 << 8: "1K", 1 << 9: "2K", 1 << 10: "4K", 1 << 13: "32K", 1 << 16: "256K", 1 << 18: "1M", 1 << 19: "2M", 1 << 20: "4M", 1 << 21: "8M", 1 << 23: "32M", 1 << 26: "256M", 1 << 28: "1G"}
var testArrays = map[int]testData{}

/*
func BenchmarkLinearSearch(b *testing.B) {
	for i := 0; i < len(steps); i++ {
		var array, needles []int32
		if !usePreparedData {
			array, needles = GetTestData(steps[i])
		} else {
			td := testArrays[steps[i]]
			array, needles = td.Array, td.Needles
		}
		if !PowerOfTwo(len(needles)) {
			b.Fatalf("expected array of length that is power of two, got %d", len(needles))
		}
		b.Run(steps2str[steps[i]], func(b *testing.B) {
			var i int
			if randomInitial {
				 i = rand.Intn(len(needles))
			}
			for b.Loop() {
				if flushCache {
					b.StopTimer()
					FlushFromCache(array)
					b.StartTimer()
				}
				_ = LinearSearch(array, needles[i&(len(needles)-1)])
				i++
			}
		})
	}
}
*/

func BenchmarkBinarySearch(b *testing.B) {
	for i := 0; i < len(steps); i++ {
		var array, needles []int32
		if !usePreparedData {
			array, needles = GetTestData(steps[i])
		} else {
			td := testArrays[steps[i]]
			array, needles = td.Array, td.Needles
		}
		if !PowerOfTwo(len(needles)) {
			b.Fatalf("expected array of length that is power of two, got %d", len(needles))
		}
		b.Run(steps2str[steps[i]], func(b *testing.B) {
			var i int
			if randomInitial {
				i = rand.Intn(len(needles))
			}
			for b.Loop() {
				if flushCache {
					b.StopTimer()
					FlushFromCache(array)
					b.StartTimer()
				}
				_ = BinarySearch(array, needles[i&(len(needles)-1)])
				i++
			}
		})
	}
}

func BenchmarkBSearch(b *testing.B) {
	for i := 0; i < len(steps); i++ {
		var array, needles []int32
		if !usePreparedData {
			array, needles = GetTestData(steps[i])
		} else {
			td := testArrays[steps[i]]
			array, needles = td.Array, td.Needles
		}
		if !PowerOfTwo(len(needles)) {
			b.Fatalf("expected array of length that is power of two, got %d", len(needles))
		}
		b.Run(steps2str[steps[i]], func(b *testing.B) {
			var i int
			if randomInitial {
				i = rand.Intn(len(needles))
			}
			for b.Loop() {
				if flushCache {
					b.StopTimer()
					FlushFromCache(array)
					b.StartTimer()
				}
				_ = BSearch(array, needles[i&(len(needles)-1)])
				i++
			}
		})
	}
}

func BenchmarkBinarySearchOpt(b *testing.B) {
	for i := 0; i < len(steps); i++ {
		var array, needles []int32
		if !usePreparedData {
			array, needles = GetTestData(steps[i])
		} else {
			td := testArrays[steps[i]]
			array, needles = td.Array, td.Needles
		}
		if !PowerOfTwo(len(needles)) {
			b.Fatalf("expected array of length that is power of two, got %d", len(needles))
		}
		b.Run(steps2str[steps[i]], func(b *testing.B) {
			var i int
			if randomInitial {
				i = rand.Intn(len(needles))
			}
			for b.Loop() {
				if flushCache {
					b.StopTimer()
					FlushFromCache(array)
					b.StartTimer()
				}
				_ = BinarySearchOpt(array, needles[i&(len(needles)-1)])
				i++
			}
		})
	}
}

func BenchmarkBinarySearchOpt2(b *testing.B) {
	for i := 0; i < len(steps); i++ {
		var array, needles []int32
		if !usePreparedData {
			array, needles = GetTestData(steps[i])
		} else {
			td := testArrays[steps[i]]
			array, needles = td.Array, td.Needles
		}
		if !PowerOfTwo(len(needles)) {
			b.Fatalf("expected array of length that is power of two, got %d", len(needles))
		}
		b.Run(steps2str[steps[i]], func(b *testing.B) {
			var i int
			if randomInitial {
				i = rand.Intn(len(needles))
			}
			for b.Loop() {
				if flushCache {
					b.StopTimer()
					FlushFromCache(array)
					b.StartTimer()
				}
				_ = BinarySearchOpt2(array, needles[i&(len(needles)-1)])
				i++
			}
		})
	}
}

func BenchmarkQuadSearch(b *testing.B) {
	for i := 0; i < len(steps); i++ {
		var array, needles []int32
		if !usePreparedData {
			array, needles = GetTestData(steps[i])
		} else {
			td := testArrays[steps[i]]
			array, needles = td.Array, td.Needles
		}
		if !PowerOfTwo(len(needles)) {
			b.Fatalf("expected array of length that is power of two, got %d", len(needles))
		}
		b.Run(steps2str[steps[i]], func(b *testing.B) {
			var i int
			if randomInitial {
				i = rand.Intn(len(needles))
			}
			for b.Loop() {
				if flushCache {
					b.StopTimer()
					FlushFromCache(array)
					b.StartTimer()
				}
				_ = QuadSearch(array, needles[i&(len(needles)-1)])
				i++
			}
		})
	}
}

func TestMain(m *testing.M) {
	runtime.LockOSThread()

	if usePreparedData {
		c := make(chan testData)
		for _, size := range steps {
			go func() {
				array, needles := GetTestData(size)
				c <- testData{array, needles}
			}()
		}
		for i := 0; i < len(steps); i++ {
			td := <-c
			testArrays[len(td.Array)] = td
		}
	}

	os.Exit(m.Run())
}
