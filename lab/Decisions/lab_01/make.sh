#!/bin/sh

set -e

# Unity build
ispc -o main.o --target avx2-i32x8 -g main.ispc
cc -o main -g *.o && rm -f *.o *.s
