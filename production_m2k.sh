#!/bin/bash

# Wrapper script for doing a production cycle/routine for a M2k board.
# This script handles 
#  * ADC measurements and validation of voltages
#  * Flashing of the board
#  * Post-flash - AD9361 calibration, measurements and Linux system validation
#
# Can be called with:  ./production_m2k.sh
#
# The ./update_m2k_release.sh must be called to update release files

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/production.sh

production "m2k" $@
