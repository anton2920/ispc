#include "color.h"

#define MAXPROCS 8

task
void
SolidLineISPC(uniform Color pixels[], uniform int width, uniform int height)
{
	uniform int span = height / taskCount;
	uniform int begin = taskIndex * span;
	uniform int end = min(begin + span, height);

	for (uniform int i = begin; i < end; i++) {
		foreach (j = 0 ... width) {
			pixels[i * width + j] = RGB(255, 0, 0);
		}
	}
}


export
void
SolidISPC(uniform Color pixels[], uniform int width, uniform int height)
{
	launch[MAXPROCS] SolidLineISPC(pixels, width, height);
}


task
void
StripesLineISPC(uniform Color pixels[], uniform int width, uniform int height)
{
	uniform int span = height / taskCount;
	uniform int begin = taskIndex * span;
	uniform int end = min(begin + span, height);

	const uniform int size = 64;
	for (uniform int i = begin; i < end; i++) {
		foreach (j = 0 ... width) {
			if ((((i + j) / size) & 1) == 0) {
				pixels[i*width+j] = RGB(255, 180, 0);
			}
		}
	}
}


export
void
StripesISPC(uniform Color pixels[], uniform int width, uniform int height)
{
	launch[MAXPROCS] StripesLineISPC(pixels, width, height);
}


task
void
CheckersLineISPC(uniform Color pixels[], uniform int width, uniform int height)
{
	uniform int span = height / taskCount;
	uniform int begin = taskIndex * span;
	uniform int end = min(begin + span, height);

	const uniform int size = 64;
	for (uniform int i = begin; i < end; i++) {
		foreach (j = 0 ... width) {
			if ((((i / size) + (j / size)) & 1) == 0) {
				pixels[i*width+j] = RGB(0, 180, 255);
			}
		}
	}
}


export
void
CheckersISPC(uniform Color pixels[], uniform int width, uniform int height)
{
	launch[MAXPROCS] CheckersLineISPC(pixels, width, height);
}
