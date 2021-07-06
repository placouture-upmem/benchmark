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

nr_accesses=(
    1
    2
)

sequence_sizes=(
    2097152
)

benchs=()

for nr_access in ${nr_accesses[@]}
do
    for sequence_size in ${sequence_sizes[@]}
    do
	for stride in 1 16 0
	do
	    _bench="10000000 1"
	    for ((i=1; i <= ${nr_access}; i++))
	    do
		_bench+=" ${ROOT_DIR}/benchmark_install/input/sequence/sequence_${sequence_size}/sequence_${sequence_size}_${stride}_1.bin"
	    done
	    benchs+=("microbe_cache_local_iterator_${nr_access} ${_bench}")
	done

	_bench="10000000 1"
	for ((i=1; i <= ${nr_access}; i++))
	do
	    _bench+=" ${ROOT_DIR}/benchmark_install/input/sequence/sequence_${sequence_size}/sequence_${sequence_size}_0_0.bin"
	done
	benchs+=("microbe_cache_local_iterator_${nr_access} ${_bench}")
    done
done

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
			config_bench+=("${id_run} ${mf} ${lf} ${bf} ${taskmap} ${freq} ${bench}")
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
			config_bench+=("${id_run} ${mf} ${lf} ${bf} ${taskmap} ${freq} ${bench}")
			id_run=$((id_run + 1))
		done
	    done
	done
    done
done

printf "%s\n" "${config_bench[@]}" > ${LOGTRACE_DIR}/configuration.txt
