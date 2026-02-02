#!/bin/bash

# Wrapper script for doing a production cycle/routine for ADRD4161
# This script handles
#
# Can be called with:  ./production_ADRD4161.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
	echo_blue "Please enter your choice: "
	options=("CAN Test" "IMU Test" "GPIO Test" "Power-Off Pi")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				echo_blue "CAN Test"
				production "crr" "$opt" "ADRD4161"
				break ;;
			2)
				echo_blue "IMU Test"
				production "crr" "$opt" "ADRD4161"
				break ;;
			3) echo_blue "GPIO Test"
				production "crr" "$opt" "ADRD4161"
				break ;;
			4)
				enforce_root
				poweroff
				break 2 ;;
			*) echo "invalid option $REPLY";;
    		esac
	done
done
