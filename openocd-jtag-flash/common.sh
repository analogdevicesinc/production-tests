#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

RELEASE_FILES="boot.dfu u-boot.elf uboot-env.dfu"

#----------------------------------#
# Functions section                #
#----------------------------------#

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

check_system_requirements() {
	type lsusb &> /dev/null || {
		echo_red "You need 'lsusb' on your system ; please install libusb and/or usb-utils"
		exit 1
	}
	type openocd &> /dev/null || {
		echo_red "You need to have OpenOCD installed on your system"
		exit 1
	}
	type expect &> /dev/null || {
		echo_red "You need to have the 'expect' utility installed on your system"
		exit 1
	}
	return 0
}

get_config() {
	lsusb -v -d 0456:f001 &> /dev/null && {
		echo "config/cable_ftdi4232.cfg"
		return
	}
	lsusb -v -d 0403:6014 &> /dev/null && {
		echo "config/cable_digilent.cfg"
		return
	}
}

force_terminate_programs() {
	killall -9 openocd 2> /dev/null
	killall -9 expect 2> /dev/null
	return 0
}

flash_board () {
	local ttyUSB="$1"
	local releaseDir="$2"
	local firmwareDfuFile="$3"

	echo_green "1. Loading uboot '$UBOOT_ELF_FILE'"

	while true ; do
		openocd -f "$CABLE_CFG" -c "load_uboot $UBOOT_ELF_FILE" || {
			echo_blue "OpenOCD command failed ; retrying"
			force_terminate_programs
			sleep 3
			continue
		}
		break
	done

	echo_green "2. Waiting 10 seconds for board to settle"
	sleep 10
	echo_green "3. Running DFU utils step"

	while true ; do
		expect cmd.exp "$ttyUSB" "$releaseDir" "$firmwareDfuFile" || {
			echo_blue "expect command failed ; retrying"
			force_terminate_programs
			sleep 3
			continue
		}
		break
	done

	echo_green "4. Power cycling the board"
	openocd -f "$CABLE_CFG" -c power_cycle || {
		echo_blue "Warning: powercycle command failed"
	}

	return 0
}

#----------------------------------#
# Main section                     #
#----------------------------------#

# Prefer dir from CLI arg ; we could be getting this as an env var
[ -z "$1" ] || RELEASE_DIR="$1"

# If empty use default/current script path
[ -n "$RELEASE_DIR" ] || \
	RELEASE_DIR="$(pwd)/release"

# make sure the path is absolute
RELEASE_DIR="$(readlink -f $RELEASE_DIR)"

[ -d "$RELEASE_DIR" ] || {
	echo_red "No valid release dir provided"
	exit 1
}

FIRMWARE_DFU_FILE="$2"

[ -n "$FIRMWARE_DFU_FILE" ] || {
	echo_red "No firmware DFU filename provided"
	exit 1
}

echo "Note: using release dir '$RELEASE_DIR'"

# Sanity check that we have all release files, before going forward
for file in $FIRMWARE_DFU_FILE $RELEASE_FILES ; do
	[ -f "$RELEASE_DIR/$file" ] || {
		echo_red "File not found: '$RELEASE_DIR/$file'"
		exit 1
	}
done

source config.sh

if [ `id -u` != "0" ]
then
	echo_red "This script must be run as root" 1>&2
	exit 1
fi

check_system_requirements

while true ;
do
	CABLE_CFG="$(get_config)"
	[ -n "$CABLE_CFG" ] || {
		echo_red "Could not find a supported JTAG cable on your system"
		sleep 4
		continue
	}
	break
done

UBOOT_ELF_FILE="$RELEASE_DIR/u-boot.elf"

force_terminate_programs

echo_green "Press CTRL-C to exit"

###### In Jtag Mode #######

flash_board "$TTYUSB" "$RELEASE_DIR" "$FIRMWARE_DFU_FILE"

exit 0
