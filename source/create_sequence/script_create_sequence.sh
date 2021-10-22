#!/bin/bash

sizes=(
    1048576
    2097152

    # 4096
    # 8192
    # 16384
    # 32768
    # 65536
    # 131072
    # 160100
    # 524288
    # 1048576
    # 2097152
    # 4194304
    # 16777216
    # 33554432
    # 67108864
    # 134217728
    # 268435456
    # 402653184
    # 805306368
    # 1610612736
)

function work() {
    (
	mkdir -p benchmark_install/input/sequence/sequence_${1}
	cd benchmark_install/input/sequence/sequence_${1}
	echo `pwd`
	../../../../create_sequence_install/bin/create_sequence ${1}
    )
}
export -f work

parallel work ::: ${sizes[@]}

mkdir -p benchmark_install/human_readable_sequence_input/
find benchmark_install/input/ -name "*.txt" -exec mv -t benchmark_install/human_readable_sequence_input/ {} +
