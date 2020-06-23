import os

def system_cmd(cmd):
    print(cmd)
    os.system(cmd)
    return

subcmd = []
subcmd.append("echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor")
subcmd.append("echo ondemand > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor")
system_cmd("sudo bash -c \"{}\"".format(" && ".join(subcmd)))

system_cmd("taskset 8 ./bench_install/bin/microbe_cache 33554432 0 9722222 1 1400000")

subcmd = []
subcmd.append("echo ondemandas > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor")
subcmd.append("echo 120000 > /sys/devices/system/cpu/cpufreq/policy0/ondemandas/sampling_rate")
subcmd.append("echo 10000000000 > /sys/devices/system/cpu/cpufreq/policy0/ondemandas/rrq_stall_cycles_factor")
subcmd.append("echo 10000000000 > /sys/devices/system/cpu/cpufreq/policy0/ondemandas/cci_factor")
subcmd.append("echo 10000000000 > /sys/devices/system/cpu/cpufreq/policy0/ondemandas/mem_cycle_factor")

subcmd.append("echo 20689179648 > /sys/devices/system/cpu/cpufreq/policy0/ondemandas/cci_congestion")

subcmd.append("echo ondemandas > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor")
subcmd.append("echo 120000 > /sys/devices/system/cpu/cpufreq/policy4/ondemandas/sampling_rate")
subcmd.append("echo 10000000000 > /sys/devices/system/cpu/cpufreq/policy4/ondemandas/rrq_stall_cycles_factor")
subcmd.append("echo 10000000000 > /sys/devices/system/cpu/cpufreq/policy4/ondemandas/cci_factor")
subcmd.append("echo 10000000000 > /sys/devices/system/cpu/cpufreq/policy4/ondemandas/mem_cycle_factor")

subcmd.append("echo 20689179648 > /sys/devices/system/cpu/cpufreq/policy4/ondemandas/cci_congestion")

system_cmd("sudo bash -c \"{}\"".format(" && ".join(subcmd)))

# system_cmd("sleep 1")
system_cmd("taskset 8 ./bench_install/bin/microbe_cache 33554432 0 9722222 1 1400000")

subcmd = []
subcmd.append("echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor")
subcmd.append("echo ondemand > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor")
system_cmd("sudo bash -c \"{}\"".format(" && ".join(subcmd)))
