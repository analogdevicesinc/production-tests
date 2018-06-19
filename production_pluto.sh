#!/bin/bash

# Wrapper script for doing a production cycle/routine for a Pluto board.
# This script handles 
#  * ADC measurements and validation of voltages
#  * Flashing of the board
#  * Post-flash - AD9361 calibration, measurements and Linux system validation
#
# Can be called with:  ./production_pluto.sh
#
# The ./update_pluto_release.sh must be called to update release files

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source config.sh

# State variables; are set during state transitions
DONE=0
ERROR=0
READ=0
PROGRESS=0

#----------------------------------#
# Functions section                #
#----------------------------------#

show_leds() {
	local leds

	if [ "$DONE" == "1" ] ; then
		leds="$leds $DONE_LED"
	fi

	if [ "$READY" == "1" ] ; then
		leds="$leds $READY_LED"
	fi

	if [ "$ERROR" == "1" ] ; then
		leds="$leds $ERROR_LED"
	fi

	if [ "$PROGRESS" == "1" ] ; then
		leds="$leds $PROGRESS_LED"
	fi

	toggle_pins D $leds
}

show_ready_state() {
	PROGRESS=0
	READY=1
	show_leds
}

show_start_state() {
	DONE=0
	READY=0
	ERROR=0
	PROGRESS=1
	show_leds
}

show_error_state() {
	ERROR=1
	show_leds
}

#----------------------------------#
# Main section                     #
#----------------------------------#

echo_green "Initializing FTDI pins to default state"
init_pins

while true ; do

	[ -n "$VREF" ] && [ -n "$VGAIN" ] && [ -n "$VOFF" ] || {
		echo_green "Loading settings from EEPROM"
		eeprom_cfg load || {
			echo_red "Failed to load settings from EEPROM..."
			sleep 3
			continue
		}
	}

	show_ready_state || {
		echo_red "Cannot enter READY state"
		sleep 3
		continue
	}

	echo_green "Waiting for start button"

	wait_pins D "$START_BUTTON" || {
		echo_red "Waiting for start button failed..."
		show_error_state
		sleep 3
		continue
	}

	show_start_state

	./lib/preflash.sh "pluto" || {
		echo_red "Pre-flash step failed..."
		show_error_state
		sleep 3
		continue
	}

	./lib/flash.sh "pluto" || {
		echo_red "Flash step failed..."
		show_error_state
		sleep 3
		continue
	}

	./config/pluto/postflash.sh "dont_power_cycle_on_start" || {
		echo_red "Post-flash step failed..."
		show_error_state
		sleep 3
		continue
	}
	DONE=1
done
