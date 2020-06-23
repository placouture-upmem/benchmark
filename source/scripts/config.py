import itertools
import os
import subprocess
import sys

from collections import namedtuple
from class_definitions import *

import utils
from utils import ghz, mhz

# activate odroid-xu3 sensors
# and the control of the thermal chamber
arch_special_config = False

# activate my_stuff in the kernel from the bencher
my_stuff_bencher = False

# whether to export in {logtrace}/{id_run}/my_stuff
my_stuff_export = False

nr_run = 1

time_stress = 0
time_cool_down = 1
time_idle = 1
time_before_benchmark = 2
time_after_benchmark = 2

# to configure thermal chamber
ambient_temperature = [
    25,
]

# configure thermal_limit for kernel thermal trip points
# it is brocken somehow in recent kernel
# TODO: fix it
# we currently simply disable thermal_zoneX action
# ==> be carefull not to burn, rely on thermal critical trip points (120\degC on odroids board)
thermal_limit = [
    100000,
]

fan = [
    # False,
    True,
]

# polling rate for thermal_zoneX polling mode
sampling_rate_temperature = [
    250000000, # 250 ms
]

# currently, all event are synchronized with this polling time
sampling_rate_cpu_usage = [
    # 1000000000, # 1000 ms
    # 500000000, # 500 ms
    120000000, # 120 ms # recomended per kernel ondemand doc
    # 100000000, # 100 ms
    # 10000000, # 10 ms
    # 1000000, # 1 ms
]

def update_bench_id_freq(identifier, cpu_freq, cpu_freq_little, cpu_freq_big, cpu_freq_mem, bench):
    # print(identifier, bench)
    new_args = bench.work.args.format(identifier=str(identifier).zfill(10),
                                      cpu_freq=str(cpu_freq),
                                      cpu_freq_little=str(cpu_freq_little),
                                      cpu_freq_big=str(cpu_freq_big),
                                      cpu_freq_mem=str(cpu_freq_mem))
    return PartialWorkload(bench.name, make_work(bench.work.app,
                                                 args=new_args,
                                                 env=bench.work.env,
                                                 in_pipe=bench.work.in_pipe,
                                                 encode=False,
                                                 nr_threads=bench.work.nr_threads,
                                                 taskset=bench.work.taskset,
                                                 need_sudo=bench.work.need_sudo))

