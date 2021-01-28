#!/bin/bash
# Dummy script to ease the background start of the process waiting
# for the START BUTTON (D pin1)
# When the button is pressed, a dummy echo is written to <path to tmp file>
# Can be called with:  ./wait_btn_background <path to tmp file>

if [ "$#" -eq 0 ]; then
	echo "This script requires a path to a tmp file."
	exit 1
fi

SCRIPT_DIR="$(readlink -f $(dirname $0))"

($SCRIPT_DIR/wait_pins.sh D pin1 ; echo pressed > $1) &
