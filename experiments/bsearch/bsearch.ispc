export
void
Nop()
{
}


export
uniform int32
LinearSearchISPC(uniform int32 haystack[], uniform int32 n, uniform int32 needle)
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
BinarySearchISPC(uniform int32 haystack[], uniform int32 n, uniform int32 needle)
{
	uniform int32 l = 0, r = n - 1;

	while (l <= r) {
		uniform int32 k = (l + r) >> 1;
		if (needle == haystack[k]) return k;
		if (needle < haystack[k]) r = k - 1; else l = k + 1;
	}

	return -1;
}


export
uniform int32
BSearchISPC(uniform int32 haystack[], uniform int32 n, uniform int32 needle)
{
	uniform int32 l = 0, r = n - 1;

	while (r - l + 1 > programCount) {
		int32 k = ((r - l + 1) / programCount) * programIndex + l;
		uniform int32 mask = packmask(haystack[k] > needle);
		uniform int32 rindex = count_trailing_zeros(mask);
		uniform int32 lindex = (rindex-1) & 0b111;
		l = extract(k, lindex) + 1; r = select(rindex == 32, r, extract(k, rindex) - 1);
	}

	if (l > r) return r;
	else for (uniform int i = l-1; i <= r; i++) if (haystack[i] == needle) return i;
	return -1;
}


