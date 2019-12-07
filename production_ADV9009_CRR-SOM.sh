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

wait_for_board_online

#Check if found @analog.local client is ADRV9009-ZU11EG
if ssh_cmd "grep -q talise /sys/bus/nvmem/devices/system-id0/nvmem"; then
	#Search for test folder
	if ssh_cmd "[ ! -d /home/analog/adrv_crr_test ] && [ ! -d /home/analog/adrv_som_test ]"; then
		echo_blue "Tests not found on box SD card. Copying from PI -> ADRV9009"
		$SCRIPT_DIR/scp.sh $SCRIPT_DIR/adrv_crr_test/ analog@analog:/home/analog/adrv_crr_test/ analog
		$SCRIPT_DIR/scp.sh $SCRIPT_DIR/adrv_som_test/ analog@analog:/home/analog/adrv_som_test/ analog
	fi
else
	echo_red "Connected board is not ADRV9009. Can't start tests"
	exec "$ScriptLoc"
fi

while true; do
	echo_blue "Please enter your choice: "
	options=("ADRV Carrier Test" "ADRV SOM Test" "Program Sequencer" "Power-Off Pi" "Power-Off ADRV")
	select opt in "${options[@]}"; do
    		case $REPLY in
        		1)
				wait_for_board_online
				echo_blue "Starting ADRV Carrier Test"
				production "crr" "$opt"
				break ;;
				2)
				wait_for_board_online
				echo_blue "Starting ADRV SOM Test"
				production "som" "$opt"
				break ;;
				3)
				$SCRIPT_DIR/src/adm1266/production_flash
				break ;;
        		4)
				enforce_root
				poweroff
				break 2 ;;
	    		5)
				wait_for_board_online
				ssh_cmd "sudo poweroff &>/dev/null"
				break ;;
        		*) echo "invalid option $REPLY";;
    		esac
	done
done
