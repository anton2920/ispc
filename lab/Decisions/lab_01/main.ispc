#include "array.ispc"
#include "matrix.ispc"


enum {
	MIN,
	MAX
};


export
void
main()
{
#if 1
	#define ROWS 3
	#define COLS 4
	uniform float data[ROWS][COLS] = {
		{8.5, 12, 2.5, 3},
		{7.0, 8, 3.0, 2},
		{9.2, 15, 1.8, 4},
	};
	uniform int functions[COLS] = {MAX, MIN, MIN, MIN};
	uniform float weights[COLS] = {0.4, 0.3, 0.2, 0.1};
#else
	#define ROWS 3
	#define COLS 3
	uniform float data[ROWS][COLS] = {
		{100, 8, 5},
		{80, 6, 7},
		{120, 9, 3},
	};
	uniform int functions[COLS] = {MIN, MAX, MIN};
	uniform float weights[COLS] = {0.5, 0.3, 0.2};
#endif

	uniform int rows = ROWS, cols = COLS;

	uniform float tdata[COLS][ROWS];
	uniform int trows = COLS, tcols = ROWS;

	print("Initial data: "); MatrixPrintln(&data[0][0], rows, cols);
	MatrixTranspose(&tdata[0][0], &data[0][0], rows, cols);
	print("Transposed data: "); MatrixPrintln(&tdata[0][0], trows, tcols);

	uniform float mins[COLS];
	uniform float maxs[COLS];
	for (uniform int i = 0; i < trows; i++) {
		mins[i] = ArrayMin(&tdata[i][0], tcols);
		maxs[i] = ArrayMax(&tdata[i][0], tcols);
	}
	print("Mins: "); ArrayPrintln(mins, tcols);
	print("Maxs: "); ArrayPrintln(maxs, tcols);

	foreach (i = 0...trows, j = 0...tcols) {
		if (functions[i] == MAX) {
			tdata[i][j] = (tdata[i][j] - mins[i]) / (maxs[i] - mins[i]);
		} else {
			tdata[i][j] = (maxs[i] - tdata[i][j]) / (maxs[i] - mins[i]);
		}
	}
	print("Normalized data: "); MatrixPrintln(&tdata[0][0], trows, tcols);
	MatrixTranspose(&data[0][0], &tdata[0][0], trows, tcols);
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


