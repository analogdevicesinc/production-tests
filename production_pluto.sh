#!/bin/bash

# Wrapper script for doing a production cycle/routine for a Pluto board.
# This script handles 
#  * ADC measurements and validation of voltages
#  * Flashing of the board
#  * Post-flash - AD9361 calibration, measurements and Linux system validation
#
# Can be called with:  ./production_pluto.sh
#
# The ./update_pluto_release.sh must be called to update release files

source lib/production.sh

production "pluto"
