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
	#define ROWS 4
	#define COLS 4
	uniform float data[ROWS][COLS] = {
		{1500, 90, 16, 10},
		{2000, 95, 16, 12},
		{1200, 85, 32, 8},
		{1800, 88, 24, 9},
	};
	uniform int functions[COLS] = {MIN, MAX, MAX, MAX};
	uniform float weights[COLS] = {0.4, 0.3, 0.2, 0.1};
#else
	#define ROWS 4
	#define COLS 3
	uniform float data[ROWS][COLS] = {
		{100000, 20, 85},
		{80000, 25, 90},
		{60000, 30, 80},
		{70000, 22, 95},
	};
	uniform int functions[COLS] = {MIN, MAX, MAX};
	uniform float weights[COLS] = {0.5, 0.3, 0.2};
#endif

	uniform int rows = ROWS, cols = COLS;

	uniform float tdata[COLS][ROWS];
	uniform int trows = COLS, tcols = ROWS;

	print("Initial: "); MatrixPrintln(&data[0][0], rows, cols);
	MatrixTranspose(&tdata[0][0], &data[0][0], rows, cols);
	print("Transposed: "); MatrixPrintln(&tdata[0][0], trows, tcols);

	uniform float rmses[COLS];
	for (uniform int i = 0; i < trows; i++) {
		rmses[i] = ArrayRMS(&tdata[i][0], tcols) * sqrt((uniform float)tcols);
	}
	foreach (i = 0...trows, j = 0...tcols) {
		tdata[i][j] = tdata[i][j] * weights[i] / rmses[i];
	}
	print("Weighted & normalized: "); MatrixPrintln(&tdata[0][0], trows, tcols);

	uniform float ideals[COLS], aideals[COLS];
	for (uniform int i = 0; i < trows; i++) {
		if (functions[i] == MAX) {
			ideals[i] = ArrayMax(&tdata[i][0], tcols);
			aideals[i] = ArrayMin(&tdata[i][0], tcols);
		} else {
			ideals[i] = ArrayMin(&tdata[i][0], tcols);
			aideals[i] = ArrayMax(&tdata[i][0], tcols);
		}
	}
	print("Ideals: "); ArrayPrintln(&ideals[0], trows);
	print("Anti-ideals: "); ArrayPrintln(&aideals[0], trows);

	MatrixTranspose(&data[0][0], &tdata[0][0], trows, tcols);
	print("De-transposed: "); MatrixPrintln(&data[0][0], rows, cols);

	uniform float idealDists[ROWS], aidealDists[ROWS];
	for (uniform int i = 0; i < rows; i++) {
		float idealSum = 0, aidealSum = 0;
		foreach (j = 0...cols) {
			idealSum += (data[i][j] - ideals[j]) * (data[i][j] - ideals[j]);
			aidealSum += (data[i][j] - aideals[j]) * (data[i][j] - aideals[j]);
		}
		idealDists[i] = sqrt(reduce_add(idealSum));
		aidealDists[i] = sqrt(reduce_add(aidealSum));
	}
	print("Distances from ideals: "); ArrayPrintln(&idealDists[0], rows);
	print("Distances from anti-ideals: "); ArrayPrintln(&aidealDists[0], rows);

	uniform float closenesses[ROWS];
	foreach (i = 0...rows) {
		closenesses[i] = aidealDists[i] / (idealDists[i] + aidealDists[i]);
	}
	print("Closenesses: "); ArrayPrintln(&closenesses[0], rows);
}


