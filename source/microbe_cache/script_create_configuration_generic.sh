#!/bin/bash

set -e

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

taskmap=0x2

benchs=()


# cache line stride = CACHE_LINE_SIZE / sizeof(size_t);

# CACHE_LINE_SIZE = 64 and sizeof(size_t) = 4
# cache_line_stride=16

# CACHE_LINE_SIZE = 64 and sizeof(size_t) = 8
cache_line_stride=8

sequence_sizes=(
    1048576
    2097152
)

nr_accesses=(
    1
    2
)

for nr_access in ${nr_accesses[@]}
do
    for sequence_size in ${sequence_sizes[@]}
    do
	for stride in 1 ${cache_line_stride} 0
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

for bench in "${benchs[@]}"
do
    for idx_run in $(seq 1 ${nr_run})
    do
	freq=1
	config_bench+=("${id_run} ${taskmap} ${freq} ${bench}")
	id_run=$((id_run + 1))
    done
done

printf "%s\n" "${config_bench[@]}" > ${LOGTRACE_DIR}/configuration.txt
