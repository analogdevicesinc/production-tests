#!/bin/bash

#----------------------------------#
# Functions section                #
#----------------------------------#

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

__retry_common() {
	while [ "$retries" -gt 0 ] ; do
		# run the commands
		$@
		[ "$?" == "0" ] && return 0
		[ -z "$failfunc" ] || $failfunc
		echo_blue "   Retrying command ($retries): $@"
		sleep 1
		let retries='retries - 1'
	done
	echo_red "Command failed after $r1 retries: $@"
	return 1
}

retry() {
	local retries="$1"
	local r1="$retries"
	shift
	__retry_common $@
}

retry_and_run_on_fail() {
	local retries="$1"
	local failfunc="$2"
	shift
	shift
	__retry_common $@
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

pin_ctrl() {
	local lockfile="/tmp/pin_ctrl_lock"
	(
		flock -e 200
		$SCRIPT_DIR/work/ft4232h_pin_ctrl $@
	) 200>$lockfile
}

toggle_pins() {
	local channel="$(toupper $1)"
	valid_ftdi_channel "$channel" || return 1
	shift
	if [ "$channel" == "GPIO_EXP1" ] ; then
		pin_ctrl --channel B \
			--serial "$FT4232H_SERIAL" \
			--mode spi-gpio-exp $@
		return $?
	fi
	pin_ctrl --mode bitbang \
		--serial "$FT4232H_SERIAL" \
		--channel "$channel" $@
}

wait_pins() {
	local channel="$1"
	valid_ftdi_channel "$channel" || return 1
	shift
	pin_ctrl --mode wait-gpio \
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

enable_usb_data_port() {
	toggle_pins A pin5
}

enable_usb_power_port() {
	toggle_pins A pin6
}

self_test() {
	local samples="${1:-1}"
	$SCRIPT_DIR/work/ft4232h_pin_ctrl --mode spi-adc --channel B \
		--serial "$FT4232H_SERIAL" --opts "self-test,no-samples=$samples"
}

have_eeprom_vars_loaded() {
	local var
	local value
	for var in $EEPROM_VARS ; do
		value="$(eval echo "\$$var")"
		[ -n "$value" ] || return 1
	done
	return 0
}

show_eeprom_vars() {
	local color="${1:-green}"
	local var
	local value
	for var in $EEPROM_VARS ; do
		value="$(eval echo "\$$var")"
		echo_${color} "${var}=${value}"
		# only a single VREF can be defined
		if [ "$var" == "VREF" ] ; then
			continue
		fi
		# VOFF & VGAIN can be specified differently per channel
		for ch in 0A 1A 2A 3A 4A 5A 6A 7A 0B 1B 2B 3B 4B 5B 6B 7B ; do
			local value="$(eval echo \${${var}${ch}})"
			[ -n "$value" ] || continue
			echo_green "${var}${ch}=${value}"
		done
	done
}

__populate_vranges() {
	local device_or_vranges="$1"
	[ -n "$device_or_vranges" ] || return 0

	if [ -f "$SCRIPT_DIR/config/$device_or_vranges/values.sh" ] ; then
		source "$SCRIPT_DIR/config/$device_or_vranges/values.sh"
		device_or_vranges="$VOLTAGE_RANGES"
	fi

	if [ -n "$device_or_vranges" ] ; then
		opts="${opts},vrange-each="
		for idx in $(seq 0 15) ; do
			local vrange="$(get_item_from_list $idx $device_or_vranges)"
			opts="${opts}${vrange}:"
		done
	fi
}

__populate_voffsets() {
	opts="${opts},voffset-each="
	for ch in 0A 1A 2A 3A 4A 5A 6A 7A 0B 1B 2B 3B 4B 5B 6B 7B ; do
		local value="$(eval echo \${VOFF${ch}})"
		if [ -z "$value" ] ; then
			value=$VOFF
		fi
		opts="${opts}${value}:"
	done
}

__populate_vgains() {
	opts="${opts},vgain-each="
	for ch in 0A 1A 2A 3A 4A 5A 6A 7A 0B 1B 2B 3B 4B 5B 6B 7B ; do
		local value="$(eval echo \${VGAIN${ch}})"
		if [ -z "$value" ] ; then
			value=$VGAIN
		fi
		opts="${opts}${value}:"
	done
}

measure_voltage() {
	local channel="${1:-all}"
	local samples="${2:-$NUM_SAMPLES}"
	local device_or_vranges="$3"

	have_eeprom_vars_loaded || {
		eeprom_cfg load
		if ! have_eeprom_vars_loaded ; then
			echo_red "Empty ADC setting(s)"
			show_eeprom_vars red
			exit 1
		fi
	}

	local opts="refinout=$VREF,no-samples=$samples"

	opts="$opts,vchannel=$channel"
	__populate_vranges "$device_or_vranges"
	__populate_voffsets
	__populate_vgains

	pin_ctrl --mode spi-adc --serial "$FT4232H_SERIAL" \
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
	for screen_pid in $(pgrep -f "SCREEN.*$1") ; do
		kill -9 $screen_pid
	done
	screen -wipe &> /dev/null
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
		pin_ctrl --serial "$FT4232H_SERIAL" \
			--channel B --mode spi-eeprom \
			--opts addr="$addr",read="$cnt_or_data",cs=D:0
	elif [ "$op" == "write" ] ; then
		pin_ctrl --serial "$FT4232H_SERIAL" \
			--channel B --mode spi-eeprom \
			--opts addr="$addr",write="$cnt_or_data",cs=D:0
	else
		echo_red "Invalid op '$op'"
	fi
}

is_valid_eeprom_cfg() {
	local cfg="$1"
	[ -n "$cfg" ] || return 1
	for var in $EEPROM_VARS ; do
		if [[ $cfg = ${var}=* ]] ; then
			return 0
		fi
		# only a single VREF can be defined
		if [ "$var" == "VREF" ] ; then
			continue
		fi
		# VOFF & VGAIN can be specified differently per channel
		for ch in 0A 1A 2A 3A 4A 5A 6A 7A 0B 1B 2B 3B 4B 5B 6B 7B ; do
			if [[ $cfg = ${var}${ch}=* ]] ; then
				return 0
			fi
		done
	done
	return 1
}

eeprom_cfg() {
	local op="$1"
	local PAGE_SIZE=16
	local page=0
	local value

	shift
	if [ "$op" == "load" ] ; then
		# try to read all the pages
		for page in $(seq 0 16 496) ; do
			value="$(eeprom_rw "read" "$page" "$PAGE_SIZE")"
			[ "$?" == "0" ] || {
				[ -n "$DONT_SHOW_EEPROM_MESSAGES" ] || \
					echo_red "Failed to read EEPROM"
				return 1
			}
			# stop reading after this marker
			if [ "$value" == "<last_entry>" ] ; then
				break
			fi
			is_valid_eeprom_cfg "$value" || {
				[ -n "$DONT_SHOW_EEPROM_MESSAGES" ] || \
					echo_red "Invalid entry in EEPROM '$value'"
				return 1
			}
			# evaluate the entries in the EEPROM as shell vars
			eval "export $value" || return 1
		done
		return 0
	elif [ "$op" == "save" ] ; then
		local values
		# validate arguments
		while [ -n "$1" ] ; do
			is_valid_eeprom_cfg "$1" || {
				[ -n "$DONT_SHOW_EEPROM_MESSAGES" ] || \
					echo_red "'$1' is an invalid EEPROM config setting"
				return 1
			}
			values="$values $1"
			shift
		done
		# write values to EEPROM
		for value in $values ; do
			eeprom_rw "write" "$page" "$value" || return 1
			let page='page + PAGE_SIZE'
			# check if we've filled it up
			if [ "$page" -gt "496" ] ; then
				break
			fi
		done
		# if it's not filled up, write a marker for when reading
		if [ "$page" -lt 496 ] ; then
			eeprom_rw "write" "$page" "<last_entry>" || return 1
		fi
		return 0
	else
		[ -n "$DONT_SHOW_EEPROM_MESSAGES" ] || \
			echo_red "Invalid EEPROM op '$op'"
		return 1
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
	elif [ "$cmd" == "ref2.5v" ] ; then
		toggle_pins GPIO_EXP1 pin0 pin2 pin3 # # pin4 - out-lo, pin1 - out-low
	elif [ "$cmd" == "disable" ] ; then
		toggle_pins GPIO_EXP1 pin4
	else
		echo_red "Unknown command '$cmd' ; valid commands are: ref10v, ref2.5v, enabled & disable"
		return 1
	fi
}

scopy() {
	LD_LIBRARY_PATH=$SCRIPT_DIR/work/scopy/deps/staging/lib $SCRIPT_DIR/work/scopy/build/scopy $@
}

get_hwserial() {
	LD_LIBRARY_PATH=$SCRIPT_DIR/work/libiio/build iio_attr -C $IIO_URI_MODE hw_serial 2> /dev/null | cut -d' ' -f2
}

__get_phys_netdevs() {
	for dev in /sys/class/net/*/device ; do echo $dev | cut -d'/' -f5 ; done
}

pi_serial() {
	cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2
}

jigname() {
	local nm="$(cat /etc/hostname 2> /dev/null)"
	[ -n "$nm" ] || nm="jig1"
	local pi_serial="$(pi_serial)"
	if [ -n "$pi_serial" ] ; then
		echo "${nm}-${pi_serial}"
		return
	fi
	local dev="$(__get_phys_netdevs | head -1)"
	if [ -z "$dev" ] ; then
		echo $nm
		return
	fi
	local addr=$(cat /sys/class/net/$dev/address | sed  's/://g')
	if [ -n "$addr" ] ; then
		echo "${nm}-${addr}"
		return
	fi
	echo $nm
}

save_logfiles_to() {
	local log_dir="$1"
	local savefile="$2"

	local tmpfile="$(mktemp)"
	tar -C "$log_dir" -zcvf "$tmpfile" .
	mv -f "$tmpfile" "$savefile"
}

check_and_reboot() {
	local logfile="$1"
	[ -n "$REBOOT_BUTTON" ] || return 1
	if type __check_and_reboot &> /dev/null ; then
		__check_and_reboot $logfile
		return $?
	fi
	return 1
}

__usbreset() {
	local lsusb_entry="$1"
	local bus="$(get_item_from_list 1 $lsusb_entry)"
	local dev="$(get_item_from_list 3 $lsusb_entry | sed 's/://g')"

	$SCRIPT_DIR/work/usbreset /dev/bus/usb/$bus/$dev
}

__usbreset_all() {
	local entry
	lsusb | while read -r entry ; do
		__usbreset "$entry"
	done
}

usbreset() {
	local vid="$1"
	local did="$2"

	[ -n "$vid" ] || {
		echo_red "No USB vendor ID provided"
		return 1
	}

	if [ "$vid" == "all" ] ; then
		__usbreset_all
		return $?
	fi

	[ -n "$did" ] || {
		echo_red "No USB device ID provided"
		return 1
	}

	local entry="$(lsusb -d ${vid}:${did})"
	[ -n "$entry" ] || {
		echo_blue "No USB device ${vid}:${did} found"
		return 1
	}

	__usbreset "$entry"
}
