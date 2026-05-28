#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <immintrin.h>
#include <x86intrin.h>


#define max(a, b) ((a) > (b) ? (a) : (b))


typedef int32_t int32;


void
ArrayPrint(int32 array[], int n)
{
	int i;

	printf("[");
	for (i = 0; i < n; i++) {
		printf("%6d", array[i]);
	}
	printf("]");
}


int32
LinearSearchC(int32 haystack[], int32 n, int32 needle)
{
	int32 i;

	for (i = 0; i < n; i++) {
		if (haystack[i] == needle) {
			return i;
		}
	}

	return -1;
}


int32
BinarySearchC(int32 haystack[], int32 n, int32 needle)
{
	int32 l = 0, r = n - 1;

	while (l <= r) {
		int32 k = (l + r) >> 1;
		if (needle == haystack[k]) return k;
		if (needle < haystack[k]) r = k - 1; else l = k + 1;
	}

	return -1;
}


#if 0
int
BSearchC(int32 haystack[], int32 n, int32 needle)
{
	enum {
		programCount = 8,
		programMask  = (1<<programCount) - 1,
		tzcntLast = sizeof(*haystack) * 8
	};

	int32 l = 0;
	int32 r = n - 1;
	int32 i;

	__m256i needles = _mm256_set1_epi32(needle);
	__m256i programIndicies = _mm256_set_epi32(7, 6, 5, 4, 3, 2, 1, 0);

	volatile int32 kmem[max(programCount, tzcntLast+1)];
	while (r - l + 1 > programCount) {
		kmem[tzcntLast-1] = l;
		kmem[tzcntLast] = r + 1;

		__m256i ls = _mm256_set1_epi32(l);
		__m256i k = _mm256_add_epi32(_mm256_mullo_epi32(_mm256_set1_epi32((r - l + 1) / programCount), programIndicies), ls);
		__m256i elements = _mm256_i32gather_epi32(haystack, k, 4);

		__m256i ltMask = _mm256_cmpgt_epi32(elements, needles);
		unsigned char lt = _mm256_movemask_ps((__m256)ltMask);

		unsigned char rindex =  __builtin_ctz(lt); /* [0; tzcntLast]. */
		unsigned char lindex =  rindex - 1;

		_mm256_storeu_si256((__m256i*)kmem, k);
		l = kmem[lindex] + 1;
		r = kmem[rindex] - 1;

		// ArrayPrint(kmem, programCount); printf(" ge = %08b, le = %08b, li = %d ri = %d, l = %d, r = %d, c = %d\n", ge, le, lindex, rindex, l, r, rindex == sizeof(*haystack) * 8); fflush(stdout);
	}

	if (l > r) return r;
	else for (i = l-1; i <= r; i++) if (haystack[i] == needle) return i;
	return -1;
}
#else
int
BSearchC(int32 haystack[], int32 n, int32 needle)
{
	enum {
		programCount = 8,
		programMask  = (1<<programCount) - 1,
		tzcntLast = sizeof(*haystack) * 8
	};

	int32 l = 0;
	int32 r = n - 1;
	int32 i;

	__m256i needles = _mm256_set1_epi32(needle);
	__m256i programIndicies = _mm256_set_epi32(7, 6, 5, 4, 3, 2, 1, 0);

	int32 kmem[max(programCount, tzcntLast+1)];
	while (r - l + 1 > programCount) {
		kmem[tzcntLast] = r + 1;

		__m256i ls = _mm256_set1_epi32(l);
		__m256i k = _mm256_add_epi32(_mm256_mullo_epi32(_mm256_set1_epi32((r - l + 1) / programCount), programIndicies), ls);
		__m256i elements = _mm256_i32gather_epi32(haystack, k, 4);

		__m256i ltMask = _mm256_cmpgt_epi32(elements, needles);
		unsigned char lt = _mm256_movemask_ps((__m256)ltMask);
		unsigned char ge = ~lt;

		int lindex =  _bit_scan_reverse(ge);
		int rindex =  __builtin_ctz(lt);

		_mm256_storeu_si256((__m256i*)kmem, k);
		l = kmem[lindex] + 1;
		r = kmem[rindex] - 1;

		// ArrayPrint(kmem, programCount); printf(" ge = %08b, le = %08b, li = %d ri = %d, l = %d, r = %d, c = %d\n", ge, le, lindex, rindex, l, r, rindex == sizeof(*haystack) * 8); fflush(stdout);
	}

	if (l > r) return r;
	else for (i = l-1; i <= r; i++) if (haystack[i] == needle) return i;
	return -1;
}
#endif


void
FlushFromCache(int32 array[], int n)
{
	int i;

	for (i = 0; i < n; i += 64/sizeof(*array)) {
		_mm_clflushopt(&array[i]);
	}
}


int32
simd_quad(int32 carr[], int32 cardinality, int32 pos)
{
    const int32_t gap = 16;
    int32 j;

    if (cardinality < gap) {
      for (j = 0; j < cardinality; j++) {
          if (carr[j] == pos) return j;
        }
        return -1;
    }
    int32_t num_blocks = cardinality / gap;
    int32_t base = 0;
    int32_t n = num_blocks;
    while (n > 3) {
      int32_t quarter = n >> 2;

      int32_t k1 = carr[(base + quarter + 1) * gap - 1];
      int32_t k2 = carr[(base + 2 * quarter + 1) * gap - 1];
      int32_t k3 = carr[(base + 3 * quarter + 1) * gap - 1];

      int32_t c1 = (k1 < pos);
      int32_t c2 = (k2 < pos);
      int32_t c3 = (k3 < pos);

      base += (c1 + c2 + c3) * quarter;
      n -= 3 * quarter;
    }
    while (n > 1) {
        int32_t half = n >> 1;
        base = (carr[(base + half + 1) * gap - 1] < pos)
                 ? base + half : base;
        n -= half;
    }
    int32_t lo = (carr[(base + 1) * gap - 1] < pos)
                ? base + 1 : base;

#if 1
    if (lo < num_blocks) {
        const uint32_t *blk = carr + lo * gap;
        __m256i needle = _mm256_set1_epi32(pos);
        __m256i v0 = _mm256_loadu_si256((const __m256i *)blk);
        __m256i v1 = _mm256_loadu_si256((const __m256i *)(blk + 8));
        __m256i mask0 = _mm256_cmpeq_epi32(v0, needle);
        __m256i mask1 = _mm256_cmpeq_epi32(v1, needle);
        volatile int32 res0 = __builtin_ctz(_mm256_movemask_ps((__m256)mask0));
        volatile int32 res1 = __builtin_ctz(_mm256_movemask_ps((__m256)mask1));
        return lo * gap + ((res0 == 32) ? res1 + 8 : res0);
    }
#endif

    for (j = num_blocks * gap; j < cardinality; j++) {
        int32 v = carr[j];
        if (v >= pos) return (v == pos) ? j : -1;
    }
    return -1;
}
