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
