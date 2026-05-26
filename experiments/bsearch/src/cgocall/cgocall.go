package cgocall

//go:nosplit
//go:noescape
func CGOCall(fn uintptr, haystack uintptr, n int32, needle int32) int32
