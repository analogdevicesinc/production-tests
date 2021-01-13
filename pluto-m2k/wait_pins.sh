#!/bin/bash

# Wrapper script for waiting for a button to be pressed.
# The button can be connected to a GPIO.
#
# Can be called with:  ./wait_pins.sh <chan> [pin0 pin1 .. pin7]
# Pin names are `pinX` - X == 0 to 7
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/config.sh

valid_ftdi_channel "$1" || {
	echo_red "Invalid FTDI channel '$1'"
	exit 1
}

wait_pins $@
