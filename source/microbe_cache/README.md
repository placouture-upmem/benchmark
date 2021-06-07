# microbe_cache

## Introduction

This microbenchmark is useful to discover cache hierarchy and its latency.
The benchmark do a pointer chasing over an array. The array is initialised to perform a sequential access with a parametrised stride (stide >= 1), or a random pattern (stride = 0). The random pattern is generated using either Gray code or an LSFR pseudo random number generator defined at compile time. With a random pattern, the array is accessed such as each cache line is touched only once within a memory page, then pass to the next page and so on.

There are multiple version of the benchmark:

```microbe_cache_local_iterator_X``` : access ```X``` different arrays, each has its own allocator. Iterators are local to the function, hence uses the stack. You can set ```X``` to fit in registers. If there are not enough registers, there will be stores/loads on the stack to manage the iterator.

```microbe_cache_global_iterator_X``` : access ```X``` different arrays, each has its own allocator. Iterators are in the global scope (.dss). There will be most probably stores/loads to manage iterators.

```microbe_cache_<location>_iterator_T_X``` : same as before, but with ```T``` threads. Be carefull about <array_size> parameter, as each single array has its own allocator. Set their sizes as to have them all fitting in the RAM to not swap. Threading is implemented with ```pthread```.

## Run the benchmark

The input of the benchmark is:
```
./microbe_cache_local_iterator_1 <array_size> <stride> <nr_iter_1> <nr_iter_2> <cpu_freq:KHz> <directory_to_put_results> <id_run>"
```
It's preferable to run this benchmark at a constant frequency for the CPU (fix `performance` governor for `cpufreq`).

It's nice to fix `nr_iter_1` to run the benchmark for 1s, and use `nr_iter_2` as a multiplier.
`directory_to_put_results` must be present, and `id_run` is just to make life easier for the analyser.

`script_odroid_xu3.sh` is tailored for the Hardkernel Odroid-XU{3,4} board and will run the benchmark for different "interesting" array size, and scanning different CPU/mem frequencies.

## Results

The output shows different information:
```
array_size rounded to fit a CACHE_LINE_SIZE from 33554432 to 33554448
sizeof(size_t) = 4
array_size = 33554448
==> 134217792 b; 131072 Kb; 128 Mb
stride = 0
nr_iter = 8161932
nr_iter_2 = 10
effective_nr_iter = 81619320
cpu_freq = 1400000
==> 1.4 GHz; 1400 MHz; 1400000 KHz
print to cut optimisation 30840448
total time = 9779478210 ns; 9.77948 s
time per iter 119.818 ns
estimated cycles per iter 167.745 c

Timing depends on the memory allocator, CPUs and memory frequency, system busyness, number of iterations, etc...
Set the number of iteration to run for at least a few seconds.
Run multiple times before making any conclusion.
```

A `summary.csv` file is created in `directory_to_put_results` which gather benchmark configuration and results of the execution.

`script_odroid_xu3.sh` gather other useful information in `directory_to_put_results/id_run`

## Building
The file `microbe_cache.c.m4` is used to create multiple version of the benchmark.
* `-DACCESS_REQ=${x}` is used to create x consecutive access to x different array. Each array has their own memory allocator.
* `-DUNROLL=${unroll_factor}` is the loop unroll factor for the critical loop. Be careful with this variable. It is used to maximise the number of memory access against loop iterator calculation and branch instruction. It's nice to have the assembly code fitting in the instruction cache to not cache miss on it. To cope with different compilers and their options on the topic, the loop is unrolled manually.

The generated .c file has different compilation definition.
* `-DCACHE_LINE_SIZE=64` is the hardware data cache line size. `getconf LEVEL1_DCACHE_LINESIZE`
* `-DPAGE_SIZE=4096` is the kernel defined memory page size. `getconf PAGE_SIZE`
* `-DLOCAL_ITERATOR` or `-DGLOBAL_ITERATOR` is used to have the iterator placed in either the local scope of the function (stack), or as a global (.data). With a local allocation, you could end up with only load instruction, and with a global allocation, you will probably have some store instruction. This compiler definition is helpful to stress (a bit) in-order/out-of-order pipeline and write-back stage.

See `CMakeLists.txt`, `microbe_cache.c.m4` and `microbe_cache_threaded.c.m4` for more detail.
To control the build, you can specify different parameters at the top of the `CMakeLists.txt`. See `nr_thread`, `nr_access_req`, `unroll_factor`, `optim`.
