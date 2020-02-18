#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_qspi.sh
answer=$?
proceed_if_ok $answer

source $SCRIPT_DIR/test_hmc.sh
proceed_if_ok $?

echo
