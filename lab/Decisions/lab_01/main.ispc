#include "array.ispc"
#include "matrix.ispc"


export
void
main()
{
#if 1
	#define ROWS 3
	#define COLS 4
	uniform float data[ROWS][COLS] = {
		{8.5, -12, -2.5, -3},
		{7.0, -8, -3.0, -2},
		{9.2, -15, -1.8, -4},
	};
	uniform float weights[COLS] = {0.4, 0.3, 0.2, 0.1};
#else
	#define ROWS 3
	#define COLS 3
	uniform float data[ROWS][COLS] = {
		{-100, 8, -5},
		{-80, 6, -7},
		{-120, 9, -3},
	};
	uniform float weights[COLS] = {0.5, 0.3, 0.2};
#endif

	uniform int rows = ROWS;
	uniform int cols = COLS;

	print("Initial data: "); MatrixPrintln(&data[0][0], rows, cols);
	MatrixTranspose(&data[0][0], &rows, &cols);
	print("Transposed data: "); MatrixPrintln(&data[0][0], rows, cols);

	uniform float mins[ROWS];
	uniform float maxs[ROWS];
	for (uniform int i = 0; i < rows; i++) {
		mins[i] = ArrayMin(&data[i][0], cols);
		maxs[i] = ArrayMax(&data[i][0], cols);
	}
	print("Mins: "); ArrayPrintln(mins, cols);
	print("Maxs: "); ArrayPrintln(maxs, cols);

	foreach (i = 0...rows, j = 0...cols) {
		data[i][j] = (data[i][j] - mins[i]) / (maxs[i] - mins[i]);
	}
	print("Normalized data: "); MatrixPrintln(&data[0][0], rows, cols);
	MatrixTranspose(&data[0][0], &rows, &cols);
	print("Transposed normalized data: "); MatrixPrintln(&data[0][0], rows, cols);

	uniform float scores[ROWS];
	for (uniform int i = 0; i < rows; i++) {
		float score = 0;
		foreach (j = 0...cols) {
			score += data[i][j] * weights[j];
		}
		scores[i] = reduce_add(score);
	}

	print("Scores: "); ArrayPrintln(scores, rows);
}


