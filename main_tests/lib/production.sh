#!/bin/bash

source $SCRIPT_DIR/config.sh

#----------------------------------#
# Functions section                #
#----------------------------------#

show_ready_state() {
	PROGRESS=0
	READY=1
}

show_start_state() {
	PASSED=0
	READY=0
	FAILED=0
	PROGRESS=1
	FAILED_NO=0
}

get_board_serial() {
	IS_OKBOARD=1
	while [ $IS_OKBOARD -ne 0 ]; do
		echo "Please use the scanner to scan the QR/Barcode on your carrier"
		read BOARD_SERIAL
		echo $BOARD_SERIAL | grep "S[0-9][0-9]" | grep "SN" &>/dev/null
		IS_OKBOARD=$?
	done
}

dut_date_sync() {
	CURR_DATE="@$(date +%s)"
	ssh_cmd "sudo date -s '$CURR_DATE'"
}

handle_error_state() {
	local serial="$1"
	FAILED=1
	console_ascii_failed
	if [ $SYNCHRONIZATION -eq 0 ]; then 
		cat "$LOGFILE" > "$LOGDIR/failed_${serial}_${RUN_TIMESTAMP}.log"
	else
		cat "$LOGFILE" > "$LOGDIR/no_date_failed_${serial}_${RUN_TIMESTAMP}.log"
	fi
	cat /dev/null > "$LOGFILE"
}

handle_skipped_state() {
	local serial="$1"
	FAILED=1
	echo_blue "CALIBRATION WAS SKIPPED. POSSIBLY DUE TO INCOMPATIBLE DEVICE OR LONG INITIALIZATION. PLEASE MAKE SURE YOU USE THE SPECIFIED FREQUENCY COUNTER HAMEG HM8123, 5.12 AND TRY AGAIN"
	if [ $SYNCHRONIZATION -eq 0 ]; then 
		cat "$LOGFILE" > "$LOGDIR/skipped_${serial}_${RUN_TIMESTAMP}.log"
	else
		cat "$LOGFILE" > "$LOGDIR/no_date_skipped_${serial}_${RUN_TIMESTAMP}.log"
	fi
	cat /dev/null > "$LOGFILE"
}

need_to_read_eeprom() {
	[ "$FAILED" == "1" ] || ! have_eeprom_vars_loaded
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
		echo_green "Loading settings frogetm EEPROM"
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
#set analog.local as param
check_conn(){
	while true; do
		if ping -q -c3 -w50 analog.local &>/dev/null
		then
			echo_blue "Connection to DUT OK"
			break
		else
			echo_red "Check ethernet connection to DUT"
		fi
	done
}

start_gps_spoofing(){
	local GPSDIR=$SCRIPT_DIR/src/gps-sdr-sim/player
	if ping -q -c2 pluto.local &>/dev/null
	then
		[ -d $GPSDIR ] || return 1
		pushd $GPSDIR
		./plutoplayer -t ../gpssim.bin -a -60 &>/dev/null &
		popd
	else
		echo_red "Pluto GPS spoofer not connected to PI."
		return 1
	fi
}

stop_gps_spoofing(){
	pkill plutoplayer &>/dev/null
}

#----------------------------------#
# Main section                     #
#----------------------------------#

production() {
        local TARGET="$1"
        local MODE="$2"
		local BOARD="$3"
		local IIO_REMOTE=analog.local 

        [ -n "$TARGET" ] || {
                echo_red "No target specified"
                return 1
        }
        local target_upper=$(toupper "$TARGET")

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

		export DBSERVER="cluster0.oiqey.mongodb.net"
		export DBUSERNAME="dev_production1"
		export DBNAME="dev_${BOARD}_prod"
		export BOARD_NAME="$BOARD"

        local LOGDIR=$SCRIPT_DIR/log
		# temp log to store stuff, before we know the S/N of device
        local LOGFILE=$LOGDIR/temp.log
        # Remove temp log file start (if it exists)
        rm -f "$LOGFILE"

        mkdir -p $LOGDIR
        exec &> >(tee -a "$LOGFILE")

	sync

	# TBD ready state - connection, other settings

	RUN_TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"

	if [ -f $SCRIPT_DIR/password.txt ]; then
		export DBPASSWORD=$(cat $SCRIPT_DIR/password.txt)
	else
		echo "Please input the password provided for storing log files remotely"
		read PASSWD
		echo $PASSWD > $SCRIPT_DIR/password.txt
		export DBPASSWORD=$(cat $SCRIPT_DIR/password.txt)
	fi

	

	timedatectl | grep "synchronized: yes"
	SYNCHRONIZATION=$?
	if [ $SYNCHRONIZATION -ne 0 ]; then
		echo_red "Your time and date is not up-to-date. The times of the logs will be inaccurate. The corresponding log files will begin with \"no_date\""
	fi

	./${BOARD,,}/production.sh $MODE

        if [ -f "$STATSFILE" ] ; then
                source $STATSFILE
        fi

	if [ "$FAILED" == "0" ] ; then
		console_ascii_passed
		if [ $SYNCHRONIZATION -eq 0 ]; then
			cat "$LOGFILE" > "$LOGDIR/passed_${BOARD_SERIAL}_${RUN_TIMESTAMP}.log"
		else
			cat "$LOGFILE" > "$LOGDIR/no_date_passed_${BOARD_SERIAL}_${RUN_TIMESTAMP}.log"
		fi
		cat /dev/null > "$LOGFILE"
	fi
	telemetry prod-logs-upload --tdir $LOGDIR &> $SCRIPT_DIR/telemetry_out.txt
	cat $SRIPT_DIR/telemetry_out.txt | grep "Authentication failed"
	if [ $? -eq 0 ]; then
		rm -rf $SCRIPT_DIR/password.txt
	fi
	rm -rf $SRIPT_DIR/telemetry_out.txt
}

