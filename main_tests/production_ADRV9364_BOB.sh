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
	options=("ADRV9364 Test" "Repair Flash" "Power-Off Pi" "Power-Off Carrier")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				wait_for_board_online
				get_board_serial
				echo_blue "Starting ADRV9364 Test"
				production "crr" "$opt" "ADRV9364_BOB"
				break ;;
			2)
				PORT=$(dmesg | grep tty | grep "cp210x converter now attached to" | awk '{print $10}');
				TTY_PORT="/dev/$PORT"
				until [ $format_ok = true ]
				do
					read -p 'Please enter last four digits of ETH0 mac address (e.g. aa:bb): ' MAC_ETH0
					if [[ $MAC_ETH0 =~ ^([0-9a-f]{2})(:[0-9a-f]{2})$ ]]; 
						then 
							format_ok=true
						else
							echo "Wrong Format: Should be four hex digits in groups of two separated by :"
						fi
				done
				MAC_ADDR="00:05:f7:80:$MAC_ETH"
				$SCRIPT_DIR/adrv9364_bob/check_uboot.expect $TTY_PORT $MAC_ADDR
				wait_for_board_online
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
