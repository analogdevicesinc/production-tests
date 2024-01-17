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
	options=("Program Sequencer" "Program PLL" "ADRV Carrier Test" "ADRV Carrier Test-SOM" "ADRV SOM Test" "ADRV SOM RF test" "ADRV FMCOMMS8 RF test" "Power-Off ADRV" "Power-Off Pi")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				echo_blue "This procedure takes around 40 seconds."
				pushd $SCRIPT_DIR/src/adm1266/
				./production_flash
				popd
				break ;;
			2)
				wait_for_board_online
				ssh_cmd "sudo /home/analog/adrv_som_test/i2c_ad9542"
				ssh_cmd "sudo poweroff &>/dev/null"
				echo_red "Power off command sent!" 
				echo_blue "Wait for PS_DONE LED from carrier to turn off."
				echo_blue "Manually powercycle the board using S12 switch."
				break ;;
			3)
				echo_blue "Please look at the carrier label"
				get_board_serial
				wait_for_board_online
				echo_blue "Starting ADRV Carrier Test"
				production "crr" "$opt" "ADV9009_CRR-SOM"
				break ;;
			4)
				echo_blue "Please look at the SOM RF Shield"
				get_board_serial
				wait_for_board_online
				echo_blue "Starting ADRV Carrier Test-SOM"
				production "crr" "$opt" "ADV9009_CRR-SOM"
				break ;;
			5)
				echo_blue "Please look at the SOM RF Shield"
				get_board_serial
				wait_for_board_online
				echo_blue "Starting ADRV SOM Test" 
				production "som" "$opt" "ADV9009_CRR-SOM"
				break ;;
			6)
				echo_blue "Please look at the SOM RF Shield"
				get_board_serial
				wait_for_board_online
				production "som" "$opt" "ADV9009_CRR-SOM"
				break ;;
			7)
				echo_blue "Please look at the FMCOMMS8 RF Shield"
				get_board_serial
				wait_for_board_online
				echo_blue "Starting FMCOMMS8 Test"
				dut_date_sync
				production "fmcomms8" "$opt" "ADV9009_CRR-SOM"
				break ;;
				
			8)
				wait_for_board_online
				ssh_cmd "sudo poweroff &>/dev/null"
				break 2 ;;

			9)
				enforce_root
				poweroff
				break ;;
				
        	*) echo "invalid option $REPLY";;
    		esac
	done
done
