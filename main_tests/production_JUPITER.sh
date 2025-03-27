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

RPI_SW_V="JT_RPI SW v0.1.1"

while true; do
	echo_blue "Please enter your choice: "
	options=("Test Jupiter Main Board" "Test Jupiter Add-On Board" "Test Entire System" "Send all log files" "Power-Off Jupiter" "Repair Jupiter SD Card" "Power-Off Pi")
	select opt in "${options[@]}"; do
    		case $REPLY in
			1)
				echo_yellow "#############################################################"
				echo_yellow "Starting TEST MAIN BOARD procedure.The following MUST be connected (see documentation):\r\n"
				echo_yellow "  1.-> SD card inserted in slot"
				echo_yellow "  2.-> Ethernet cable from Ethernet Switch - DUT ETH (50cm)"
				echo_yellow "  3.-> eSATA cable coming from SSD - ESATA"
				echo_yellow "  4.-> HDMI - DP Adapter + Mini HDMI to HDMI cable coming from DUT Display"
				echo_yellow "  5.-> GPIO Loopback cable - into GPIO connector"
				echo_yellow "  6.-> UART microUSB cable from RPI"
				echo_yellow "  7.-> AddOn Interface TEST_BRD - AddOn Connector"
				echo_yellow "  8.-> RF Loopback cables in MAIN using SMA Quick connect adapters"
				echo_yellow "  9.-> CLK_OUT cable using SMA Quick connect adapters"
				echo_yellow "  10.-> MCS_OUT cable using SMA Quick connect adapters"
				echo_yellow "  11.-> Press button to power the board, LED should trun BLUE\r\n"
				echo_yellow "############################################################"
				wait_enter &&
				wait_for_board_online
				echo_blue "Starting Main Board Test"
				production "crr" "$opt" "JUPITER"
				break ;;
			2)
				echo_yellow "###########################################################"
				echo_yellow "Testing add-on board. The following MUST be connected:\r\n"
				echo_yellow "  1.-> SD card inserted in slot"
				echo_yellow "  2.-> Ethernet cable from Ethernet Switch - DUT ETH (50cm)"
				echo_yellow "  3.-> DUT_POWER cable - in USB_POWER"
				echo_yellow "  4.-> RF Loopback cables on ADD-ON"
				echo_yellow "  5.-> Press button to power the board, LED should trun BLUE\r\n"
				echo_yellow "###########################################################"
				wait_enter &&
				wait_for_board_online
				echo_blue "Starting Add-On Board Test"
				production "crr" "$opt" "JUPITER"
				break ;;
			3)
				echo_yellow "####################################################"
				echo_yellow "Starting TEST SYSTEM procedure\r\n"
				echo_yellow "  1.-> RF Loopback cables on the ADD-ON ports"
				echo_yellow "  2.-> RF terminators on the MAIN BOARD ports"
				echo_yellow "  3.-> DYMO Label Printer connected to raspberry pi"
				echo_yellow "  4.-> SD card inserted in slot"
				echo_yellow "  5.-> Ethernet cable from Ethernet Switch - DUT ETH (50cm)"
				echo_yellow "  6.-> Press button to power the board, LED should trun BLUE\r\n"
				echo_yellow "####################################################"
				wait_enter &&
				wait_for_board_online
				echo_blue "Starting system test"
				production "crr" "$opt" "JUPITER"
				break ;;
			4)
				LOGDIRT=$SCRIPT_DIR/log
				export DBSERVER="cluster0.oiqey.mongodb.net"
				export DBUSERNAME="dev_production1"
				export DBNAME="dev_${BOARD}_prod"
				if [ -f $SCRIPT_DIR/password.txt ]; then
					export DBPASSWORD=$(cat $SCRIPT_DIR/password.txt)
				else
					echo "Please input the password provided for storing log files remotely"
					read PASSWD
					echo $PASSWD > $SCRIPT_DIR/password.txt
					export DBPASSWORD=$(cat $SCRIPT_DIR/password.txt)
				fi
				export BOARD_NAME="JUPITER"
				telemetry prod-logs-upload --tdir $LOGDIRT > $SCRIPT_DIR/telemetry_out.txt
				cat $SCRIPT_DIR/telemetry_out.txt | grep "Authentication failed"
				if [ $? -eq 0 ]; then
					rm -rf $SCRIPT_DIR/password.txt
				fi
				rm -rf $SCRIPT_DIR/telemetry_out.txt
				break ;;
			5)
				wait_for_board_online
				ssh_cmd "sudo poweroff &>/dev/null"
				break ;;
			6)
				echo_yellow "####################################################"
				echo_yellow "This step is used in case the card got corrupted and the tests are not working as expected\r\n"
				echo_yellow "This step requires the board to boot and the following:\r\n"
				echo_yellow "  1.-> SD card inserted in slot"
				echo_yellow "  2.-> Ethernet cable"
				echo_yellow "  3.-> Press button to power the board, LED should trun BLUE\r\n"
				echo_yellow "####################################################"
				wait_for_board_online

				echo_yellow "Repairing jupiter SD card";
				echo_yellow "Copying Image file to the board. Please type the password";
				scp $SCRIPT_DIR/jupiter/bootfiles/Image root@analogdut.local:/boot/Image ;
				if [ $? -eq 0 ]; then
					echo_yellow "Copying system.dtb file to the board. Please type the password";
					scp $SCRIPT_DIR/jupiter/bootfiles/system.dtb root@analogdut.local:/boot/system.dtb ;
					if [ $? -eq 0 ]; then
						echo_yellow "Copying BOOT.BIN file to the board. Please type the password";
						scp $SCRIPT_DIR/jupiter/bootfiles/BOOT.BIN root@analogdut.local:/boot/BOOT.BIN ;
						if [ $? -eq 0 ]; then
							echo_green "Files updated successfully!"
						fi
					else
						echo_red "Something went wrong"
					fi
				else
					echo_red "Something went wrong"
				fi

				echo_yellow "Board will now power off!\r\n"
				ssh_cmd "sudo poweroff &>/dev/null"
				break ;;
			7)
				enforce_root
				poweroff
				break 2 ;;
			*) echo "invalid option $REPLY";;
    		esac
	done
done
