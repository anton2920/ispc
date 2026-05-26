package main

func LinearSearchGo(haystack []int32, needle int32) int32 {
	for i := 0; i < len(haystack); i++ {
		if haystack[i] == needle {
			return int32(i)
		}
	}
	return -1
}

func BinarySearchGo(haystack []int32, needle int32) int32 {
	l := int32(0)
	r := int32(len(haystack) - 1)

	for l <= r {
		k := (l + r) >> 1
		if needle == haystack[k] {
			return k
		}

		if needle < haystack[k] {
			r = k - 1
		} else {
			l = k + 1
		}
	}

	return -1
}
