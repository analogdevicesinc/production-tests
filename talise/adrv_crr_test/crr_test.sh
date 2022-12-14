#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
GLOBAL_FAIL=0

source $SCRIPT_DIR/test_nav.sh

echo
source $SCRIPT_DIR/test_audio.sh

echo
source $SCRIPT_DIR/test_periph.sh

echo
source $SCRIPT_DIR/test_hmc.sh

echo
source $SCRIPT_DIR/test_clk.sh

echo
source $SCRIPT_DIR/test_eth.sh

echo
source $SCRIPT_DIR/test_usb.sh

if [ -n "$GLOBAL_FAIL" ]; then
	exit 1
else
	exit 0
fi

