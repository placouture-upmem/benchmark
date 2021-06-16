#!/bin/bash

mkdir ./bench_install/data/
./bench_install/bin/create_sequence
mv sequence_* ./bench_install/data/

./bench_install/bin/script_odroid_xu3.sh
