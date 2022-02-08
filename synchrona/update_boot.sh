#!/bin/bash

# Script used for update of BOOT partition on carrier SD card
#
# Can be called with:  ./update_boot.sh
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh

wait_for_board_online
ssh_cmd "sudo mount /dev/mmcblk0p1 /boot"
$SCRIPT_DIR/scp.sh $SCRIPT_DIR/misc/* analog@analog:/boot/ analog

echo_blue "Select what type of SD card you want to create: "
options=("zu11eg-revb-4.14" "zu11eg-revb-4.19" "fmcomms8")
select opt in "${options[@]}"; do
	case $REPLY in
		1)
			SRC_DIR="zynqmp-adrv9009-zu11eg-revb-adrv2crr-fmc-revb"
		2)
			SRC_DIR="zynqmp-adrv9009-zu11eg-revb-adrv2crr-fmc-revb-4.19"
		3)
			SRC_DIR="fmcomms8_boot"
	esac
done

ssh_cmd "sudo cp /boot/$SRC_DIR/* /boot/"
ssh_cmd "sudo sync"
ssh_cmd "sudo umount /boot"
