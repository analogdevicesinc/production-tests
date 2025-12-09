#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/production.sh
source $SCRIPT_DIR/lib/utils.sh

while true; do
	echo_blue "Please enter your choice: "
	options=("MAX17320 Ini Flash" "Firmware Flash" "System Test" "Power-Off Pi")
	select opt in "${options[@]}"; do
		case $REPLY in
			1)
				production "crr" "$opt" "ADRD5161"

				break ;;
			2)
				export BOARD_SERIAL=$(date +%s)
				echo "Using timestamp as serial number: $BOARD_SERIAL"

				production "crr" "$opt" "ADRD5161"

				break ;;
			3)
				production "crr" "$opt" "ADRD5161"

				break;;

			4)
				enforce_root
				poweroff
				break 2 ;;

			*) echo "invalid option $REPLY";;
		esac
	done
done
