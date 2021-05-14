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
    cd benchmark
    ./bench_build.sh
    ./bench_run.sh
```

Scripts used freely the `sudo` command to force CPU/GPU/other frequencies and DVFS governors. To automate everything smoothly, you could allow using sudo without password for the user.

The current project version is appropriate to run on the HardKernel Odroid-XU{3,4} board running Debian 10 with a standard Linux kernel >= 5.11.y

## Prerequisites
* bash
* cmake 3.13+
* gcc/clang
* m4
* sudo
* Python 3+
* gnuplot
