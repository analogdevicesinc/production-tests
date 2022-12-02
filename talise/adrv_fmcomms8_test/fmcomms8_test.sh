#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_powersupply.sh
answer=$?

TIMED_LOG_SUFFIX="FRU"
timed_log "Setting FMCOMMS8 FRU EEPROM data"
source $SCRIPT_DIR/fru_write.sh
write_fru

if [ -n "$GLOBAL_FAIL" ]; then
	exit 1
else
	exit 0
fi
