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

tolower() {
	echo "$1" | tr A-Z a-z
}

toupper() {
	echo "$1" | tr a-z A-Z
}

valid_ftdi_channel() {
	local channel="$(toupper $1)"
	for chan in A B C D GPIO_EXP1 ; do
		[ "$chan" == "$channel" ] && return 0
	done
	return 1
}

toggle_pins() {
	local channel="$(toupper $1)"
	valid_ftdi_channel "$channel" || return 1
	shift
	if [ "$channel" == "GPIO_EXP1" ] ; then
		./work/ft4232h_pin_ctrl --channel B \
			--serial "$FT4232H_SERIAL" \
			--mode spi-gpio-exp $@
		return $?
	fi
	./work/ft4232h_pin_ctrl --mode bitbang \
		--serial "$FT4232H_SERIAL" \
		--channel "$channel" $@
}

wait_pins() {
	local channel="$1"
	valid_ftdi_channel "$channel" || return 1
	shift
	./work/ft4232h_pin_ctrl --mode wait-gpio \
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

self_test() {
	./work/ft4232h_pin_ctrl --mode spi-adc --channel B \
		--serial "$FT4232H_SERIAL" --opts self-test
}

measure_voltage() {
	local channel="${1:-all}"

	[ -n "$VREF" ] && [ -n "$VGAIN" ] && [ -n "$VOFF" ] || {
		eeprom_cfg load
		if [ -z "$VREF" ] || [ -z "$VGAIN" ] || [ -z "$VOFF" ] ; then
			echo_red "Empty ADC setting(s)"
			echo_red "VREF=$VREF"
			echo_red "VGAIN=$VGAIN"
			echo_red "VOFF=$VOFF"
			exit 1
		fi
	}

	local opts="refinout=$VREF,no-samples=$NUM_SAMPLES"

	opts="$opts,voffset=$VOFF,gain=$VGAIN,vchannel=$channel"

	./work/ft4232h_pin_ctrl --mode spi-adc --serial "$FT4232H_SERIAL" \
		--channel B --opts "$opts"
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
		channel="A B D GPIO_EXP1"
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
		# GPIO expander (1) - pin4 HI disables ref measurement
		[ "$chan" == "GPIO_EXP1" ] && pin_vals="pin4"

		toggle_pins "$chan" $pin_vals || return 1
	done

	return 0
}

eeprom_rw() {
	local op="$1"
	local addr="$2"
	local cnt_or_data="$3"

	if [ "$op" == "read" ] ; then
		./work/ft4232h_pin_ctrl --serial "$FT4232H_SERIAL" \
			--channel B --mode spi-eeprom \
			--opts addr="$addr",read="$cnt_or_data",cs=D:0
	elif [ "$op" == "write" ] ; then
		./work/ft4232h_pin_ctrl --serial "$FT4232H_SERIAL" \
			--channel B --mode spi-eeprom \
			--opts addr="$addr",write="$cnt_or_data",cs=D:0
	else
		echo_red "Invalid op '$op'"
	fi
}

eeprom_cfg() {
	local op="$1"
	local PAGES="0 16 32"
	local CFGS="VREF VOFF VGAIN"
	local PAGE_SIZE=16
	local value

	shift
	if [ "$op" == "load" ] ; then
		for page in $PAGES ; do
			value="$(eeprom_rw "read" "$page" "$PAGE_SIZE")"
			[ "$?" == "0" ] || {
				echo_red "Failed to read EEPROM"
				return 1
			}
			[ -n "$value" ] || {
				echo_red "No value store in EEPROM at page '$page'"
				return 1
			}
			# evaluate the entries in the EEPROM as shell vars
			eval "export $value" || return 1
			[ "$EEPROM_VERBOSE" != "1" ] || echo_green "$value"
		done
		return 0
	elif [ "$op" == "save" ] ; then
		# export all arguments as variables
		while [ -n "$1" ] ; do
			eval "export $1"
			shift
		done
		# check that all of them are non-empty
		for cfg in $CFGS ; do
			value="$(eval echo "\$$cfg")"
			[ -n "$value" ] || {
				echo_red "No value provided for '$cfg'"
				return 1
			}
		done
		# Now write them to EEPROM
		local page
		for cfg in $CFGS ; do
			value="$(eval echo "\$$cfg")"
			eeprom_rw "write" "$page" "${cfg}=${value}" || return 1
			let page='page + PAGE_SIZE'
		done
		return 0
	else
		echo_red "Invalid EEPROM op '$op'"
		return 0
	fi
}

ref_measure_ctl() {
	local cmd="$(tolower $1)"

	# pin0 - select ref voltage - out-low == 10V, ough-high == 2.5V
	# pin1 - GND_REF_SEL - must be out-low
	# pin2 - REF_CH2_N_P_SEL - should be out-hi for now
	# pin3 - REF_CH1_N_P_SEL - should be out-hi for now
	# pin4 - EN_REF_MEASURE - active low

	if [ "$cmd" == "ref10v" ] ; then
		toggle_pins GPIO_EXP1 pin2 pin3 # pin4 - out-lo, pin1 - out-low, pin0 - out-lo
		sleep 0.5
	elif [ "$cmd" == "ref2.5v" ] ; then
		toggle_pins GPIO_EXP1 pin0 pin2 pin3 # # pin4 - out-lo, pin1 - out-low
		sleep 0.5
	elif [ "$cmd" == "disable" ] ; then
		toggle_pins GPIO_EXP1 pin4
		sleep 0.1
	else
		echo_red "Unknown command '$cmd' ; valid commands are: ref10v, ref2.5v, enabled & disable"
		return 1
	fi
}

scopy() {
	LD_LIBRARY_PATH=$(pwd)/work/scopy/deps/staging/lib $(pwd)/work/scopy/build/scopy $@
}
