import itertools

import numpy as np

import os

from class_definitions import *

if BUILD:
    with open("cmake_dynamic_benchmark_list.txt", "a+") as fd:
        fd.write("add_subdirectory(microbe_cache/)\n")

bench_workloads = []

cmd_args = "{size} {pattern} {nr_iter} {nr_iter_2} {cpu_freq}"

configuration = [

    [["8", 1], "microbe_cache", 33554432, 0, 9722222, 10],
    [["80", 1], "microbe_cache", 33554432, 0, 9090909, 10],

    # [["8", 1], "microbe_cache", 33554432, 16, 9333333, 10],
    # [["80", 1], "microbe_cache", 33554432, 16, 8928571, 10],

    # [["8", 1], "microbe_cache", 33554432, 1, 116666666, 10],
    # [["80", 1], "microbe_cache", 33554432, 1, 333333333, 10],

    ###
    
    # [[ "8", 1], "microbe_cache", 1048576, 0, 9722222, 10],
    # [["80", 1], "microbe_cache", 1048576, 0, 10526315, 10],

    # [[ "8", 1], "microbe_cache", 1048576, 16, 9333333, 10],
    # [["80", 1], "microbe_cache", 1048576, 16, 10526315, 10],

    # [[ "8", 1], "microbe_cache", 1048576, 1, 116666666, 10],
    # [["80", 1], "microbe_cache", 1048576, 1, 333333333, 10],

    ###
    
    # [[ "8", 1], "microbe_cache",  163840, 0, 20000000, 10],
    # [["80", 1], "microbe_cache",  163840, 0, 95238095, 10],

    # [[ "8", 1], "microbe_cache",  163840, 16, 20000000, 10],
    # [["80", 1], "microbe_cache",  163840, 16, 95238095, 10],

    # [[ "8", 1], "microbe_cache",  163840, 1, 200000000, 10],
    # [["80", 1], "microbe_cache",  163840, 1, 400000000, 10],

    ###
    
    # [[ "8", 1], "microbe_cache",  131072, 0, 33333333, 10],
    # [["80", 1], "microbe_cache",  131072, 0, 95238095, 10],

    # [[ "8", 1], "microbe_cache",  131072, 16, 33333333, 10],
    # [["80", 1], "microbe_cache",  131072, 16, 95238095, 10],

    # [[ "8", 1], "microbe_cache",  131072, 1, 245614035, 10],
    # [["80", 1], "microbe_cache",  131072, 1, 400000000, 10],

    ###
    
    # [[ "8", 1], "microbe_cache",   65536, 0, 107692307, 10],
    # [["80", 1], "microbe_cache",   65536, 0, 95238095, 10],

    # [[ "8", 1], "microbe_cache",   65536, 16, 93333333, 10],
    # [["80", 1], "microbe_cache",   65536, 16, 95238095, 10],

    # [[ "8", 1], "microbe_cache",  65536, 1, 388888888, 10],
    # [["80", 1], "microbe_cache",  65536, 1, 3610108303, 10],

    ###
    
    # [[ "8", 1], "microbe_cache",       4, 0, 466666666, 10],
    # [["80", 1], "microbe_cache",       4, 0, 500000000, 10],

    # [[ "8", 1], "microbe_cache",       4, 16, 466666666, 10],
    # [["80", 1], "microbe_cache",       4, 16, 500000000, 10],

    # [[ "8", 1], "microbe_cache",       4, 1, 466666666, 10],
    # [["80", 1], "microbe_cache",       4, 1, 500000000, 10],
]


# this two following set configure array size as power of 2
# feel free to use a linear scale instead

# TODO: add more size around cliff size of the memory hierarchy level

# sizes = []

# sizes.extend(np.linspace(pow(2,  4), pow(2, 13), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 12), pow(2, 13), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 13), pow(2, 14), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 14), pow(2, 15), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 15), pow(2, 16), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 16), pow(2, 17), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 17), pow(2, 18), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 18), pow(2, 19), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 19), pow(2, 27), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 27), pow(2, 28), num=10, dtype=int))

# for taskset in ["8", "80"]:
#     for size in sizes:
#         for stride in [0]:
#             kb_size = (size * 4) / 1024

#             if int(taskset, 16) >= int("1", 16) and int(taskset, 16) <= int("f", 16):
#                 nr_iter_1 = 466666666
#                 nr_iter_2 = 10
                
#                 if kb_size >= 32:
#                     nr_iter_1 = 107692307
#                     nr_iter_2 = 10
#                 if kb_size >= 512:
#                     nr_iter_1 = 9722222
#                     nr_iter_2 = 10
                    
#             if int(taskset, 16) >= int("10", 16) and int(taskset, 16) <= int("f0", 16):
#                 nr_iter_1 = 500000000
#                 nr_iter_2 = 10
#                 if kb_size >= 32:
#                     nr_iter_1 = 95238095
#                     nr_iter_2 = 10
#                 if kb_size >= 2048:
#                     nr_iter_1 = 9090909
#                     nr_iter_2 = 10

#             # nr_iter_2 = 1
#             configuration.append([[taskset, 1], "microbe_cache", size, stride, nr_iter_1, nr_iter_2])

# sizes = []

# sizes.extend(np.linspace(pow(2,  4), pow(2, 13), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 12), pow(2, 13), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 13), pow(2, 14), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 14), pow(2, 15), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 15), pow(2, 16), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 16), pow(2, 17), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 17), pow(2, 18), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 18), pow(2, 19), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 19), pow(2, 27), num=10, dtype=int))
# sizes.extend(np.linspace(pow(2, 27), pow(2, 28), num=10, dtype=int))

# for taskset in ["8", "80"]:
#     for size in sizes:
#         for stride in [1, 16]:   
#             kb_size = (size * 4) / 1024

#             if int(taskset, 16) >= int("1", 16) and int(taskset, 16) <= int("f", 16):
#                 nr_iter_1 = 466666666
#                 nr_iter_2 = 10
                
#                 if kb_size >= 32:
#                     nr_iter_1 = 107692307
#                     nr_iter_2 = 10
#                 if kb_size >= 512:
#                     nr_iter_1 = 9722222
#                     nr_iter_2 = 10
                    
#             if int(taskset, 16) >= int("10", 16) and int(taskset, 16) <= int("f0", 16):
#                 nr_iter_1 = 500000000
#                 nr_iter_2 = 10
#                 if kb_size >= 32:
#                     nr_iter_1 = 95238095
#                     nr_iter_2 = 10
#                 if kb_size >= 2048:
#                     nr_iter_1 = 9090909
#                     nr_iter_2 = 10

#             # nr_iter_2 = 1
#             configuration.append([[taskset, 1], "microbe_cache", size, stride, nr_iter_1, nr_iter_2])


for conf in itertools.product(configuration):
    benchname = "microbe_cache"
    workload_name = benchname
    taskset = conf[0][0][0]
    
    app_binary = os.path.join(os.environ["BENCH_INSTALL_DIR"], "bin", benchname)
    app_args = cmd_args.format(size=conf[0][2],
                               pattern=conf[0][3],
                               nr_iter=conf[0][4],
                               nr_iter_2=conf[0][5],
                               cpu_freq="{cpu_freq}")
    
    bench_workloads.append(PartialWorkload(workload_name,
                                           make_work(app_binary,
                                                     app_args,
                                                     taskset = taskset)))
