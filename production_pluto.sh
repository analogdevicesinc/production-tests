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

source config.sh

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

	echo_green "Waiting for start button"

	wait_pins D "$START_BUTTON" || {
		echo_red "Waiting for start button failed..."
		sleep 3
		continue
	}

	./lib/preflash.sh "pluto" || {
		echo_red "Pre-flash step failed..."
		sleep 3
		continue
	}

	./lib/flash.sh "pluto" || {
		echo_red "Flash step failed..."
		sleep 3
		continue
	}

	./config/pluto/postflash.sh "dont_power_cycle_on_start" || {
		echo_red "Post-flash step failed..."
		sleep 3
		continue
	}
done
