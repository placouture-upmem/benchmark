#!/bin/bash

set -e
# set -x

ROOT_DIR=`pwd`

LOGTRACE_NAME=stress
LOGTRACE_DIR=${ROOT_DIR}/logtrace/${LOGTRACE_NAME}

mkdir -p ${LOGTRACE_DIR}

function normal_config()
{
    echo "set normal_config"
}

function exit_fct()
{
    normal_config
}

trap exit_fct EXIT

function run_benchmark()
{
    (
	row_insertion=$(printf "%010d\n" ${id_run})
	if [ -d "${LOGTRACE_DIR}/${row_insertion}" ]
	then
	    rm -rf ${LOGTRACE_DIR}/${row_insertion}
	fi

	mkdir ${LOGTRACE_DIR}/${row_insertion}

	script=$(mktemp)
	echo "#!/bin/bash" > ${script}
	echo "${ROOT_DIR}/benchmark_install/bin/${bench} ${freq} ${LOGTRACE_DIR} ${id_run} ${nr_iter_1} ${nr_iter_2} ${sequence} &" >> ${script}
	echo "echo \$! >> real_pid.txt" >> ${script}
	echo "wait \$!" >> ${script}

	(
	    mkdir ${LOGTRACE_DIR}/${row_insertion}/output
	    cd ${LOGTRACE_DIR}/${row_insertion}/output
	    taskset ${taskmap} /usr/bin/time -v -p bash ${script} > 00_stdout 2> 00_stderr
	)

	mv ${script} ${LOGTRACE_DIR}/${row_insertion}/output/
    )
}

if [ -f "${LOGTRACE_DIR}/current_id" ]
then
    current_id=`cat ${LOGTRACE_DIR}/current_id`
    current_id=$((current_id))
else
    echo "id,bin,array_size,stride,page_stride,nr_iter,cpu_freq,duration,time_per_iter,cycles_per_iter" > ${LOGTRACE_DIR}/summary.csv
    current_id=1
fi

IFS=$'\r\n' GLOBIGNORE='*' command eval  'config_bench=($(cat ${LOGTRACE_DIR}/configuration.txt))'

for line in "${config_bench[@]}"
do
    IFS=' ' read -a split_line <<< "${line}"

    id_run=${split_line[0]}
    if [ ${id_run} -lt ${current_id} ]
    then
	continue
    fi

    # echo ${line}

    taskmap=${split_line[1]}
    freq=${split_line[2]}
    bench=${split_line[3]}
    nr_iter_1=${split_line[4]}
    nr_iter_2=${split_line[5]}
    sequence=${split_line[@]:6}

    echo "${id_run} ${taskmap} ${freq} ${bench} ${nr_iter_1} ${nr_iter_2} ${sequence}"

    run_benchmark

    current_id=$((current_id+1))
    echo ${current_id} > ${LOGTRACE_DIR}/current_id
done
