#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/config.sh

eeprom_cfg $@ || exit 1

if [ "$1" == "load" ] ; then
	echo_green "Configuration loaded from EEPROM"
elif [ "$1" == "save" ] ; then
	echo_green "Configuration saved to EEPROM"
fi
