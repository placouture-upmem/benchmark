#!/bin/bash

# set -e
# set -x

function normal_config()
{
    echo "set normal_config"

    sudo bash -c "echo 0 > /sys/devices/virtual/thermal/cooling_device0/cur_state"
    sudo bash -c "echo 0 > /sys/devices/virtual/thermal/cooling_device1/cur_state"
    sudo bash -c "echo 0 > /sys/devices/virtual/thermal/cooling_device2/cur_state"
    sudo bash -c "echo 0 > /sys/devices/virtual/thermal/cooling_device3/cur_state"

    sudo bash -c "echo schedutil > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
    sudo bash -c "echo 1400000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
    sudo bash -c "echo schedutil > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor"
    sudo bash -c "echo 2000000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq"

    sudo bash -c "echo simple_ondemand > /sys/class/devfreq/10c20000.memory-controller/governor"
    sudo bash -c "echo simple_ondemand > /sys/class/devfreq/11800000.gpu/governor"
    sudo bash -c "echo simple_ondemand > /sys/class/devfreq/soc:bus-wcore/governor"
}

function sigint_fct()
{
    normal_config

    exit
}

function err_fct()
{
    echo "ERROR somewhere"

    normal_config

    exit
}
trap sigint_fct SIGINT
trap err_fct ERR

function run_benchmark()
{
    (
	echo ${id_run} > ${LOGTRACE_DIR}/current_id

	mkdir -p ${LOGTRACE_DIR}/${id_run}
	cd ${LOGTRACE_DIR}/${id_run}

	set -- $config

	echo "${lf},${bf},${mf},${taskmap} ${config}"
	echo "${id_run},${bench},$1,$2,$3,$4,${lf},${bf},${mf},${taskmap}" > configuration.csv

	sudo bash -c "echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
	sudo bash -c "echo ${lf} > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
	sudo bash -c "echo performance > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor"
	sudo bash -c "echo ${bf} > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq"
	sudo bash -c "echo performance > /sys/class/devfreq/10c20000.memory-controller/governor"
	sudo bash -c "echo ${mf} > /sys/class/devfreq/10c20000.memory-controller/max_freq"

	sudo dmesg -c > before_dmesg.txt

	for cpufreq in `ls --color=auto -d /sys/devices/system/cpu/cpufreq/policy*`
	do
	    name=`basename ${cpufreq}`
	    sudo bash -c "echo \"\" > ${cpufreq}/stats/reset"
	    cat ${cpufreq}/stats/trans_table > before_${name}.txt
	done

	for cdev in `ls --color=auto -d /sys/devices/virtual/thermal/cooling_device*`
	do
	    name=`basename ${cdev}`
	    sudo bash -c "echo \"\" > ${cdev}/stats/reset"
	    cat ${cdev}/stats/trans_table > before_${name}.txt
	done

	sudo bash -c "echo \"0\" > /sys/class/devfreq/10c20000.memory-controller/trans_stat"
	cat /sys/class/devfreq/10c20000.memory-controller/trans_stat > before_memory_controller.txt

	sudo bash -c "echo \"0\" > /sys/class/devfreq/11800000.gpu/trans_stat"
	cat /sys/class/devfreq/11800000.gpu/trans_stat > before_gpu.txt

	sudo bash -c "echo \"0\" > /sys/class/devfreq/soc\:bus-wcore/trans_stat"
	cat /sys/class/devfreq/soc\:bus-wcore/trans_stat > before_gpu.txt

	taskset ${taskmap} ${ROOT_DIR}/bench_install/bin/${bench} $1 $2 $3 $4 $freq ${LOGTRACE_DIR} ${id_run} > output.txt

	sudo dmesg -c > after_dmesg.txt

	for cpufreq in `ls --color=auto -d /sys/devices/system/cpu/cpufreq/policy*`
	do
	    name=`basename ${cpufreq}`
	    cat ${cpufreq}/stats/trans_table > after_${name}.txt
	done

	for cdev in `ls --color=auto -d /sys/devices/virtual/thermal/cooling_device*`
	do
	    name=`basename ${cdev}`
	    cat ${cdev}/stats/trans_table > after_${name}.txt
	done
	cat /sys/class/devfreq/10c20000.memory-controller/trans_stat > after_memory_controller.txt
	cat /sys/class/devfreq/11800000.gpu/trans_stat > after_gpu.txt
	cat /sys/class/devfreq/soc\:bus-wcore/trans_stat > after_gpu.txt

	# normal_config
    )
}

