#!/bin/bash

# Wrapper script for doing a production cycle/routine for MAX-ARDUINO 
# This script handles
#
# Can be called with:  ./production_MAX-ARDUINO.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
	echo_blue "Please enter your choice: "
	options=("Firmware and memory test" "System Test" "WI-FI Flash Test" "Power-Off Pi")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				echo_blue "Firmware and memory tests"
				production "crr" "$opt" "MAX-ARDUINO"
				break ;;


			2)
				echo_blue "System Test"
				production "crr" "$opt" "MAX-ARDUINO"
				break ;;
				

			3) echo_blue "WI-FI Flash Test"
				production "crr" "$opt" "MAX-ARDUINO"
				break ;;
			4)
				enforce_root
				poweroff
				break 2 ;;
			*) echo "invalid option $REPLY";;
    		esac
	done
done