def configure_freq_mem(benchmarks):
    identifier = utils.get_db_current_id() + len(workload_to_do)

    freqs_mem = [
        825000000,
        # 728000000,
        # 633000000,
        # 543000000,
        # 413000000,
        # 275000000,
        # 206000000,
        # 165000000,
    ]
    
    workload_name_extension = ""

    for idx_run in range(nr_run):
        pr = namedtuple("pr", ["ambient_temperature",
                               "thermal_limit",
                               "workload",
                               "sampling_rate_temperature",
                               "sampling_rate_cpu_usage",
                               "fan"])
        for prod_conf in itertools.product(ambient_temperature,
                                           thermal_limit,
                                           benchmarks,
                                           sampling_rate_temperature,
                                           sampling_rate_cpu_usage,
                                           fan):
            meta_configuration = pr._make(prod_conf)

            thermal_governor = "step_wise"
            dvfs_governor = "performance"
            
            dvfs_memory_governor = "performance"
            # dvfs_memory_governor = "simple_ondemand"
            
            dvfs_cpu_governor = [[0, dvfs_governor],
                                 [4, dvfs_governor]]
            
            if (int(meta_configuration.workload.work.taskset, 16) >= int("1", 16)
                and int(meta_configuration.workload.work.taskset, 16) <= int("f", 16)):
                freqs_big = [
                    # 1.0,

                    2.0,

                    # 0.2,
                    # 0.3,
                    # 0.4,
                    # 0.5,
                    # 0.6,
                    # 0.7,
                    # 0.8,
                    # 0.9,
                    # 1.0,
                    # 1.1,
                    # 1.2,
                    # 1.3,
                    # 1.4,
                    # 1.5,
                    # 1.6,
                    # 1.7,
                    # 1.8,
                    # 1.9,
                ]

                freqs_little = [
                    # 1.0,

                    1.4,

                    # 0.2,
                    # 0.3,
                    # 0.4,
                    # 0.5,
                    # 0.6,
                    # 0.7,
                    # 0.8,
                    # 0.9,
                    # 1.0,
                    # 1.1,
                    # 1.2,
                    # 1.3,
                ]

                for freq_mem in freqs_mem:
                    for freq_little in freqs_little:
                        for freq_big in freqs_big:
                            n_bench = update_bench_id_freq(identifier, ghz(freq_little), ghz(freq_little),
                                                           ghz(freq_big), freq_mem, meta_configuration.workload)
                            bench_config = Workload(identifier,
                                                    n_bench.name + workload_name_extension,
                                                    n_bench.work,
                                                    make_environment(ambient_temperature=meta_configuration.ambient_temperature,
                                                                     dvfs_cpu_governor=dvfs_cpu_governor,
                                                                     dvfs_cpu_max_frequency=[[0, ghz(freq_little)],
                                                                                             [4, ghz(freq_big)]],
                                                                     dvfs_memory_governor=dvfs_memory_governor,
                                                                     dvfs_memory_frequency=freq_mem,
                                                                     thermal_governor=thermal_governor,
                                                                     trip_point_temperature=meta_configuration.thermal_limit,
                                                                     sampling_rate_temperature=meta_configuration.sampling_rate_temperature,
                                                                     sampling_rate_cpu_usage=meta_configuration.sampling_rate_cpu_usage,
                                                                     fan=meta_configuration.fan))
                            workload_to_do.append(bench_config)
                            identifier = identifier + 1

            elif (int(meta_configuration.workload.work.taskset, 16) >= int("10", 16)
                and int(meta_configuration.workload.work.taskset, 16) <= int("f0", 16)):

                freqs_big = [
                    # 1.0,

                    2.0,

                    # 0.2,
                    # 0.3,
                    # 0.4,
                    # 0.5,
                    # 0.6,
                    # 0.7,
                    # 0.8,
                    # 0.9,
                    # 1.0,
                    # 1.1,
                    # 1.2,
                    # 1.3,
                    # 1.4,
                    # 1.5,
                    # 1.6,
                    # 1.7,
                    # 1.8,
                    # 1.9,
                ]

                freqs_little = [
                    # 1.0,

                    1.4,

                    # 0.2,
                    # 0.3,
                    # 0.4,
                    # 0.5,
                    # 0.6,
                    # 0.7,
                    # 0.8,
                    # 0.9,
                    # 1.0,
                    # 1.1,
                    # 1.2,
                    # 1.3,
                ]

                for freq_mem in freqs_mem:
                    for freq_little in freqs_little:
                        for freq_big in freqs_big:
                            n_bench = update_bench_id_freq(identifier, ghz(freq_big), ghz(freq_little),
                                                           ghz(freq_big), freq_mem, meta_configuration.workload)
                            bench_config = Workload(identifier,
                                                    n_bench.name + workload_name_extension,
                                                    n_bench.work,
                                                    make_environment(ambient_temperature=meta_configuration.ambient_temperature,
                                                                     dvfs_cpu_governor=dvfs_cpu_governor,
                                                                     dvfs_cpu_max_frequency=[[0, ghz(freq_little)],
                                                                                             [4, ghz(freq_big)]],
                                                                     dvfs_memory_governor=dvfs_memory_governor,
                                                                     dvfs_memory_frequency=freq_mem,
                                                                     thermal_governor=thermal_governor,
                                                                     trip_point_temperature=meta_configuration.thermal_limit,
                                                                     sampling_rate_temperature=meta_configuration.sampling_rate_temperature,
                                                                     sampling_rate_cpu_usage=meta_configuration.sampling_rate_cpu_usage,
                                                                     fan=meta_configuration.fan))
                            workload_to_do.append(bench_config)
                            identifier = identifier + 1

    return

all_workload = []

from config_binary_microbe_cache import bench_workloads
all_workload.extend(bench_workloads)

workload_to_do = []

utils.check_or_create()

configure_freq_mem(all_workload)
