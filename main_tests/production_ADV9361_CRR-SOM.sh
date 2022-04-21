#!/bin/bash

# Wrapper script for doing a production cycle/routine for a rfsom-box.
# This script handles
#
# Can be called with:  ./production_rfsom-box.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
	echo_blue "Please enter your choice: "
	options=("Program PLL" "ADRV1 Carrier Test" "Power-Off Pi" "Power-Off ADRV")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				wait_for_board_online
				ssh_cmd "sudo /home/analog/adrv_som_test/i2c_ad9542"
				ssh_cmd "sudo poweroff &>/dev/null"
				echo_red "Power off command sent!" 
				echo_blue "Wait for PS_DONE LED from carrier to turn off."
				echo_blue "Manually powercycle the board using S12 switch."
				break ;;
			2)
				wait_for_board_online
				get_board_serial
				echo_blue "Starting ADRV Carrier Test"
				production "crr" "$opt" "ADRV9361_CRR-SOM"
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
