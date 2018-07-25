#!/bin/bash

# Wrapper script for calling the pre-flash steps for M2k factory testing
# Called with:  sudo ./preflash_m2k.sh
# Requires `sudo`
# Mostly used for testing

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/preflash.sh

pre_flash "m2k"
