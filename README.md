# benchmarks

## Introduction

Benchmarks used for my PhD.
These benchmarks was used for the paper "Performance Optimization on big.LITTLE Architectures: A Memory-latency Aware Approach accepted" at LCTES2020.
(https://dl.acm.org/doi/10.1145/3372799.3394370 and https://www.youtube.com/watch?v=5AKBiMU4b1Y)

* microbe_cache is used to caracterise the memory hierarchy and its latency (largerly inspired by other projects)

## How-to

Simply clone source the bash environment:

```
    git clone https://github.com/wwilly/benchmark.git
    cd benchmark
    source env.sh
```

You then have to configure the set of benchmarck you want to run.

Configuration is done `source/scripts/config.py`. The few first variable is self explanatory.
Note that `my_stuff` related variables are used in conjunction with my version of the Linux kernel.

In the function `configure_freq_mem`, you can set a set of DVFS CPU and memory frequencies,
the bencher script `bench_run.sh` will run benchmarks with all these frequencies.

At the end of this file, you can import the benchmark that you want to run.

When you're done with the configuration, you can run with `./bench_run.sh`,
a bunch of print will be shown to track progress.

By default, benchmark results will appear in the `logtrace` directory.
You can provide remote login information in `env.sh` and remove `--no-backup` flag in `bash_run.sh` to use ssh to do a backup of this logtrace to limit disk occupancy.

The result of a run in the `logtrace` directory is organised as follow, indexed by its id:
* `0_stderr.dat`, `0_stdout.dat` and `0_time.dat` is the output of `stderr`, `stdout` command line output channel and the `time` output as the benchmark is run using this (GNU) command line tool
* `dmesg_0.txt` and `dmest_1.txt` is the output of `dmesg` command line before and after the benchmark
* `output` directory is used for the produced files of the benchmark
* `pickle` related files are the benchmark python configuration pickled to reuse for the Analyser
* the other files are related to my_stuff kernel version

To automate everything smoothly, you could allow using sudo without password for the user (it's an academic testing project, not an industrial release :) ).

The current project version is appropriate to run on the HardKernel Odroid-XU{3,4} board running Debian 10 with a mainline Linux 5.5.y

## Prerequisites
* Python 3+
* cmake 3.13+
* gcc
* sudo
