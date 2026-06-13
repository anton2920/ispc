package main

/*
#cgo CFLAGS: -std=gnu89 -O3 -g -mavx2 -march=skylake -fno-pic
#cgo LDFLAGS: -L. -lbsearch
#include <immintrin.h>
#include <x86intrin.h>
#if 1
	#include "bsearch.h"
#else
	#include <stdint.h>
#endif

typedef int32_t int32;

int32
bsf(int32 n)
{
	return (n == 0) ? 0 : _bit_scan_forward(n);
}

int32
bsr(int32 n)
{
	return (n == 0) ? 0 : _bit_scan_reverse(n);
}

int32	LinearSearch(int32 haystack[], int32 n, int32 needle);
int32	BinarySearch(int32 haystack[], int32 n, int32 needle);
int32	BSearch(int32 haystack[], int32 n, int32 needle);
int32	BinarySearchOpt(int32 haystack[], int32 n, int32 needle);
int32	BinarySearchOpt2(int32 haystack[], int32 n, int32 needle);
int32	simd_quad(int32 carr[], int32 cardinality, int32 pos);

void	FlushFromCache(int32 array[], int n);
*/
import "C"
import (
	"math/rand"
	"slices"
	"unsafe"

	"cgocall"
)

func LinearSearch(haystack []int32, needle int32) int32 {
	return cgocall.CGOCall(uintptr(C.LinearSearch), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func BinarySearch(haystack []int32, needle int32) int32 {
	return cgocall.CGOCall(uintptr(C.BinarySearch), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func BSearch(haystack []int32, needle int32) int32 {
	return cgocall.CGOCall(uintptr(C.BSearch), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func BSearchISPC(haystack []int32, needle int32) int32 {
	return cgocall.CGOCall(uintptr(C.BSearchISPC), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func BinarySearchOpt(haystack []int32, needle int32) int32 {
	return cgocall.CGOCall(uintptr(C.BinarySearchOpt), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func BinarySearchOpt2(haystack []int32, needle int32) int32 {
	return cgocall.CGOCall(uintptr(C.BinarySearchOpt2), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func QuadSearch(haystack []int32, needle int32) int32 {
	return cgocall.CGOCall(uintptr(C.simd_quad), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func FlushFromCache(array []int32) int32 {
	return cgocall.CGOCall(uintptr(C.FlushFromCache), uintptr(unsafe.Pointer(&array[0])), int32(len(array)), 0)
}

func GetTestData(n int) ([]int32, []int32) {
	const seed = 42
	rng := rand.New(rand.NewSource(seed))

	needles := make([]int32, n)
	array := make([]int32, n)
	for i := 0; i < len(array); i++ {
		array[i] = rng.Int31()
		needles[i] = array[i]
	}
	slices.Sort(array)

	return array, needles
}

func main() {
	array, needles := GetTestData(1024)
	//needle := int32(1042974411)
	needle := int32(141734987)
	//needle := needles[0]
	//needle := needles[len(needles)-1]
	_ = needles
	actual := BSearchISPC(array, needle)
	if actual > 0 {
		println(BinarySearchGo(array, needle), actual, array[actual] == needle)
	}
}
