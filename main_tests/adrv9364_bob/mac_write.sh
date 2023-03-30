#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

QSPI_ENV_PART="/dev/mtd1"
MAC_PREFIX="00:05:f7:80:"


source $SCRIPT_DIR/test_util.sh

function check_req() {
	if [ ! -e $QSPI_ENV_PART ]
	then
		echo "QSPI memory not detected"
		exit 1
	fi
}	

function write_mac() {
	check_req

	local format_ok=false

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

	MAC_ETH0="${MAC_PREFIX}${MAC_ETH0}";

	fw_setenv ethaddr "$MAC_ETH0"
	fw_setenv model "ADRV9364-Z7020"
	fw_setenv qspiboot "qspiboot=echo Booting from flash... &&  sf probe 0 0 0"

	return 0
}

function get_mac() {
	local format_ok=false

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

	MAC_ETH="${MAC_PREFIX}${MAC_ETH0}";
	echo $MAC_ETH > mac_file.txt;

	return 0;
}