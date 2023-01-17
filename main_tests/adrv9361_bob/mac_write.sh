#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

QSPI_ENV_PART="/dev/mtd1"
MAC_PREFIX="00:05:f7:80:"
MKENVIMAGE_PATH="/usr/bin/mkenvimage"
QSPI_ENV_PART_SIZE="0x20000"
MAC_ADDR=""

source $SCRIPT_DIR/test_util.sh

function check_req() {
	if [ ! -e $QSPI_ENV_PART ]
	then
		echo "QSPI memory not detected"
		exit 1
	fi

	if [ ! -e $MKENVIMAGE_PATH ]
	then
		echo "mkenvimage executable not found. Check u-boot-tools to be installed"
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
	cp $SCRIPT_DIR/uboot_default_uenv.txt $SCRIPT_DIR/uboot_default_uenv_copy.txt
	echo "ethaddr=$MAC_ETH0" >> $SCRIPT_DIR/uboot_default_uenv_copy.txt
	echo "model=ADRV9361-Z7035" >> $SCRIPT_DIR/uboot_default_uenv_copy.txt
	mkenvimage -s $QSPI_ENV_PART_SIZE -o /boot/qspi_boot/uenv.bin $SCRIPT_DIR/uboot_default_uenv_copy.txt
	flashcp -v /boot/qspi_boot/uenv.bin $QSPI_ENV_PART
	rm -rf $SCRIPT_DIR/uboot_default_uenv_copy.txt


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
	#echo $MAC_ADDR;

	return 0;
}
