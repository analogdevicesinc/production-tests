#!/bin/bash

# Wrapper script for doing a production cycle/routine for fmcomms2/3.
# This script handles
#
# Can be called with:  ./production_FMCOMMS2-3.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
	echo_blue "Please enter your choice: "
	options=("DCXO Calibration Test" "FMCOMMS2/3 Test" "Power-Off Pi" "Power-Off Carrier")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				wait_for_board_online
				get_board_serial
				echo_blue "Starting DCXO Test"
				production "crr" "$opt" "FMCOMMS2-3"
				break ;;
			
			2)
				wait_for_board_online
				get_board_serial
				echo_blue "Starting FMCOMMS2/3 Test"
				production "crr" "$opt" "FMCOMMS2-3"
				break ;;
			3)
				enforce_root
				poweroff
				break 2 ;;
			4)
				wait_for_board_online
				ssh_cmd "sudo poweroff &>/dev/null"
				break ;;
			*) echo "invalid option $REPLY";;
    		esac
	done
done
