#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source $SCRIPT_DIR/lib/utils.sh
source $SCRIPT_DIR/config.sh

m2k_pre_check() {
	echo_green "1. Checking the ADALM2000"

	if ! [ -x "$(command -v m2kcli)" ]; then
		echo_red 'm2kcli is not installed.' >&2
		return 1
	fi
		
	wait_for_board_online || {
		terminate_any_lingering_stuff
		echo_red "Board did not come online"
		return 1
	}

	echo_green "1.1 Calibrating the ADC"
	m2kcli analog-in uri "$M2K_URI_MODE" -C || {
		terminate_any_lingering_stuff
		echo_red "ADALM2000 failed to calibrate"
		return 1
	}
	
	echo_green "1.2 Calibrating the DAC"
	m2kcli analog-out uri "$M2K_URI_MODE" -C || {
		terminate_any_lingering_stuff
		echo_red "ADALM2000 failed to calibrate"
		return 1
	}

	terminate_any_lingering_stuff
	return 0
}
