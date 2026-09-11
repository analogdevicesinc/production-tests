#!/bin/bash

# Wrapper script for initializing the board to a known/sane state.
# Requires sudo.
#
# Can be called with:  ./init.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/config.sh
