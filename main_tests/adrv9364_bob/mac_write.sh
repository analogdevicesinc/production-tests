#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

QSPI_ENV_PART="/dev/mtd1"
QSPI_ENV_PART_SIZE="20000"
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

	MAC_STRING="ethaddr=$MAC_ETH0"

	sed -i "s/ethaddr=00:05:f7:80:fa:34/$MAC_STRING/" /boot/qspi_boot/uEnv.txt

	flashcp -v /boot/qspi_boot/uEnv.txt $QSPI_ENV_PART

	return 0
}