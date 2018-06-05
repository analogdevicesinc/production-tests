#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

COMMON_RELEASE_FILES="boot.dfu u-boot.elf uboot-env.dfu ps7_init.tcl"

# HOST x86 Config
TTYUSB=ttyTest-A1

# RPI Config
#havegpio=1
#GDB=gdb
#TTYUSB=ttyS0

POWER_CYCLE_DELAY=2

FT4232H_SERIAL="Test-Slot-A"

# This can be increased to a higher value, and then multiple measurements
# will be made and averaged
NUM_SAMPLES=1

# These need to be tuned per board
REFINOUT=2.4989
VOLTAGE_OFFSET=0
VOLTAGE_GAIN=1

#----------------------------------#
# Functions section                #
#----------------------------------#

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

is_ft4232h() {
	lsusb -v -d 0456:f001 &> /dev/null
}

valid_ftdi_channel() {
	local channel="$1"
	channel=$(echo $channel | tr a-z A-Z)
	for chan in A B C D ; do
		[ "$chan" == "$channel" ] && return 0
	done
	return 1
}

toggle_pins() {
	local channel=$1
	valid_ftdi_channel "$channel" || return 1
	shift
	./work/ft4232h_pin_ctrl --mode bitbang \
		--serial "$FT4232H_SERIAL" \
		--channel "$channel" $@
}

power_cycle_sleep() {
	[ -z "$POWER_CYCLE_DELAY" ] || \
		sleep "$POWER_CYCLE_DELAY"
}

disable_all_usb_ports() {
	toggle_pins A # will set all pins to low
}

enable_all_usb_ports() {
	toggle_pins A pin5 pin6
}

enable_usb_port_1() {
	toggle_pins A pin5
}

enable_usb_port_2() {
	toggle_pins A pin6
}

reset_adc() {
	toggle_pins B pin4 || return 1
	sleep 0.1
	toggle_pins B || return 1
	sleep 0.1
	toggle_pins B pin4 || return 1
}

self_test() {
	./work/ft4232h_pin_ctrl --mode spi --channel B \
		--serial "$FT4232H_SERIAL" --self-test
}

measure_voltage() {
	local channel="${1:-all}"
	./work/ft4232h_pin_ctrl --mode spi --serial "$FT4232H_SERIAL" \
		--channel B --refinout "$REFINOUT" --no-samples "$NUM_SAMPLES" \
		--voffset "$VOLTAGE_OFFSET" --gain "$VOLTAGE_GAIN" \
		--vchannel "$channel"
}

is_valid_number() {
	local re='^-?[0-9]+([.][0-9]+)?$'
	[ -n "$1" ] || return 1
	[[ $1 =~ $re ]]	# note: this is bash-ism
}

valid_numbers() {
	local cnt="$1"
	shift
	while [ "$cnt" -gt 0 ] ; do
		is_valid_number "$1" || return 1
		shift
		let cnt='cnt - 1'
	done
	return 0
}

get_item_from_list() {
	local idx=$1
	shift
	while [ "$idx" -gt 0 ] ; do
		let idx='idx - 1'
		shift
	done
	echo $1
}

value_in_range() {
	local val="$1"
	local min="$2"
	local max="$3"

	is_valid_number "$val" || {
		echo_red "Compare value '$val' is not a valid number"
		return 1
	}

	is_valid_number "$min" || {
		echo_red "Min value '$min' is not a valid number"
		return 1
	}

	is_valid_number "$val" || {
		echo_red "Max value '$max' is not a valid number"
		return 1
	}

	[ "$(echo "$min <= $val && $val <= $max" | bc -l)" == "1" ]
}
