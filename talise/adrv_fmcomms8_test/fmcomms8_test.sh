#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/test_powersupply.sh
answer=$?
proceed_if_ok $answer

TIMED_LOG_SUFFIX="FRU"

timed_log "Setting FMCOMMS8 FRU EEPROM data"
source $SCRIPT_DIR/fru_write.sh
write_fru

echo
