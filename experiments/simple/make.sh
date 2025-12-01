#!/bin/sh

PROJECT=simple

ispc -o $PROJECT.o -h $PROJECT.h --target avx2-i32x8 -g simple.ispc
ispc -o $PROJECT.s --emit-asm --target avx2-i32x8 simple.ispc
cc -o $PROJECT -g -std=c90 -ansi *.c $PROJECT.o
