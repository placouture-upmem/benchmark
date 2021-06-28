# benchmark

## Introduction

Benchmarks used for my PhD.
These benchmarks was used for the paper "Performance Optimization on big.LITTLE Architectures: A Memory-latency Aware Approach" accepted at LCTES2020.
(https://dl.acm.org/doi/10.1145/3372799.3394370 and https://www.youtube.com/watch?v=5AKBiMU4b1Y)

* microbe_cache is used to characterise the memory hierarchy and its latency (largerly inspired by other projects)

## How-to

Simply clone, build and run:

```
    git clone https://github.com/wwilly/benchmark.git

    # edit `source/create_sequence/create_sequence.c`
    # edit `bench_run.sh`

    cd benchmark
    ./bench_build.sh
    ./bench_run.sh
```

## Prerequisites
* bash
* cmake 3.7+
* gcc/clang
* m4
* parallel
* sudo
* Python 3+
* gnuplot
