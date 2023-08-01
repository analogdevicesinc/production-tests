#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

MAC_PREFIX="00:05:f7:80:"


source $SCRIPT_DIR/test_util.sh

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
