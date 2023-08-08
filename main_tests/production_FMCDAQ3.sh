#!/bin/bash

# Wrapper script for doing a production cycle/routine for fmcdaq3.
# This script handles
#
# Can be called with: ./production_FMCDAQ3.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
	echo_blue "Please enter your choice: "
	options=("FMCDAQ3 Test" "Power-Off Carrier" "Power-Off Pi")
	select opt in "${options[@]}"; do
		case $REPLY in
			1)
				wait_for_board_online
				export BOARD_SERIAL=$(get_board_serial)
				echo_blue "Starting FMCDAQ3 Test"
				production "crr" "$opt" "FMCDAQ3"
				break ;;
			2)
				wait_for_board_online
				ssh_cmd "sudo poweroff &>/dev/null"
				break ;;
			3)
				enforce_root
				poweroff
				break ;;

			*) echo "invalid option $REPLY";;
		esac
	done
done

