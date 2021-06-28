#!/bin/bash

# export CC=clang
# export CXX=clang++

(
    mkdir -p create_sequence_build
    cd create_sequence_build
    cmake -DCMAKE_INSTALL_PREFIX=`pwd`/../create_sequence_install ../source/create_sequence
    make VERBOSE=1
    make install
)

(
    mkdir -p benchmark_build
    cd benchmark_build
    cmake -DCMAKE_INSTALL_PREFIX=`pwd`/../benchmark_install ../source/microbe_cache
    make VERBOSE=1
    make install
)
