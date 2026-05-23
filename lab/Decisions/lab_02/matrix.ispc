template <typename T>
void
MatrixMultiply(uniform T dst[], uniform T src1[], uniform T src2[], uniform int rows1, uniform int cols1, uniform int cols2)
{
	for (uniform int i = 0; i < rows1; i++) {
		foreach (j = 0...cols2) {
			dst[i*cols2+j] = 0;
			for (uniform int k = 0; k < cols1; k++) {
				dst[i*cols2+j] += src1[i*cols1+k] * src2[k*cols2+j];
			}
		}
	}
}


template <typename T>
void
MatrixPrint(uniform T matrix[], uniform int rows, uniform int cols)
{
	print("[\n");
	for (uniform int i = 0; i < rows; i++) {
		print("\t");
		ArrayPrint(&matrix[i*cols], cols);
		print(",\n");
	}
	print("]");
}


template <typename T>
void
MatrixPrintln(uniform T matrix[], uniform int rows, uniform int cols)
{
	MatrixPrint(matrix, rows, cols);
	print("\n");
}


template <typename T>
void
MatrixTranspose(uniform T dst[], uniform T src[], uniform int rows, uniform int cols)
{
	#if TARGET_WIDTH == 8
		#define TILE_COLS 16
	#elif TARGET_WIDTH == 16
		#define TILE_COLS 32
	#endif
	#define TILE_ROWS 8

	/* https://github.com/ispc/ispc/blob/7af581e14b88af3ed69bf2a6f0a58afccdc74803/examples/cpu/attention/attention.ispc#L411 */
	for (uniform int si = 0; si < rows; si += TILE_ROWS) {
		for (uniform int sj = 0; sj < cols; sj += TILE_COLS) {
			uniform int ei = min(si + TILE_ROWS, rows);
			uniform int ej = min(sj + TILE_COLS, cols);

			foreach (i = si...ei, j = sj...ej) {
				#pragma ignore warning(perf) // ignore scatter for store.
				dst[j * rows + i] = src[i * cols + j];
			}
		}
	}
}


uniform int
GCD(uniform int a, uniform int b)
{
	if (a == b)
		return a;
	if (a == 0)
		return b;
	if (b == 0)
		return a;

	if (~a & 1) {
		if (b & 1)
			return GCD(a >> 1, b);
		else
			return GCD(a >> 1, b >> 1) << 1;
	}

	if (~b & 1)
		return GCD(a, b >> 1);

	if (a > b)
		return GCD((a - b) >> 1, b);

	return GCD((b - a) >> 1, a);
}


template <typename T>
void
MatrixTranspose(uniform T matrix[], int *uniform rows, int *uniform cols)
{
	uniform T *uniform tmp = (float *uniform)alloca(max(*rows, *cols) * sizeof(T));
	uniform int m = *rows, n = *cols;
	uniform int c = GCD(m, n);
	uniform int a = m/c;
	uniform int b = n/c;

	#define UNSAFE_USE_DOUBLES_FOR_DIVISION

	if (c > 1) {
		for (uniform int j = 0; j < n; j++) {
			foreach (i = 0...m) {
				#ifdef UNSAFE_USE_DOUBLES_FOR_DIVISION
					int r = fmod((double)(i + j/b), m);
				#else
					#pragma ignore warning(perf)
					int r = (i + j/b) % m;
				#endif
				#pragma ignore warning(perf)
				tmp[i] = matrix[r*n+j];
			}
			foreach (i = 0...m) {
				#pragma ignore warning(perf)
				matrix[i*n+j] = tmp[i];
			}
		}
	}

	for (uniform int i = 0; i < m; i++) {
		foreach (j = 0...n) {
			#ifdef UNSAFE_USE_DOUBLES_FOR_DIVISION
				int d = fmod(fmod(i + floor((double)j/b), m) + j*m, n);
			#else
				#pragma ignore warning(perf)
				int d = (((i + j/b) % m) + j*m) % n;
			#endif
			#pragma ignore warning(perf)
			tmp[d] = matrix[i*n+j];
		}
		foreach (j = 0...n) {
			#pragma ignore warning(perf)
			matrix[i*n+j] = tmp[j];
		}
	}

	for (uniform int j = 0; j < n; j++) {
		foreach (i = 0...m) {
			#ifdef UNSAFE_USE_DOUBLES_FOR_DIVISION
				int s = fmod((j + i*n - floor((double)i/a)), m);
			#else
				#pragma ignore warning(perf)
				int s = (j + i*n - i/a) % m;
			#endif
			#pragma ignore warning(perf)
			tmp[i] = matrix[s*n+j];
		}
		foreach (i = 0...m) {
			#pragma ignore warning(perf)
			matrix[i*n+j] = tmp[i];
		}
	}

	*rows = n;
	*cols = m;
}


