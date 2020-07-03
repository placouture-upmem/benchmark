#!/bin/bash

set -e

sudo bash -c "echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
sudo bash -c "echo performance > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor"

little_freq=`cat /sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq`
big_freq=`cat /sys/devices/system/cpu/cpufreq/policy4/scaling_cur_freq`

sudo bash -c "echo simple_ondemand > /sys/class/devfreq/10c20000.memory-controller/governor"

mem_gov=`cat /sys/class/devfreq/10c20000.memory-controller/governor`
mem_freq=`cat /sys/class/devfreq/10c20000.memory-controller/cur_freq`

printf "\n\nmem_gov = ${mem_gov} at ${mem_freq}\n\n"

cat /sys/class/devfreq/10c20000.memory-controller/trans_stat

printf "\n\n Running on the LITTLE cluster\n\n"
taskset 8 ./bench_install/bin/microbe_cache 33554431 0 9722222 1 ${little_freq}

printf "\n\n Running on the big cluster\n\n"
taskset 80 ./bench_install/bin/microbe_cache 33554431 0 9722222 1 ${big_freq}

cat /sys/class/devfreq/10c20000.memory-controller/trans_stat

sudo bash -c "echo performance > /sys/class/devfreq/10c20000.memory-controller/governor"

mem_gov=`cat /sys/class/devfreq/10c20000.memory-controller/governor`
mem_freq=`cat /sys/class/devfreq/10c20000.memory-controller/cur_freq`

printf "\n\nmem_gov = ${mem_gov} at ${mem_freq}\n\n"

cat /sys/class/devfreq/10c20000.memory-controller/trans_stat

printf "\n\n Running on the LITTLE cluster\n\n"
taskset 8 ./bench_install/bin/microbe_cache 33554431 0 9722222 1 ${little_freq}

printf "\n\n Running on the big cluster\n\n"
taskset 80 ./bench_install/bin/microbe_cache 33554431 0 9722222 1 ${big_freq}

cat /sys/class/devfreq/10c20000.memory-controller/trans_stat

sudo bash -c "echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
sudo bash -c "echo ondemand > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor"
sudo bash -c "echo simple_ondemand > /sys/class/devfreq/10c20000.memory-controller/governor"
