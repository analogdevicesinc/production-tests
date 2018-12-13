#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source $SCRIPT_DIR/config.sh
source $SCRIPT_DIR/lib/update_release.sh

#----------------------------------#
# Functions section                #
#----------------------------------#

get_config() {
	local board="$1"
	is_ft4232h && {
		echo "$SCRIPT_DIR/config/${board}/ftdi4232.cfg"
		return
	}
	lsusb -v -d 0403:6014 &> /dev/null && {
		echo "$SCRIPT_DIR/config/${board}/digilent.cfg"
		return
	}
}

load_uboot() {
	if [ "$MODE" == "DFU_ONLY" ] ; then
		echo_green "  Skipping JTAG u-boot load"
		return 0
	fi

	if is_ft4232h ; then
		local bmode=1
	else
		local bmode=0
	fi

	openocd -f "$CABLE_CFG" -c "load_uboot $UBOOT_ELF_FILE $bmode" -s "$SCRIPT_DIR" || {
		echo_blue "OpenOCD command failed"
		force_terminate_programs
		return 1
	}
}

flash() {
	local BOARD="$1"
	local MODE="$2"

	local CABLE_CFG="$(get_config "$BOARD")"
	[ -n "$CABLE_CFG" ] || {
		echo_red "Could not find a supported JTAG cable on your system"
		return 1
	}
	[ -f "$CABLE_CFG" ] || {
		echo_red "Cable config file '$CABLE_CFG' does not exist"
		return 1
	}

	have_all_firmware_files "$BOARD" || {
		echo_red "Not all firmware files are present..."
		return 1
	}

	local releaseDir="$SCRIPT_DIR/release/${BOARD}"
	local firmwareDfuFile="${BOARD}.dfu"
	local UBOOT_ELF_FILE="$releaseDir/u-boot.elf"

	force_terminate_programs

	# Disable board first; OpenOCD will enable it
	if is_ft4232h ; then
		disable_all_usb_ports
		power_cycle_sleep
	fi

	echo_green "1. Loading uboot '$UBOOT_ELF_FILE'"
	load_uboot

	echo_green "2. Running DFU utils step"

	expect $SCRIPT_DIR/lib/flash.exp "$releaseDir" "$firmwareDfuFile" || {
		echo_blue "expect command failed"
		force_terminate_programs
		return 1
	}

	# wait until env is saved by uboot
	sleep 2

	if is_ft4232h ; then
		echo_green "3. Done ; powercycling the board"
		disable_all_usb_ports
		power_cycle_sleep
		enable_all_usb_ports
	else
		echo_green "3. Done ; you can now powercycle the board"
	fi

	return 0
}
