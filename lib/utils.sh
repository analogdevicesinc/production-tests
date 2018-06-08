#!/bin/bash

#----------------------------------#
# Functions section                #
#----------------------------------#

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

retry() {
	local retries="$1"
	shift
	while [ "$retries" -gt 0 ] ; do
		# run the commands
		$@
		[ "$?" == "0" ] && return 0
		echo_blue "   Retrying command ($retries): $@"
		sleep 1
		let retries='retries - 1'
	done
	echo_red "Command failed after $retries retries: $@"
	return 1
}

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

force_terminate_programs() {
	# terminate detached screen sesssions; they could be left over
	# from a previous run
	for session in $(screen -ls | grep Detached | awk '{print $1}') ; do
		screen -X -S $session quit
	done
	killall -9 openocd 2> /dev/null
	killall -9 expect 2> /dev/null
	return 0
}

openocd_is_minimum_required() {
	local ver="$(openocd --version 2>&1 | head -1 | cut -d' ' -f4)"
	local min_ver="$(echo $ver | cut -d. -f2)"
	local maj_ver="$(echo $ver | cut -d. -f1)"
	[ "$maj_ver" -ge "0" ] && [ "$min_ver" -ge "10" ]
}

enforce_openocd_version() {
	if ! openocd_is_minimum_required ; then
		echo_red "You need at least version 0.10.0 for OpenOCD"
		exit 1
	fi
}

check_system_requirements() {
	type bc &> /dev/null || {
		echo_red "You need 'bc' on your system"
		exit 1
	}
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
	type iio_attr &> /dev/null || {
		echo_red "You need 'iio_attr' on your system ; please install libiio"
		exit 1
	}
	type sshpass &> /dev/null || {
		echo_red "You need 'sshpass' installed on your system"
		exit 1
	}
	return 0
}

enforce_root() {
	if [ `id -u` != "0" ]
	then
		echo_red "This script must be run as root" 1>&2
		exit 1
	fi
}

init_pins() {
	local channel=$1
	local pin_vals

	if [ -n "$channel" ] ; then
		[ "$channel" == "C" ] && return 1
		valid_ftdi_channel "$channel" || return 1
	else
		# init all - except C for UART
		channel="A B D"
	fi

	for chan in $channel ; do
		pin_vals=
		# Channel for JTAG, pin1 is TDI - OpenOCD will take of the JTAG pins,
		# we just need to init all other pins
		[ "$chan" == "A" ] && pin_vals="pin1i"
		# Channel for SPI, pin1 is MOSI, pin3 is CS - these are controlled
		# via the ft4232h_pin_ctrl utility in SPI mode
		[ "$chan" == "B" ] && pin_vals="pin1i pin3"
		# Channel for GPIOs - these are controlled via shell scripts and
		# the ft4232h_pin_ctrl utility (in bitbang mode)
		[ "$chan" == "D" ] && pin_vals="pin0 pin1i pin6i pin7i"

		toggle_pins "$chan" $pin_vals || return 1
	done

	return 0
}
