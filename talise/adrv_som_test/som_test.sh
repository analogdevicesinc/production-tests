#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_qspi.sh

source $SCRIPT_DIR/test_hmc.sh

source $SCRIPT_DIR/test_adrv.sh

if [ -n "$GLOBAL_FAIL" ]; then
	exit 1
else
	exit 0
fi
