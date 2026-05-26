export
void
Nop()
{
}


export
uniform int32
LinearSearch(uniform int32 haystack[], uniform int32 n, uniform int32 needle)
{
	for (uniform int i = 0; i < n; i++) {
		if (haystack[i] == needle) {
			return i;
		}
	}
	return -1;
}


export
uniform int32
BinarySearch(uniform int32 haystack[], uniform int32 n, uniform int32 needle)
{
	uniform int32 l = 0, r = n - 1;

	while (l <= r) {
		uniform int32 k = (l + r) >> 1;
		if (needle == haystack[k]) return k;
		if (needle < haystack[k]) r = k - 1; else l = k + 1;
	}

	return -1;
}


extern "C" uniform int32 bsf(uniform int32);
extern "C" uniform int32 bsr(uniform int32);


export
uniform int32
BSearch(uniform int32 haystack[], uniform int32 n, uniform int32 needle)
{
	uniform int32 l = 0, r = n - 1;

	while (l <= r) {
		int32 k = ((r - l + 1) / programCount) * programIndex + l;
		#if 1
		if (needle >= haystack[k]) l = extract(k + 1, bsr(lanemask()));
		if (needle <= haystack[k]) r = extract(k - 1, bsf(lanemask()));
		#else
		if (needle >= haystack[k]) l = reduce_max(k + 1);
		if (needle <= haystack[k]) r = reduce_min(k - 1);
		#endif
	}

	return (l - r > 1) ? r+1 : -1;
}


