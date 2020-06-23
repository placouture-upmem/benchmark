#!/bin/bash

set -e
set -x

> cmake_dynamic_benchmark_list.txt
${ROOT_DIR}/bench_build.sh

while getopts "c" o; do
    case "${o}" in
        c)
            echo "Clean folder."

	    ssh -t ${REMOTE_USER}@${REMOTE_IP} "rm -rf ${REMOTE_PATH}"
	    ssh -t ${REMOTE_USER}@${REMOTE_IP} "mkdir ${REMOTE_PATH}"

	    rm -rf ${LOGTRACE_DIR}/
	    mkdir ${LOGTRACE_DIR}/
            ;;
    esac
done

${BENCH_INSTALL_DIR}/scripts/bench_run.py --no-backup # --show --estimation 
