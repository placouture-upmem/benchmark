#!/bin/bash

(
    mkdir -p ./benchmark_install/input/sequence/sequence_33554432
    cd ./benchmark_install/input/sequence/sequence_33554432
    ../../../bin/create_sequence 33554432
)

# bash ./benchmark_install/bin/script_create_configuration_odroidxu3.sh
# bash ./benchmark_install/bin/script_execute_odroidxu3.sh

# bash ./benchmark_install/bin/script_create_configuration_hikey970.sh
# bash ./benchmark_install/bin/script_execute_hikey970.sh
