#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <immintrin.h>

#include "color.h"
#include "renderer.h"

using namespace ispc;

#define nil (void*)0

#define WIDTH 640
#define HEIGHT 480

typedef void (*Renderer)(Color*, int, int);

void
SolidC(Color *pixels, int width, int height)
{
	int	i, j;

	for (i = 0; i < height; i++) {
		for (j = 0; j < width; j++) {
			pixels[i*width+j] = RGB(255, 0, 0);
		}
	}
}


void
StripesC(Color *pixels, int width, int height)
{
	int	i, j;
	int	size;

	size = 64;
	for (i = 0; i < height; i++) {
		for (j = 0; j < width; j++) {
			if ((((i + j) / size) & 1) == 0) {
				pixels[i*width+j] = RGB(255, 180, 0);
			}
		}
	}
}


void
CheckersC(Color *pixels, int width, int height)
{
	int	i, j;
	int	size;

	size = 64;
	for (i = 0; i < height; i++) {
		for (j = 0; j < width; j++) {
			if ((((i / size) + (j / size)) & 1) == 0) {
				pixels[i*width+j] = RGB(0, 180, 255);
			}
		}
	}
}


int
DumpPPM(char *filename, Color *pixels, int width, int height)
{
	FILE * out;
	int	i, j;

	out = fopen(filename, "wb");
	if (out == nil) {
		fprintf(stderr, "Failed to open file: %m\n");
		return 1;
	}

	fprintf(out, "P6 %d %d 255 ", WIDTH, HEIGHT);
	for (i = 0; i < width * height; i++) {
		fwrite(&pixels[i], 3, 1, out);
	}

	return 0;
}


#define Compare(name, pixels, width, height)\
{\
	__uint64_t start, end, elapsedC, elapsedISPC;\
	int	count;\
	int	i;\
\
	count = 10 * 1000;\
\
	elapsedC = 0;\
	for (i = 0; i < count; i++) {\
		start = __rdtsc();\
		name##C(pixels, WIDTH, HEIGHT);\
		end = __rdtsc();\
		elapsedC += end - start;\
	}\
	printf(#name"C: Took %ld cycles to perform %d iterations [%lf cyc/op]\n", elapsedC, count, (double)elapsedC / count);\
\
	elapsedISPC = 0;\
	for (i = 0; i < count; i++) {\
		start = __rdtsc();\
		name##ISPC(pixels, WIDTH, HEIGHT);\
		end = __rdtsc();\
		elapsedISPC += end - start;\
	}\
	printf(#name"ISPC: Took %ld cycles to perform %d iterations [%lf cyc/op]\n", elapsedISPC, count, (double)elapsedISPC / count);\
\
	if (elapsedISPC < elapsedC) {\
		printf(#name"ISPC is %g times faster\n", (double)elapsedC / elapsedISPC);\
	} else {\
		printf(#name"C is %g times faster\n", (double)elapsedISPC / elapsedC);\
	}\
	printf("\n");\
}


int
main()
{
	Color	 * pixels;

	pixels = (Color * )calloc(WIDTH * HEIGHT, sizeof(*pixels));
	assert(pixels != nil);

#if 1
	Compare(Solid, pixels, WIDTH, HEIGHT);
	Compare(Stripes, pixels, WIDTH, HEIGHT);
	Compare(Checkers, pixels, WIDTH, HEIGHT);
#endif

	//SolidISPC(pixels, WIDTH, HEIGHT);
	//StripesISPC(pixels, WIDTH, HEIGHT);
	//CheckersISPC(pixels, WIDTH, HEIGHT);

	return DumpPPM("image.ppm", pixels, WIDTH, HEIGHT);
}


