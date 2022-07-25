#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

LD_LIBRARY_PATH="$SCRIPT_DIR/work/libiio/build"
export LD_LIBRARY_PATH

PATH="$SCRIPT_DIR/work/:$PATH"
export PATH

export LC_ALL="C.UTF-8"

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
		ft4232h_pin_ctrl $@
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
	ft4232h_pin_ctrl --mode spi-adc --channel B \
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

__get_hwserial() {
	iio_attr -C $IIO_URI_MODE hw_serial 2> /dev/null | cut -d' ' -f2
}

get_hwserial() {
	local timeout="$1"
	if [ -z "$timeout" ] ; then
		__get_hwserial
	else
		local serial
		for _ in $(seq 1 $timeout) ; do
			serial=$(__get_hwserial)
			[ -z "$serial" ] || {
				echo "$serial"
				break
			}
			sleep 1
		done
	fi
	return 1
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

wait_for_board_offline() {
	BOARD_ONLINE_TIMEOUT=${BOARD_ONLINE_TIMEOUT:-20}
	local serial
	for iter in $(seq $BOARD_ONLINE_TIMEOUT) ; do
		serial=$(iio_attr -C $IIO_URI_MODE hw_serial 2> /dev/null | cut -d ' ' -f2)
		[ -n "$serial" ] || return 0
		sleep 1
	done
	return 1
}

ssh_cmd() {
	local USER=analog
	local CLIENT=analog
	local PASS=analog
	local CMD="$1"

	[ -n "$CMD" ] || {
		echo "failed - no command"
	exit 1
	}

	[ -z "$2" ] || {
		$USER = $2
	}

	[ -z "$3" ] || {
		$CLIENT = $3
	}

	[ -z "$4" ] || {
		$PASS = $4
	}

	sshpass -p${PASS} ssh -q -t -oConnectTimeout=10 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oCheckHostIP=no "$USER"@"$CLIENT" "$CMD"
}

wait_for_board_online(){
	while true; do
		if timeout 30 bash -c "until ping -q -c3 analog &>/dev/null; do false; done"
		then
			echo_blue "Connection to DUT OK"
			break
		else
			echo_red "Check ethernet connection to DUT"
		fi
	done
}
