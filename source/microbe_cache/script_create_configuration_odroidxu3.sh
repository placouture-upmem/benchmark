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

nr_run=3

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
    200000
)

taskmap=0x08

benchs=()

bench_args=(
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_2097152/sequence_2097152_1_1.bin 8161932 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_2097152/sequence_2097152_16_1.bin 8161932 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_2097152/sequence_2097152_0_1.bin 8161932 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_2097152/sequence_2097152_0_0.bin 8161932 1"
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
    200000
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

taskmap=0x80

benchs=()

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
