#!/bin/bash

# Wrapper script for doing a production cycle/routine for FMCOMMS4
# This script handles
#
# Can be called with:  ./production_SWIOT.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
	echo_blue "Please enter your choice: "
	options=("Memory/MAXQ1065 tests" "AD74413R/MAX14906 tests" "Program final firmware" "Power-Off Pi")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				echo_blue "Starting Memory/MAXQ1065 tests"
				production "crr" "$opt" "SWIOT"
				break ;;

			2)
				echo_blue "Starting AD74413R/MAX14906 tests"
				production "crr" "$opt" "SWIOT"
				break ;;

			3)
				echo_blue "Starting Program final firmware"
				production "crr" "$opt" "SWIOT"
				break ;;
			
			
			4)
				enforce_root
				poweroff
				break 2 ;;
			*) echo "invalid option $REPLY";;
    		esac
	done
done
