#!/bin/bash

# Wrapper script for doing a production cycle/routine for T1L TO USB
# This script handles
#
# Can be called with:  ./production_T1L-2-USB.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
	echo_blue "Please enter your choice: "
	options=("T1L TO USB TEST" "Power-Off Pi")
	select opt in "${options[@]}"; do
            case $REPLY in
			1)
				echo_blue "T1L TO USB TEST"
				production "crr" "$opt" "T1L-2-USB"
				break ;;
			2)
				enforce_root
				poweroff
				break 2 ;;
			*) echo "invalid option $REPLY";;
            esac
	done
done