sudo bash -c "echo performance > /sys/class/devfreq/soc:bus-wcore/governor"
sudo bash -c "echo performance > /sys/class/devfreq/10c20000.memory-controller/governor"
sudo bash -c "echo performance > /sys/class/devfreq/11800000.gpu/governor"

FAN_LEVEL=3
sudo bash -c "echo ${FAN_LEVEL} > /sys/devices/virtual/thermal/cooling_device0/cur_state"
sudo bash -c "echo 0 > /sys/devices/virtual/thermal/cooling_device1/cur_state"
sudo bash -c "echo 0 > /sys/devices/virtual/thermal/cooling_device2/cur_state"
sudo bash -c "echo 0 > /sys/devices/virtual/thermal/cooling_device3/cur_state"

ROOT_DIR=`pwd`
LOGTRACE_DIR=`pwd`/logtrace

mkdir -p ${LOGTRACE_DIR}

if test -f "${LOGTRACE_DIR}/current_id"; then
    id_run=`cat ${LOGTRACE_DIR}/current_id`
    id_run=$((id_run+1))
else
    echo "id,bin,array_size,stride,nr_iter,cpu_freq,duration,time_per_iter,cycles_per_iter" > ${LOGTRACE_DIR}/summary.csv
    id_run=1
fi

nr_run=1

benchs=(
    microbe_cache_local_iterator_1
    microbe_cache_local_iterator_2
    # microbe_cache_local_iterator_3
    # microbe_cache_local_iterator_4
    # microbe_cache_local_iterator_5
    # microbe_cache_local_iterator_6
    # microbe_cache_local_iterator_7
    # microbe_cache_local_iterator_8
    # microbe_cache_local_iterator_9
    # microbe_cache_local_iterator_10
    # microbe_cache_local_iterator_11
    # microbe_cache_local_iterator_12

    microbe_cache_local_iterator_1_1
    microbe_cache_local_iterator_1_2
    # microbe_cache_local_iterator_1_3
    # microbe_cache_local_iterator_1_4
    # microbe_cache_local_iterator_1_5
    # microbe_cache_local_iterator_1_6
    # microbe_cache_local_iterator_1_7

    microbe_cache_local_iterator_2_1
    microbe_cache_local_iterator_2_2
    # microbe_cache_local_iterator_2_3
    # microbe_cache_local_iterator_2_4
    # microbe_cache_local_iterator_2_5
    # microbe_cache_local_iterator_2_6
    # microbe_cache_local_iterator_2_7

    microbe_cache_local_iterator_3_1
    microbe_cache_local_iterator_3_2
    # microbe_cache_local_iterator_3_3
    # microbe_cache_local_iterator_3_4
    # microbe_cache_local_iterator_3_5
    # microbe_cache_local_iterator_3_6
    # microbe_cache_local_iterator_3_7

    microbe_cache_local_iterator_4_1
    microbe_cache_local_iterator_4_2
    # microbe_cache_local_iterator_4_3
    # microbe_cache_local_iterator_4_4
    # microbe_cache_local_iterator_4_5
    # microbe_cache_local_iterator_4_6
    # microbe_cache_local_iterator_4_7

    microbe_cache_global_iterator_1
    microbe_cache_global_iterator_2
    # microbe_cache_global_iterator_3
    # microbe_cache_global_iterator_4
    # microbe_cache_global_iterator_5
    # microbe_cache_global_iterator_6
    # microbe_cache_global_iterator_7
    # microbe_cache_global_iterator_8
    # microbe_cache_global_iterator_9
    # microbe_cache_global_iterator_10
    # microbe_cache_global_iterator_11
    # microbe_cache_global_iterator_12

    microbe_cache_global_iterator_1_1
    microbe_cache_global_iterator_1_2
    # microbe_cache_global_iterator_1_3
    # microbe_cache_global_iterator_1_4
    # microbe_cache_global_iterator_1_5
    # microbe_cache_global_iterator_1_6
    # microbe_cache_global_iterator_1_7

    microbe_cache_global_iterator_2_1
    microbe_cache_global_iterator_2_2
    # microbe_cache_global_iterator_2_3
    # microbe_cache_global_iterator_2_4
    # microbe_cache_global_iterator_2_5
    # microbe_cache_global_iterator_2_6
    # microbe_cache_global_iterator_2_7

    microbe_cache_global_iterator_3_1
    microbe_cache_global_iterator_3_2
    # microbe_cache_global_iterator_3_3
    # microbe_cache_global_iterator_3_4
    # microbe_cache_global_iterator_3_5
    # microbe_cache_global_iterator_3_6
    # microbe_cache_global_iterator_3_7

    microbe_cache_global_iterator_4_1
    microbe_cache_global_iterator_4_2
    # microbe_cache_global_iterator_4_3
    # microbe_cache_global_iterator_4_4
    # microbe_cache_global_iterator_4_5
    # microbe_cache_global_iterator_4_6
    # microbe_cache_global_iterator_4_7
)

