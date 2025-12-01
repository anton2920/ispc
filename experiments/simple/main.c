#include <stdio.h>
#include <string.h>

#include "simple.h"

int
main()
{
	float	vin[16], vout[16];
	int	i;

	for (i = 0; i < 16; ++i) {
		vin[i] = i;
	}
	memset(vout, 0, sizeof(vout));

	simple(vout, vin, 16);

	for (i = 0; i < 16; ++i) {
		printf("%d: simple(%f) = %f\n", i, vin[i], vout[i]);
	}
}


