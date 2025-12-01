#!/bin/sh

set -e

PROJECT=renderer

ispc -o $PROJECT.o -h $PROJECT.h --target avx2-i32x8 -O3 $PROJECT.ispc
c++ -o $PROJECT -O3 main.c $PROJECT.o tasksys.cpp -L/usr/local/lib -lpthread

# Emit assembly listings.
ispc -o $PROJECT.s --emit-asm --target avx2-i32x8 -O1 $PROJECT.ispc
# c++ -S -o main.s -O3 main.c
