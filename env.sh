export HOSTNAME=${HOSTNAME}

export ROOT_DIR=${PWD}

export SOURCE_DIR=${ROOT_DIR}/source

export LOGTRACE_DIR=${ROOT_DIR}/logtrace

export BENCH_BUILD_DIR=${ROOT_DIR}/bench_build
export BENCH_INSTALL_DIR=${ROOT_DIR}/bench_install

mkdir -p ${LOGTRACE_DIR}

export PROJECT_NODE_ROOT="\${HOME}"
export PATH_RESULTS=${PROJECT_NODE_ROOT}/Data/PhD_temperature_results/raw/

export REMOTE_USER=willy
export REMOTE_IP=project-node
export REMOTE_PATH=$PATH_RESULTS/${HOSTNAME}
