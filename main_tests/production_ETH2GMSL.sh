#!/bin/bash

# Wrapper script for doing a production cycle/routine for a ethernet to gmsl board
# This script handles
#
# Can be called with:  ./production_ETH2GMSL.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"
ScriptLoc="$(readlink -f "$0")"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh



while true; do
	echo_blue "Please enter your choice: "
	options=("System Test" "GMSL P2 Cameras Test" "GMSL P1 Cameras Test" "Power-off board")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				wait_for_board_online
				echo_blue "Starting system test"
				production "crr" "$opt" "ETH2GMSL"
				break ;;
                
			2) 
				wait_for_board_online
				echo_blue "GMSL PORT 2 Cameras Test"
				production "crr" "$opt" "ETH2GMSL"
				break;;

			3)
				wait_for_board_online
				echo_blue "GMSL PORT 1 Cameras Test"
				production "crr" "$opt" "ETH2GMSL"
				break;;

			4)
				enforce_root
				ssh_cmd "sudo poweroff &>/dev/null"
				break 2;;

			*) echo "invalid option $REPLY";;

            esac

    done
done
