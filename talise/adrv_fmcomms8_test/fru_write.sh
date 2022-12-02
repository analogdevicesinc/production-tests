#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

EEPROM_PATH="/sys/devices/platform/amba/ff030000.i2c/i2c-1/i2c-8/8-0052/eeprom"
MASTERFILE_PATH="/usr/local/src/fru_tools/masterfiles/AD-FMCOMMS8-EBZ-FRU.bin"
SERIAL_NUMBER_PREFIX=$(date +"%m%Y")

source $SCRIPT_DIR/test_util.sh

function check_req() {
	if [ ! -e $EEPROM_PATH ]
	then
		echo "EEPROM file not found on SYSFS"
		exit 1
	fi

	if [ ! -e $FRU_TOOLS_PATH ]
	then
		echo "FRU TOOLS path not correct or masterfile not available"
		exit 1
	fi
}	

function write_fru() {
	check_req
	if which fru-dump > /dev/null
	then
		read -p 'Please enter last digits of serial number: ' SERIAL_NUMBER
		SERIAL_NUMBER="${SERIAL_NUMBER_PREFIX}${SERIAL_NUMBER}";
		fru-dump -i $MASTERFILE_PATH -o $EEPROM_PATH -d now -s $SERIAL_NUMBER 
		return 0
	else
		echo "fru-dump command not found. Check if you have it installed."
		exit 1
	fi
}