mem_freq=(
    825000000
    # 728000000
    # 633000000
    # 543000000
    # 413000000
    # 275000000
    # 206000000
    # 165000000
)

######### on little
little_freq=(
    1400000
    # 1300000
    # 1200000
    # 1100000
    # 1000000
    # 900000
    # 800000
    # 700000
    # 600000
    # 500000
    # 400000
    # 300000
    # 200000
)

big_freq=(
    2000000
    # 1900000
    # 1800000
    # 1700000
    # 1600000
    # 1500000
    # 1400000
    # 1300000
    # 1200000
    # 1100000
    # 1000000
    # 900000
    # 800000
    # 700000
    # 600000
    # 500000
    # 400000
    # 300000
    # 200000
)

configuration_little=(
    "16777216 0 8161932 10"

    # "33554432 0 8161932 10"
    # "1048576 0 8161932 10"
    # "160100 0 23402925 10"
    # "131072 0 44793033 10"
    # "65536 0 104767332 10"
    # "4 0 463492975 10"
)

taskmap=0x0f

for bench in "${benchs[@]}"
do
    for mf in "${mem_freq[@]}"
    do
	for lf in "${little_freq[@]}"
	do
	    for bf in "${big_freq[@]}"
	    do
		#######
		for config in "${configuration_little[@]}"
		do
		    for idx_run in $(seq 1 ${nr_run})
		    do
			freq=$lf
			run_benchmark
			id_run=$((id_run + 1))
		    done
		done
	    done
	done
    done
done

########### on big
little_freq=(
    1400000
    # 1300000
    # 1200000
    # 1100000
    # 1000000
    # 900000
    # 800000
    # 700000
    # 600000
    # 500000
    # 400000
    # 300000
    # 200000
)

big_freq=(
    2000000
    # 1900000
    # 1800000
    # 1700000
    # 1600000
    # 1500000
    # 1400000
    # 1300000
    # 1200000
    # 1100000
    # 1000000
    # 900000
    # 800000
    # 700000
    # 600000
    # 500000
    # 400000
    # 300000
    # 200000
)

configuration_big=(
    "16777216 0 8161932 10"

    # "33554432 0 8161932 10"
    # "1048576 0 9555113 10"
    # "160100 0 88541805 10"
    # "131072 0 88541805 10"
    # "65536 0 88541805 10"
    # "4 0 496571176 10"
)

taskmap=0xf0

for bench in "${benchs[@]}"
do
    for mf in "${mem_freq[@]}"
    do
	for lf in "${little_freq[@]}"
	do
	    for bf in "${big_freq[@]}"
	    do
		for config in "${configuration_big[@]}"
		do
		    for idx_run in $(seq 1 ${nr_run})
		    do
			freq=$bf
			run_benchmark
			id_run=$((id_run + 1))
		    done
		done
	    done
	done
    done
done

normal_config
