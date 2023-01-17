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
	options=("ADRV9361 Test" "Repair Flash" "Power-Off Pi" "Power-Off Carrier")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				get_board_serial
				echo_blue "Starting ADRV9361 Test"
				production "crr" "$opt" "ADRV9361_BOB"
				break ;;
			2)
				##### run expect script to erase flash and get out of uboot ######
				$SCRIPT_DIR/adrv9361_bob/check_uboot.expect
				#### unlock the flash and erase the environment partition
				$SCRIPT_DIR/adrv9361_bob/unlock_erase_flash.sh
				##### re-write flash with mac address 
				$SCRIPT_DIR/adrv9361_bob/test_qspi.sh
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
