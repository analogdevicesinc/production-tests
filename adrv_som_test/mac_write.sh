#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

QSPI_ENV_PART="/dev/mtd1"
QSPI_ENV_PART_SIZE="20000"
MKENVIMAGE_PATH="/usr/bin/mkenvimage"
MAC_PREFIX="aa:bb:cc:dd:"


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
	read -p 'Please enter last four digits of ETH0 mac address (e.g. aa:bb): ' MAC_ETH0
	MAC_ETH0="${MAC_PREFIX}${MAC_ETH0}";
	read -p 'Please enter last four digits of ETH1 mac address (e.g. aa:bb): ' MAC_ETH1
	MAC_ETH1="${MAC_PREFIX}${MAC_ETH1}";

	echo -e "ethaddr=$MAC_ETH0\n" > /tmp/uboot-env.txt
	echo -e "eth1addr=$MAC_ETH1\n" >> /tmp/uboot-env.txt

	mkenvimage -s 0x20000 -o /tmp/uboot-env.bin /tmp/uboot-env.txt

	flashcp -v /tmp/uboot-env.bin $QSPI_ENV_PART

	return 0
}
