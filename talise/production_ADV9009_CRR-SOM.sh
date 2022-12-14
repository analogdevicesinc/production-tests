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
	options=("Program Sequencer" "Program PLL" "ADRV Carrier Test" "ADRV Carrier Test-SOM" "ADRV SOM Test" "ADRV SOM RF test" "ADRV FMCOMMS8 RF test" "Power-Off Pi" "Power-Off ADRV")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				echo_blue "This procedure takes around 40 seconds."
				pushd $SCRIPT_DIR/src/adm1266/
				sudo ./production_flash
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
				echo "Please use the scanner to scan the QR/Barcode on your carrier"
				get_board_serial
				wait_for_board_online
				echo_blue "Starting ADRV Carrier Test"
				production "crr" "$opt" "ADRV2CRR"
				break ;;
			4)
				echo "Please use the scanner to scan the QR/Barcode on your SOM RF Shield"
				get_board_serial
				wait_for_board_online
				echo_blue "Starting ADRV Carrier Test-SOM"
				production "crr" "$opt" "ADRV2CRR-SOM"
				break ;;
			5)
				echo "Please use the scanner to scan the QR/Barcode on your SOM RF Shield"
				get_board_serial
				wait_for_board_online
				echo_blue "Starting ADRV SOM Test" 
				production "som" "$opt" "ADRV9009-ZU11EG-SOM"
				break ;;
			6)
				echo "Please use the scanner to scan the QR/Barcode on your SOM RF Shield"
				get_board_serial
				wait_for_board_online
				#python3 -m pytest --report-log=$SCRIPT_DIR/logRF_test_log/result_${BOARD_SERIAL}.log --color yes $SCRIPT_DIR/work/pyadi-iio/test/test_adrv9009_zu11eg.py -v --uri="ip:analogdut.local" --hw="adrv9009-dual" --tb=short --showlocals -rN
				production "som" "$opt" "ADRV9009-ZU11EG-SOM-RF"
				break ;;
			7)
				echo "Please use the scanner to scan the QR/Barcode on your FMCOMMS8 RF Shield"
				get_board_serial
				wait_for_board_online
				echo_blue "Starting FMCOMMS8 Test"
				dut_date_sync
				production "fmcomms8" "$opt" "FMCOMMS8"
				break ;;
			8)
				sudo poweroff
				break 2 ;;
			9)
				wait_for_board_online
				ssh_cmd "sudo poweroff &>/dev/null"
				break ;;
        		*) echo "invalid option $REPLY";;
    		esac
	done
done
