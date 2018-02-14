#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source config.sh

#----------------------------------#
# Functions section                #
#----------------------------------#

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

enforce_openocd_version() {
	local ver="$(openocd --version 2>&1 | head -1 | cut -d' ' -f4)"
	local min_ver="$(echo $ver | cut -d. -f2)"
	local maj_ver="$(echo $ver | cut -d. -f1)"
	if [ "$maj_ver" -le "0" ] && [ "$min_ver" -lt "10" ] ; then
		echo_red "You need at least version 0.10.0 for OpenOCD"
		exit 1
	fi
}

check_system_requirements() {
	type lsusb &> /dev/null || {
		echo_red "You need 'lsusb' on your system ; please install libusb and/or usb-utils"
		exit 1
	}
	type openocd &> /dev/null || {
		echo_red "You need to have OpenOCD installed on your system"
		exit 1
	}
	enforce_openocd_version
	type dfu-util &> /dev/null || {
		echo_red "You need to install 'dfu-util' on your system"
		exit 1
	}
	type expect &> /dev/null || {
		echo_red "You need to have the 'expect' utility installed on your system"
		exit 1
	}
	return 0
}

get_config() {
	local board="$1"
	lsusb -v -d 0456:f001 &> /dev/null && {
		echo "config/${board}_ftdi4232.cfg"
		return
	}
	lsusb -v -d 0403:6014 &> /dev/null && {
		echo "config/${board}_digilent.cfg"
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

	echo_green "2. Waiting 5 seconds for board to settle"
	sleep 5
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

	echo_green "4. Done ; you can now powercycle the board"
	# Note: powercycling does not work yet on Pluto
	#echo_green "4. Power cycling the board"
	#openocd -f "$CABLE_CFG" -c power_cycle || {
	#	echo_blue "Warning: powercycle command failed"
	#}

	return 0
}

#----------------------------------#
# Main section                     #
#----------------------------------#

BOARD="$1"

[ -n "$BOARD" ] || {
	echo_red "No board-name provided"
	exit 1
}

RELEASE_DIR="$(readlink -f "release/$BOARD")"

[ -d "$RELEASE_DIR" ] || {
	echo_red "No valid release dir provided"
	exit 1
}

FIRMWARE_DFU_FILE="${BOARD}.dfu"

echo "Note: using release dir '$RELEASE_DIR'"

# Sanity check that we have all release files, before going forward
for file in $FIRMWARE_DFU_FILE $COMMON_RELEASE_FILES ; do
	[ -f "$RELEASE_DIR/$file" ] || {
		echo_red "File not found: '$RELEASE_DIR/$file'"
		exit 1
	}
done

if [ `id -u` != "0" ]
then
	echo_red "This script must be run as root" 1>&2
	exit 1
fi

check_system_requirements

while true ;
do
	CABLE_CFG="$(get_config "$BOARD")"
	[ -n "$CABLE_CFG" ] || {
		echo_red "Could not find a supported JTAG cable on your system"
		sleep 4
		continue
	}
	[ -f "$CABLE_CFG" ] || {
		echo_red "Cable config file '$CABLE_CFG' does not exist"
		exit 1
	}
	break
done

UBOOT_ELF_FILE="$RELEASE_DIR/u-boot.elf"

force_terminate_programs

echo_green "Press CTRL-C to exit"

###### In Jtag Mode #######

flash_board "$TTYUSB" "$RELEASE_DIR" "$FIRMWARE_DFU_FILE"

exit 0
