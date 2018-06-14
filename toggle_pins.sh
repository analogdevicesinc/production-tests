#!/bin/bash

# Wrapper script for toggling GPIO pins via bitbang.
# This script only handles flashing, no extra steps
#
# Can be called with:  ./toggle_pins.sh <chan> [pin0 pin1 .. pin7]
# Pin names are `pinX` - X == 0 to 7 to set as output high
#               `pinXi` - X == 0 to 7 to set as input
#                otherwise [if unspecified] pins will be ouput low
#

source config.sh

valid_ftdi_channel "$1" || {
	echo_red "Invalid FTDI channel '$1'"
	exit 1
}

toggle_pins $@
