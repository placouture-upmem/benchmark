#!/bin/bash

set -e
set -x

while getopts "c" o; do
    case "${o}" in
        c)
            echo "Clean folder."
            rm -rf ${BENCH_BUILD_DIR} ${BENCH_INSTALL_DIR}
            ;;
    esac
done

# CC=gcc
# CXX=g++

# CC=clang
# CXX=clang++

# on odroid-xu{3,4} f0 is the big cluster
PREFIX_CMD="taskset f0"
NR_THREADS=4

> cmake_dynamic_benchmark_list.txt

if [ $REMOTE_SOURCE = true ]
then
    sudo mkdir -p /media/Projects/
    trap "fusermount -qu /media/Projects/" EXIT
    sshfs -o cache=no,allow_other,StrictHostKeyChecking=no,ro willy@project-node:${PATH_PROJECT} /media/Projects/
fi

(
    mkdir -p ${BENCH_BUILD_DIR}
    cd ${BENCH_BUILD_DIR}

    CC=${CC} CXX=${CXX} \
      ${PREFIX_CMD} cmake ${SOURCE_DIR} \
      -DCMAKE_INSTALL_PREFIX=${BENCH_INSTALL_DIR}

    ${PREFIX_CMD} make -k -j${NR_THREADS} VERBOSE=1

    ${PREFIX_CMD} make -k -j${NR_THREADS} VERBOSE=1 install
)

mkdir -p ${LOGTRACE_DIR}
touch ${LOGTRACE_DIR}/data.db

python3 ${BENCH_INSTALL_DIR}/scripts/bench_build.py
${PREFIX_CMD} make -k -j${NR_THREADS} VERBOSE=1 -C ${BENCH_BUILD_DIR}
${PREFIX_CMD} make -k -j${NR_THREADS} VERBOSE=1 -C ${BENCH_BUILD_DIR} install
