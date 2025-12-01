#define RGB(r, g, b) (b << 16 | g << 8 | r)

#ifndef ISPC_UINT_IS_DEFINED
typedef unsigned int	uint32;
#endif
typedef uint32 Color;
