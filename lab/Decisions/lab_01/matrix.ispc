#include "array.isph"


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
	MatrixPrint(matrix, cols, rows);
	print("\n");
}


template <typename T>
void
MatrixTranspose(uniform T matrix[], int *uniform rows, int *uniform cols)
{
	for (uniform int i = 0; i < *rows; i++) {
		foreach (j = i...*cols) {
			T tmp = matrix[i**cols+j];
			#pragma ignore warning(perf) // ignore gather.
			matrix[i**cols+j] = matrix[j**cols+i];
			#pragma ignore warning(perf) // ignore scatter.
			matrix[j**cols+i] = tmp;
		}
	}

	uniform int tmp = *cols;
	*cols = *rows;
	*rows = tmp;
}
