#!/bin/bash

# export CC=clang
# export CXX=clang++

(
    mkdir -p bench_build
    cd bench_build
    cmake -DCMAKE_INSTALL_PREFIX=`pwd`/../bench_install ../source/microbe_cache
    make VERBOSE=1
    make install
)
