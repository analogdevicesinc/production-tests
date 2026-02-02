#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

sudo gpioset gpiochip0 24=1

read -n 1 -p "Is the LED connector currently ON? [y/n] " answer

case "$answer" in
	y|Y|yes|YES)
		sudo gpioset gpiochip0 24=0
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
