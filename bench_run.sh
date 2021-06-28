#!/bin/bash

bash create_sequence_install/bin/script_create_sequence.sh

bash ./benchmark_install/bin/script_create_configuration_generic.sh
bash ./benchmark_install/bin/script_execute_generic.sh

# bash ./benchmark_install/bin/script_create_configuration_odroidxu3.sh
# bash ./benchmark_install/bin/script_execute_odroidxu3.sh

# bash ./benchmark_install/bin/script_create_configuration_hikey960.sh
# bash ./benchmark_install/bin/script_execute_hikey960.sh

# bash ./benchmark_install/bin/script_create_configuration_hikey970.sh
# bash ./benchmark_install/bin/script_execute_hikey970.sh
