#include "array.ispc"
#include "matrix.ispc"


template <typename T>
void
CubePrint(uniform T cube[], uniform int n)
{
	print("[\n");
	for (uniform int i = 0; i < n; i++) {
		print("\t[\n");
		for (uniform int j = 0; j < n; j++) {
			print("\t\t"); ArrayPrint(&cube[i*n*n + j*n], n); print(",\n");
		}
		print("\t],\n");
	}
	print("]");
}


template <typename T>
void
CubePrintln(uniform T cube[], uniform int n)
{
	CubePrint(cube, n); print("\n");
}


template <typename T>
void
ComputeWeights(uniform float weights[], uniform T matrix[], uniform int n)
{
	uniform T *uniform tmatrix = (uniform T *uniform)alloca(n*n*sizeof(T));
	MatrixTranspose(tmatrix, &matrix[0], n, n);

	uniform T *uniform sums = (uniform T *uniform)alloca(n*sizeof(T));
	for (uniform int i = 0; i < n; i++) {
		sums[i] = ArraySum(&tmatrix[i*n], n);
	}
	foreach (i = 0...n, j = 0...n) {
		tmatrix[i*n+j] /= sums[i];
	}

	uniform T *uniform nmatrix = (uniform T *uniform)alloca(n*n*sizeof(T));
	MatrixTranspose(&nmatrix[0], tmatrix, n, n);
	for (uniform int i = 0; i < n; i++) {
		weights[i] = ArraySum(&nmatrix[i*n], n) / n;
	}
}


template <typename T>
void
CheckConsistency(uniform T matrix[], uniform float weights[], uniform int n)
{
	const uniform float RIs[] = {0.00, 0.00, 0.58, 0.90, 1.12, 1.24, 1.32, 1.41, 1.45, 1.49, 1.51, 1.48, 1.56, 1.57, 1.59};

	uniform float *uniform result = (uniform float *uniform)alloca(n);
	MatrixMultiply(result, matrix, weights, n, n, 1);

	foreach (i = 0...n) {
		result[i] /= weights[i];
	}
	uniform float lmax = ArraySum(result, n) / n;

	uniform float CI = (lmax - n) / (n - 1);

	uniform float RI = RIs[n-1];
	uniform float CR = CI/RI;

	print("λmax = %, C.I. = %, R.I = %, C.R. = % (", lmax, CI, RI, CR);
	if (CR <= 0.10) {
		print("OK!");
	} else {
		print("INCONSISTENT DATA!!!");
	}
	print(")\n");
}


void
println()
{
	print("\n");
}


export
uniform int
main()
{
#if 1
	#define N 3
	#define K 3
	uniform float criteria[N][N] = {
		{1, 1./3, 1./5},
		{3, 1, 1./2},
		{5, 2, 1},
	};
	uniform float alternatives[N][K][K] = {
		{
			{1, 2, 4},
			{1./2, 1, 2},
			{1./4, 1./2, 1},
		},
		{
			{1, 1./3, 1./5},
			{3, 1, 1./2},
			{5, 2, 1},
		},
		{
			{1, 1./2, 1./3},
			{2, 1, 1./2},
			{3, 2, 1},
		},
	};
#else
	#define N 3
	#define K 3
	uniform float criteria[N][N] = {
		{1, 1./3, 1./5},
		{3, 1, 1./2},
		{5, 2, 1},
	};
	uniform float alternatives[N][K][K] = {
		{
			{1, 2, 4},
			{1./2, 1, 2},
			{1./4, 1./2, 1},
		},
		{
			{1, 1./3, 1./5},
			{3, 1, 1./2},
			{5, 2, 1},
		},
		{
			{1, 1./2, 1./3},
			{2, 1, 1./2},
			{3, 2, 1},
		},
	};
#endif

	uniform float criteriaWeights[N];
	ComputeWeights(&criteriaWeights[0], &criteria[0][0], N);
	print("Criteria: "); MatrixPrintln(&criteria[0][0], N, N);
	print("Criteria weights: "); ArrayPrintln(&criteriaWeights[0], N);
	CheckConsistency(&criteria[0][0], &criteriaWeights[0], N);

	print("Alternatives: "); CubePrintln(&alternatives[0][0][0], N);
	uniform float alternativesWeights[N][K];
	for (uniform int i = 0; i < N; i++) {
		ComputeWeights(&alternativesWeights[i][0], &alternatives[i][0][0], N);
		print("Alternative % weights: ", i+1); ArrayPrintln(&alternativesWeights[i][0], N);
		CheckConsistency(&alternatives[i][0][0], &alternativesWeights[i][0], N);
	}
	uniform float talternativesWeights[K][N];
	MatrixTranspose(&talternativesWeights[0][0], &alternativesWeights[0][0], N, K);
	print("Transposed alternatives weights: "); MatrixPrintln(&alternativesWeights[0][0], K, N);

	uniform float rankings[K];
	MatrixMultiply(&rankings[0], &talternativesWeights[0][0], &criteriaWeights[0], K, N, 1);
	print("Rankings: "); ArrayPrintln(&rankings[0], K);

	return 0;
}


