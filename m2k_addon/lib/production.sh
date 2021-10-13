#!/bin/bash

source $SCRIPT_DIR/config.sh

#----------------------------------#
# Functions section                #
#----------------------------------#

show_leds() {
	local leds

	if [ "$PASSED" == "1" ] ; then
		leds="$leds $PASSED_LED"
	fi

	if [ "$READY" == "1" ] ; then
		leds="$leds $READY_LED"
	fi

	if [ "$FAILED" == "1" ] ; then
		leds="$leds $FAILED_LED"
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
	PASSED=0
	READY=0
	FAILED=0
	PROGRESS=1
	show_leds
}

handle_error_state() {
	local serial="$1"
	FAILED=1
	show_leds
	inc_fail_stats "$serial"
	console_ascii_failed

	if [ -n "$serial" ] ; then
		cat "$LOGFILE" > "$LOGDIR/failed_${serial}_${RUN_TIMESTAMP}.log"
	else
		cat "$LOGFILE" > "${ERRORSFILE}_${RUN_TIMESTAMP}"
	fi
	cat /dev/null > "$LOGFILE"
}

need_to_read_eeprom() {
	[ "$FAILED" == "1" ] || ! have_eeprom_vars_loaded
}

inc_fail_stats() {
	local serial="$1"
	let FAILED_CNT='FAILED_CNT + 1'
	echo "PASSED_CNT=$PASSED_CNT" > $STATSFILE
	echo "FAILED_CNT=$FAILED_CNT" >> $STATSFILE
	[ -z "$serial" ] || echo "FAILED $serial" >> $RESULTSFILE
}

inc_pass_stats() {
	local serial="$1"
	let PASSED_CNT='PASSED_CNT + 1'
	echo "PASSED_CNT=$PASSED_CNT" > $STATSFILE
	echo "FAILED_CNT=$FAILED_CNT" >> $STATSFILE
	echo "PASSED $serial" >> $RESULTSFILE
	console_ascii_passed
}

console_ascii_passed() {
	echo_green "$(cat $SCRIPT_DIR/lib/passed.ascii)"
}

console_ascii_failed() {
	echo_red "$(cat $SCRIPT_DIR/lib/failed.ascii)"
}

wait_for_eeprom_vars() {
	DONT_SHOW_EEPROM_MESSAGES=1
	if need_to_read_eeprom ; then
		echo_green "Loading settings from EEPROM"
		eeprom_cfg load || {
			echo_red "Failed to load settings from EEPROM."
			echo_red "Plug in a board with EEPROM vars configured to continue..."
			echo
		}
		while ! eeprom_cfg load &> /dev/null ; do
			sleep 1
			continue
		done
		show_eeprom_vars
	fi
}

wait_for_firmware_files() {
	local target="$1"
	local ver_file="$SCRIPT_DIR/release/$target/version"
	FW_VERSION="$(cat $ver_file)"
	if ! have_all_firmware_files "$target" || [ -z "$FW_VERSION" ] ; then
		echo_red "Firmware files not found, please add them to continue..."
		while ! have_all_firmware_files "$target" || [ ! -f "$ver_file" ]
		do
			sleep 1
		done
	fi
	FW_VERSION="$(cat $ver_file)"
}

#----------------------------------#
# Main section                     #
#----------------------------------#

production() {
	local mode="$1"

	cd "$SCRIPT_DIR"
	
	source $SCRIPT_DIR/lib/m2k_addon_tests.sh
	source $SCRIPT_DIR/lib/m2k_check.sh

	# State variables; are set during state transitions
	local PASSED=0
	local FAILED=0
	local READY=0
	local PROGRESS=0

	# This will store in a `log` directory the following files:
	# * _results.log - each device that has passed or failed with S/N
	#    they will only show up here if they got a S/N, so this assumes
	#    that flashing worked
	# * _errors.log - all errors that don't yet have a S/N
	# * _stats.log - number of PASSED & FAILED
	local LOGDIR=$SCRIPT_DIR/log
	local LOGFILE=$LOGDIR/temp.log # temp log to store stuff, before we know the S/N of device
	local ERRORSFILE=$LOGDIR/_errors.log # errors that cannot be mapped to any device (because no S/N)
	local STATSFILE=$LOGDIR/_stats.log # stats ; how many passes/fails
	local RESULTSFILE=$LOGDIR/_results.log # format is "<BOARD S/N> = OK/FAILED"
	local PREVIOUSCMD=""

	# Remove temp log file start (if it exists)
	rm -f "$LOGFILE"

	mkdir -p $LOGDIR
	exec &> >(tee -a "$LOGFILE")

	while true ; do

		if [ "$mode" == "single" ] ; then
			[ "$PASSED" == "1" ] && return 0
			[ "$FAILED" == "1" ] && return 1
		fi

		mkdir -p $LOGDIR
		sync

		if [ "$PREVIOUSCMD" == "" ]; then
			echo_green "Waiting for start command [bnc/pwr]:"
			while true
			do
				read -p "" BOARD
				PREVIOUSCMD="$BOARD"
				case $BOARD in
				[bB][nN][cC])  #echo_green "BNC adapter"
							break;;
				[pP][wW][rR])  #echo_red "PWR adapter"
							break;;
				* )         echo_green "Please enter BNC or PWR!"
				esac
			done
		else
			echo_green "Running previous command: " "$PREVIOUSCMD"
			BOARD="$PREVIOUSCMD"
		fi

		RUN_TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"

		! check_and_reboot "$LOGFILE" || break

		if [ -f "$STATSFILE" ] ; then
			source $STATSFILE
		fi
		[ -n "$PASSED_CNT" ] || PASSED_CNT=0
		[ -n "$FAILED_CNT" ] || FAILED_CNT=0

		# TODO: handle the M2K calibration here (check if already calibrated)
		# then don't calibrate again
		# display M2K info here, fw version, calibration params, etc;
		m2k_pre_check || {
			echo_red "M2K pre-check step failed..."
			handle_error_state "$BOARD_SERIAL"
			sleep 1
			continue
		}
		
		
		BOARD="${BOARD,,}"
		board_upcase="${BOARD^^}"
		
		addon_test_${BOARD} || {
			handle_error_state "$BOARD_SERIAL"
			sleep 1
			echo_red "UNPLUG THE AD-M2K${board_upcase}-EBZ board"
			echo_red "Press enter to continue the tests"
			read line
			continue
		}
		
		terminate_any_lingering_stuff
		echo
		echo_green "PASSED ALL TESTS"

		#disable_all_usb_ports
		#inc_pass_stats "$BOARD_SERIAL"
		cat "$LOGFILE" > "$LOGDIR/passed_${BOARD_SERIAL}_${RUN_TIMESTAMP}.log"
		cat /dev/null > "$LOGFILE"
		PASSED=1
		console_ascii_passed
		echo_green "UNPLUG THE AD-M2K${board_upcase}-EBZ board"
		echo_green "Press enter to continue the tests"
		read line
	done
}
