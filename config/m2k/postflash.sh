#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source config.sh

#----------------------------------#
# Functions section                #
#----------------------------------#

terminate_any_lingering_scopies() {
	for pid in $(pgrep scopy) ; do
		kill -9 $pid
	done
}

wait_for_board() {
	local serial
	for iter in $(seq $BOARD_ONLINE_TIMEOUT) ; do
		serial=$(iio_attr -C $IIO_URI_MODE hw_serial 2> /dev/null | cut -d ' ' -f2)
		[ -z "$serial" ] || return 0
		sleep 1
	done
	return 1
}

#----------------------------------#
# Main section                     #
#----------------------------------#

post_flash() {
	force_terminate_programs
	terminate_any_lingering_scopies

	# This is a small workaround to avoid power-cycling the board
	# when running this script; it means that someone else took care of
	# this before calling the script
	if [ "$1" != "dont_power_cycle_on_start" ] ; then
		echo_green "0. Power cycling the board"
		disable_all_usb_ports
		power_cycle_sleep
		enable_all_usb_ports
		power_cycle_sleep
	fi

	echo_green "1. Waiting for board to come online (timeout $BOARD_ONLINE_TIMEOUT seconds)"
	wait_for_board || {
		terminate_any_lingering_scopies
		echo_red "Board did not come online"
		return 1
	}

	scopy --script config/m2k/scopy.js || {
		terminate_any_lingering_scopies
		echo_red "Scopy tests have failed..."
		return 1
	}

	terminate_any_lingering_scopies

	echo
	echo_green "PASSED ALL TESTS"
	return 0
}
