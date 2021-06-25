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

taskmap=0x2

benchs=()

bench_args=(
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_1_1.bin 1000000000 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_8_1.bin 1000000000 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_0_1.bin 1000000000 1"
    "${ROOT_DIR}/benchmark_install/input/sequence/sequence_33554432/sequence_33554432_0_0.bin 1000000000 1"
)

for nr_access in {1..1}
do
    for bench_arg in "${bench_args[@]}"
    do
	benchs+=("microbe_cache_local_iterator_${nr_access} ${bench_arg}")
    done
done

for bench in "${benchs[@]}"
do
    for idx_run in $(seq 1 ${nr_run})
    do
	freq=1
	config_bench+=("${id_run} ${taskmap} ${bench} ${freq}")
	id_run=$((id_run + 1))
    done
done

printf "%s\n" "${config_bench[@]}" > ${LOGTRACE_DIR}/configuration.txt
