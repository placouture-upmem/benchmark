from collections import namedtuple

BUILD = True

Environment = namedtuple("Environment",
                         ["ambient_temperature",
                          "thermal_governor",
                          "trip_point_profile",
                          "trip_point_temperature",
                          "sampling_rate_temperature",
                          "sampling_rate_cpu_usage",
                          "dvfs_cpu_governor",
                          "dvfs_cpu_max_frequency",
                          "dvfs_memory_governor",
                          "dvfs_memory_frequency",
                          "fan"])

Work = namedtuple("Work",
                  ["app", "args", "env", "in_pipe",
                   "nr_threads", "taskset", "need_sudo"])

PartialWorkload = namedtuple("PartialWorkload",
                             ["name", "work"])

Workload = namedtuple("Workload",
                      ["identifier", "name", "work", "environment"])

ThermalManager = namedtuple("ThermalManager",
                            ["name", "thermal_governor", "binary_name"])

def make_work(binary, args="", env={}, in_pipe="", encode=True,
              nr_threads=1, taskset="f", need_sudo=False):
    return Work(binary, args, env, in_pipe.encode("utf-8") if encode else in_pipe,
                nr_threads, taskset, need_sudo)

def make_environment(ambient_temperature=30,
                     thermal_governor="step_wise",
                     trip_point_profile="simple_polling",
                     trip_point_temperature=85,
                     sampling_rate_temperature=500000000,
                     sampling_rate_cpu_usage=500000000,
                     dvfs_cpu_governor=[[0, "performance"], [4, "performance"]],
                     dvfs_cpu_max_frequency=[[0, 1400000], [4, 2000000]],
                     dvfs_memory_governor="performance",
                     dvfs_memory_frequency=825000000,
                     fan=True):
    return Environment(ambient_temperature,
                       thermal_governor,
                       trip_point_profile,
                       trip_point_temperature,
                       sampling_rate_temperature,
                       sampling_rate_cpu_usage,
                       dvfs_cpu_governor,
                       dvfs_cpu_max_frequency,
                       dvfs_memory_governor,
                       dvfs_memory_frequency,
                       fan)
