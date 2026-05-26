#!/bin/sh

PROJECT=bsearch

VERBOSITY=0
VERBOSITYFLAGS=""
while test "$1" = "-v"; do
	VERBOSITY=$((VERBOSITY+1))
	VERBOSITYFLAGS="$VERBOSITYFLAGS -v"
	shift
done

now()
{
	date +%s%N
}

run()
{
	if test $VERBOSITY -gt 1; then echo "$@"; fi
	"$@" || exit 1
}

printv()
{
	if test $VERBOSITY -gt 0; then echo "$@"; fi
}

buildISPC()
{
	# run ispc $@ --target=avx2-i32x8 -o bsearch.o -h bsearch.h bsearch.ispc
	# run gcc -c -std=gnu89 -o bsearch2.o $@ -mavx2 -march=skylake bsearch.c
	# run ar rc libbsearch.a *.o
	# run rm -f *.o
}

# NOTE(anton2920): don't like Google spying on me.
GOPROXY=direct; export GOPROXY
GOSUMDB=off; export GOSUMDB

# NOTE(anton2920): disable Go 1.11+ package management.
GO111MODULE=off; export GO111MODULE
GOPATH=`go env GOPATH`:`pwd`; export GOPATH
CGO_ENABLED=1; export CGO_ENABLED
CC=gcc; export CC

STARTTIME=`now`

TARGET=$1
shift

