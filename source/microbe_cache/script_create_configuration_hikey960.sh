#!/bin/bash

ROOT_DIR=`pwd`

LOGTRACE_NAME=stress
LOGTRACE_DIR=${ROOT_DIR}/logtrace/${LOGTRACE_NAME}

mkdir -p ${LOGTRACE_DIR}

config_bench=()

if [ -f "${LOGTRACE_DIR}/current_id" ]
then
    id_run=`cat ${LOGTRACE_DIR}/current_id`
else
    id_run=1
fi

nr_run=1

# no class/devfreq for memory
# cat /sys/kernel/debug/clk/\"clk-ddrc\"/clk_rate
mem_freq=(
    # 1866000000
    # 1244000000
    # 830000000
    # 415000000

    685000000
)

# cat /sys/devices/system/cpu/cpufreq/policy0/scaling_available_frequencies
little_freq=(
    1844000
    # 1709000
    # 1402000
    # 999000
    # 533000
)

# cat /sys/devices/system/cpu/cpufreq/policy4/scaling_available_frequencies
big_freq=(
    2362000
    # 2112000
    # 1805000
    # 1421000
    903000
)

taskmap=0x08

benchs=()

bench_args=(
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_1_1.bin 166666666 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_8_1.bin 166666666 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_0_1.bin 166666666 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_0_0.bin 166666666 1"
)

for nr_access in {1..1}
do
    for bench_arg in "${bench_args[@]}"
    do
        benchs+=("microbe_cache_local_iterator_${nr_access} ${bench_arg}")
    done
done

for mf in "${mem_freq[@]}"
do
    for lf in "${little_freq[@]}"
    do
	for bf in "${big_freq[@]}"
	do
	    for bench in "${benchs[@]}"
	    do
		for idx_run in $(seq 1 ${nr_run})
		do
			freq=$lf
			config_bench+=("${id_run} ${mf} ${lf} ${bf} ${taskmap} ${bench} ${freq}")
			id_run=$((id_run + 1))
		done
	    done
	done
    done
done






little_freq=(
    1844000
    # 1709000
    # 1402000
    # 999000
    533000
)

big_freq=(
    2362000
    # 2112000
    # 1805000
    # 1421000
    # 903000
)

taskmap=0x80

benchs=()

bench_args=(
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_1_1.bin 625000000 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_8_1.bin 625000000 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_0_1.bin 625000000 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_0_0.bin 625000000 1"
)

for nr_access in {1..1}
do
    for bench_arg in "${bench_args[@]}"
    do
        benchs+=("microbe_cache_local_iterator_${nr_access} ${bench_arg}")
    done
done

for mf in "${mem_freq[@]}"
do
    for lf in "${little_freq[@]}"
    do
	for bf in "${big_freq[@]}"
	do
	    for bench in "${benchs[@]}"
	    do
		for idx_run in $(seq 1 ${nr_run})
		    do
			freq=$bf
			config_bench+=("${id_run} ${mf} ${lf} ${bf} ${taskmap} ${bench} ${freq}")
			id_run=$((id_run + 1))
		done
	    done
	done
    done
done

printf "%s\n" "${config_bench[@]}" > ${LOGTRACE_DIR}/configuration.txt
