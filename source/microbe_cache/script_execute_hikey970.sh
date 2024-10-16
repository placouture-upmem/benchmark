#!/bin/bash

set -x

ROOT_DIR=`pwd`

LOGTRACE_NAME=stress
LOGTRACE_DIR=${ROOT_DIR}/logtrace/${LOGTRACE_NAME}

mkdir -p ${LOGTRACE_DIR}

function normal_config()
{
    echo "set normal_config"

    sudo bash -c "echo schedutil > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
    sudo bash -c "echo 1844000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
    sudo bash -c "echo schedutil > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor"
    sudo bash -c "echo 2362000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq"

    sudo bash -c "echo simple_ondemand > /sys/class/devfreq/ddr_devfreq/governor"
    sudo bash -c "echo 415000000 > /sys/class/devfreq/ddr_devfreq/min_freq"
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
	# row_insertion=`sqlite3 ${LOGTRACE_DIR}/data.db "select max(id) from entry;"`
	# row_insertion=$((row_insertion + 1))

	# run_id=${row_insertion}
	row_insertion=$(printf "%010d\n" ${id_run})
	mkdir ${LOGTRACE_DIR}/${row_insertion}/

	OS_info=${LOGTRACE_DIR}/${row_insertion}/OS_info/
	mkdir ${OS_info}

	echo "${lf},${bf},${mf},${taskmap} ${bench} ${freq}"
	echo "${lf},${bf},${mf},${taskmap}" > ${OS_info}/configuration.csv

	sudo dmesg -c > ${OS_info}/before_dmesg.txt

	#### HARDWARE CONFIG ####
	sudo bash -c "echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
	sudo bash -c "echo ${lf} > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
	sudo bash -c "echo performance > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor"
	sudo bash -c "echo ${bf} > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq"
	# sudo bash -c "echo performance > /sys/class/devfreq/ddr_devfreq/governor"
	sudo bash -c "echo ${mf} > /sys/class/devfreq/ddr_devfreq/min_freq"

	for cpufreq in `ls --color=auto -d /sys/devices/system/cpu/cpufreq/policy*`
	do
	    name=`basename ${cpufreq}`
	    # sudo bash -c "echo \"\" > ${cpufreq}/stats/reset"
	    cat ${cpufreq}/stats/time_in_state > ${OS_info}/before_${name}.txt
	done

	# sudo bash -c "echo \"0\" > /sys/class/devfreq/ddr_devfreq/trans_stat"
	cat /sys/class/devfreq/ddr_devfreq/trans_stat > ${OS_info}/before_memory_controller.txt
	#### HARDWARE CONFIG ####

	script=$(mktemp)
	echo "#!/bin/bash" > ${script}
	echo "${ROOT_DIR}/benchmark_install/bin/${bench} ${sequence} ${nr_iter_1} ${nr_iter_2} ${freq} ${LOGTRACE_DIR} ${id_run} &" >> ${script}
	echo "echo \$! >> real_pid.txt" >> ${script}
	echo "wait \$!" >> ${script}

	(
	    mkdir ${LOGTRACE_DIR}/${row_insertion}/output
	    cd ${LOGTRACE_DIR}/${row_insertion}/output
	    taskset ${taskmap} time -v -p bash ${script} > 00_stdout 2> 00_stderr
	)

	rm ${script}
	
	echo "${lf},${bf},${mf},${taskmap}" > ${LOGTRACE_DIR}/${row_insertion}/output/configuration.csv
	
	sudo dmesg -c > ${OS_info}/after_dmesg.txt

	#### HARDWARE CONFIG ####
	for cpufreq in `ls --color=auto -d /sys/devices/system/cpu/cpufreq/policy*`
	do
	    name=`basename ${cpufreq}`
	    # sudo bash -c "echo \"\" > ${cpufreq}/stats/reset"
	    cat ${cpufreq}/stats/time_in_state > ${OS_info}/after_${name}.txt
	done

	cat /sys/class/devfreq/ddr_devfreq/trans_stat > ${OS_info}/after_memory_controller.txt
	#### HARDWARE CONFIG ####
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

    mf=${split_line[1]}
    lf=${split_line[2]}
    bf=${split_line[3]}
    taskmap=${split_line[4]}
    bench=${split_line[5]}
    sequence=${split_line[6]}
    nr_iter_1=${split_line[7]}
    nr_iter_2=${split_line[8]}
    freq=${split_line[9]}
    
    echo "${id_run} ${mf} ${lf} ${bf} ${taskmap} ${bench} ${sequence} ${nr_iter_1} ${nr_iter_2} ${freq}"

    run_benchmark
    
    current_id=$((current_id+1))
    echo ${current_id} > ${LOGTRACE_DIR}/current_id
done

normal_config