case $TARGET in
	'' | debug)
		run buildISPC -O0 -g
		run go build $VERBOSITYFLAGS -a -o $PROJECT -pgo off -gcflags="all=-N -l" -ldflags="-X main.BuildMode=Debug" -tags gofadebug
		;;
	allocs | allocations)
		printv go build $VERBOSITYFLAGS -o /dev/null -gcflags="all=-m -m"
		go build $VERBOSITYFLAGS -o /dev/null -gcflags="all=-m -m" 2>&1 | sort | uniq | grep "moved to heap" >$PROJECT.esc
		;;
	allocs-plus | allocations-plus)
		printv go build $VERBOSITYFLAGS -o /dev/null -gcflags="all=-m -m"
		go build $VERBOSITYFLAGS -o /dev/null -gcflags="all=-m -m" 2>&1 | sort | uniq | grep "escapes to heap" | grep " in " >$PROJECT.esc
		;;
	clean)
		run rm -f *_gpp.go $PROJECT $PROJECT.[sS] $PROJECT.esc $PROJECT.test $PROJECT.test.esc c.out cpu.pprof mem.pprof
		run go clean -cache -modcache -testcache
		run rm -rf `go env GOCACHE`
		run rm -rf /tmp/cover*
		;;
	check)
		run $0 $VERBOSITYFLAGS test-race-cover
		run ./$PROJECT.test $@
		;;
	check-bench)
		run $0 $VERBOSITYFLAGS test
		printv ./$PROJECT.test -test.run=^Benchmark -test.bench=.  $@
		GODEBUG=cgocheck=0 ./$PROJECT.test -test.run=^Benchmark -test.bench=. $@ | tee tmp.txt
		benchstat tmp.txt >bench-result.txt
		# rm tmp.txt
		;;
	check-bench-compare)
		run $0 check-bench -test.count=10 -test.bench=$1 | tee after

		git stash >/dev/null
		run $0 check-bench -test.count=10 -test.bench=$1 |tee before
		git stash pop >/dev/null

		OUTPUT=$PROJECT-diff.txt
		printv benchstat before after
		benchstat before after >$OUTPUT
		echo Results saved in $OUTPUT

		rm -f before after
		;;
	check-bench-cpu)
		run $0 $VERBOSITYFLAGS test

		OUTPUT=$PROJECT-cpu.pprof
		run ./$PROJECT.test -test.run=^Benchmark -test.benchmem -test.bench=. -test.cpuprofile=$OUTPUT $@
		echo Results saved in $OUTPUT
		;;
	check-bench-mem)
		run $0 $VERBOSITYFLAGS test

		OUTPUT=$PROJECT-mem.pprof
		run ./$PROJECT.test -test.run=^Benchmark -test.benchmem -test.bench=. -test.memprofile=$OUTPUT $@
		echo Results saved in $OUTPUT
		;;
	check-bench-tracing)
		run $0 $VERBOSITYFLAGS test-tracing
		run ./$PROJECT.test -test.run=^Benchmark -test.benchmem -test.bench=. $@
		;;
	check-cover)
		run $0 $VERBOSITYFLAGS test-race-cover
		run ./$PROJECT.test -test.coverprofile=c.out

		OUTPUT=/tmp/coverage.html
		run go tool cover -html=c.out -o $OUTPUT
		echo Results saved in $OUTPUT

		run rm -f c.out
		;;
	check-msan)
		run $0 $VERBOSITYFLAGS test-msan
		run ./$PROJECT.test
		;;
	disas | disasm | disassembly)
		printv go build $VERBOSITYFLAGS -o /dev/null -gcflags="all=-S"
		go build $VERBOSITYFLAGS -o /dev/null -gcflags="all=-S" >$PROJECT.S 2>&1
		;;
	esc | escape | escape-analysis)
		printv go build $VERBOSITYFLAGS -o /dev/null -gcflags="all=-m -m"
		go build $VERBOSITYFLAGS -o /dev/null -gcflags="all=-m -m" >$PROJECT.esc 2>&1
		;;
	fmt)
		if which goimports >/dev/null; then
			run goimports -l -w *.go
		else
			run gofmt -l -s -w *.go
		fi
		;;
	objdump)
		printv go tool objdump -S $PROJECT
		go tool objdump -S $PROJECT >$PROJECT.s
		;;
	pgo)
		run $0 $VERBOSITYFLAGS test

		printv ./$PROJECT.test -test.run=^Benchmark -test.benchmem -test.bench=. -test.count=10 -test.cpuprofile=$PROJECT-cpu.pprof
		./$PROJECT.test -test.run=^Benchmark -test.benchmem -test.bench=. -test.count=10 -test.cpuprofile=$PROJECT-cpu.pprof | tee before

		run go test $VERBOSITYFLAGS -c -o $PROJECT.test -pgo=$PROJECT-cpu.pprof -vet=off

		printv ./$PROJECT.test -test.run=^Benchmark -test.benchmem -test.bench=. -test.count=10 -test.cpuprofile=tmp.pprof
		./$PROJECT.test -test.run=^Benchmark -test.benchmem -test.bench=. -test.count=10 -test.cpuprofile=tmp.pprof | tee after

		OUTPUT=$PROJECT-diff.txt
		printv benchstat before after
		benchstat before after >$OUTPUT
		echo Results saved in $OUTPUT

		run rm before after tmp.pprof
		;;
	png)
		OUTPUT=/tmp/cpu.png
		run go tool pprof -png $PROJECT-cpu.pprof >$OUTPUT
		echo Results saved in $OUTPUT
		;;
	profiling)
		run go build $VERBOSITYFLAGS -o $PROJECT -ldflags="-X main.BuildMode=Profiling"
		;;
	release)
		run buildISPC -O3
		run go build $VERBOSITYFLAGS -o $PROJECT
		;;
	test)
		run $0 $VERBOSITYFLAGS vet
		run buildISPC -O3
		run go test $VERBOSITYFLAGS -a -c -o $PROJECT.test -vet=off
		;;
	allocs | allocations)
		printv go build $VERBOSITYFLAGS -o /dev/null -gcflags="all=-m -m"
		go test $VERBOSITYFLAGS -c -o /dev/null -gcflags="all=-m -m" 2>&1 | sort | uniq | grep "escapes to heap" >$PROJECT.test.esc
		;;
	test-msan)
		run $0 $VERBOSITYFLAGS vet
		run go test $VERBOSITYFLAGS -c -o $PROJECT.test -vet=off -msan -gcflags="all=-N -l" -tags gofadebug
		;;
	test-race-cover)
		run $0 $VERBOSITYFLAGS vet
		run buildISPC -O0 -g
		run go test $VERBOSITYFLAGS -a -c -o $PROJECT.test -vet=off -cover -gcflags="all=-N -l" -tags gofadebug
		;;
	test-tracing)
		run $0 $VERBOSITYFLAGS vet
		run go test $VERBOSITYFLAGS -c -o $PROJECT.test -vet=off -tags gofatrace
		;;
	tracing)
		run go build $VERBOSITYFLAGS -o $PROJECT -tags gofatrace
		;;
	vet)
		run go vet $VERBOSITYFLAGS -unsafeptr=false
		;;
	*)
		printf "Target '%s' is not supported!\n" $TARGET >&2
		exit 1
		;;
esac

ENDTIME=`now`
ELAPSEDMS=`echo "scale=2; ($ENDTIME-$STARTTIME)/1000000" | bc`

echo Done $TARGET in "$ELAPSEDMS"ms
