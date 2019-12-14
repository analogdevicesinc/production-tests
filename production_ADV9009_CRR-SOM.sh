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
	options=("Program Sequencer" "Program PLL" "ADRV Carrier Test" "ADRV SOM Test" "ADRV SOM RF test" "Power-Off Pi" "Power-Off ADRV")
	select opt in "${options[@]}"; do
    		case $REPLY in
    		1)
				$SCRIPT_DIR/src/adm1266/production_flash
				break ;;
			2)
				wait_for_board_online
				ssh_cmd "sudo /home/analog/AD9542_eeprom_download/i2c/i2c"
				ssh_cmd "sudo poweroff &>/dev/null"
				echo "Board will power off. Wait for PS_DONE LED from carrier to turn off."
				break ;;
			3)
				wait_for_board_online
				echo_blue "Starting ADRV Carrier Test"
				production "crr" "$opt"
				break ;;
			4)
				wait_for_board_online
				echo_blue "Starting ADRV SOM Test"
				production "som" "$opt"
				break ;;
			5)
				wait_for_board_online
				python3 -m pytest $SCRIPT_DIR/src/pyadi-iio/test/test_adrv9009_zu11eg.py -v
				break ;;
			6)
				enforce_root
				poweroff
				break 2 ;;
			7)
				wait_for_board_online
				ssh_cmd "sudo poweroff &>/dev/null"
				break ;;
        		*) echo "invalid option $REPLY";;
    		esac
	done
done
