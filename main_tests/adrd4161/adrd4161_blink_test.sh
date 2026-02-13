#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

sudo $SCRIPT_DIR/firmware.sh $SCRIPT_DIR/adrd4161_blink.elf

read -n 1 -p "Are the DS1 and DS2 LEDs currently blinking? [y/n]" answer

case "$answer" in
	y|Y|yes|YES)
		exit 0
		;;
	n|N|no|NO)
		exit 1
		;;
	*) 
		echo "Invalid input. Please answer y or n."
		exit 2
		;;
esac
