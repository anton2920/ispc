package main

/*
#cgo CFLAGS: -std=gnu89 -O3 -g -mavx2 -march=skylake -fno-pic
//#cgo LDFLAGS: -L. -lbsearch
#include <immintrin.h>
#include <x86intrin.h>
#if 0
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
int32	BSearchProper(int32 haystack[], int32 n, int32 needle);
*/
import "C"
import (
	"math/rand"
	"slices"
	"unsafe"

	"cgocall"
)

func LinearSearch(haystack []int32, needle int32) int32 {
	//return int32(C.LinearSearch((*C.int32)(unsafe.Pointer(&haystack[0])), C.int32(len(haystack)), C.int32(needle)))
	return cgocall.CGOCall(uintptr(C.LinearSearch), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func BinarySearch(haystack []int32, needle int32) int32 {
	//return int32(C.BinarySearch((*C.int32)(unsafe.Pointer(&haystack[0])), C.int32(len(haystack)), C.int32(needle)))
	return cgocall.CGOCall(uintptr(C.BinarySearch), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func BSearch(haystack []int32, needle int32) int32 {
	//return int32(C.BSearchProper((*C.int32)(unsafe.Pointer(&haystack[0])), C.int32(len(haystack)), C.int32(needle)))
	return cgocall.CGOCall(uintptr(C.BSearch), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
}

func BSearchProper(haystack []int32, needle int32) int32 {
	//return int32(C.BSearchProperProper((*C.int32)(unsafe.Pointer(&haystack[0])), C.int32(len(haystack)), C.int32(needle)))
	return cgocall.CGOCall(uintptr(C.BSearchProper), uintptr(unsafe.Pointer(&haystack[0])), int32(len(haystack)), needle)
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
	array, needles := GetTestData(1024*1024)
	//needle := int32(141734987)
	//needle := needles[0]
	needle := needles[len(needles)-1]
	_ = needles
	actual := BSearchProper(array, needle)
	if actual > 0 {
		println(BinarySearchGo(array, needle), actual, array[actual] == needle)
	}
}
