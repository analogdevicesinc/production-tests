#!/bin/bash

# Wrapper script for calling the post-flash steps for M2k factory testing
# Called with:  sudo ./postflash_m2k.sh
# Requires `sudo`
# Mostly used for testing

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/config/m2k/postflash.sh

post_flash $@
