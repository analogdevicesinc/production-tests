#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh

PYSMU_LIBDIR="$(readlink -f $SCRIPT_DIR/work/libsmu/bindings/python/build/lib*/pysmu/..)"
SMU_CLI_PATH="$(readlink -f $SCRIPT_DIR/work/libsmu/build/src/cli)"

PYTHONPATH="$(${PYTHON} -c "import sys; print(':'.join(sys.path))")"
PYTHONPATH="${PYTHONPATH}:${PYSMU_LIBDIR}"

${PYTHON} configure_calibration_board.py
