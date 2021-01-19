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
}

get_board_serial() {
	BOARD_SERIAL=$(ssh_cmd "dmesg | grep SPI-NOR-UniqueID | cut -d' ' -f9 | tr -d '[:cntrl:]'")
}

get_fmcomms_serial() {
	BOARD_SERIAL=$(ssh_cmd "fru-dump -i /sys/devices/platform/amba/ff030000.i2c/i2c-1/i2c-8/8-0052/eeprom -b | grep 'Serial Number' | cut -d' ' -f3 | tr -d '[:cntrl:]'")
}

dut_date_sync() {
	CURR_DATE="@$(date +%s)"
	ssh_cmd "sudo date -s '$CURR_DATE'"
}

handle_error_state() {
	local serial="$1"
	FAILED=1
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

        local LOGDIR=$SCRIPT_DIR/log
	# temp log to store stuff, before we know the S/N of device
        local LOGFILE=$LOGDIR/temp.log
	# errors that cannot be mapped to any device (because no S/N)
        local ERRORSFILE=$LOGDIR/_errors.log
	# stats ; how many passes/fails
        local STATSFILE=$LOGDIR/_stats.log
	 # format is "<BOARD S/N> = OK/FAILED"
        local RESULTSFILE=$LOGDIR/_results.log

        # Remove temp log file start (if it exists)
        rm -f "$LOGFILE"

        mkdir -p $LOGDIR
        exec &> >(tee -a "$LOGFILE")

	sync

	# TBD ready state - connection, other settings

	RUN_TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"

        case $MODE in
                "ADRV Carrier Test")
                        $SCRIPT_DIR/adrv_crr_test/test_usb_periph.sh &&
                        $SCRIPT_DIR/adrv_crr_test/test_uart.sh &&
                        ssh_cmd "sudo /home/analog/adrv_crr_test/crr_test.sh"
                        if [ $? -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi
                        ;;
                "ADRV SOM Test")
                        ssh_cmd "sudo /home/analog/adrv_som_test/som_test.sh"
                        if [ $? -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi
                        ;;
                "ADRV FMCOMMS8 RF test")
                        ssh_cmd "sudo /home/analog/adrv_fmcomms8_test/fmcomms8_test.sh"
			RESULT=$?
			get_fmcomms_serial
			python3 -m pytest --color yes $SCRIPT_DIR/work/pyadi-iio/test/test_adrv9009_zu11eg_fmcomms8.py -v
                        if [ $? -ne 0 ] || [ $RESULT -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi
                        ;;
                *) echo "invalid option $MODE" ;;
        esac

        if [ -f "$STATSFILE" ] ; then
                source $STATSFILE
        fi

	if [ "$FAILED" == "0" ] ; then
        	inc_pass_stats "$BOARD_SERIAL"
        	cat "$LOGFILE" > "$LOGDIR/passed_${BOARD_SERIAL}_${RUN_TIMESTAMP}.log"
        	cat /dev/null > "$LOGFILE"
	fi
}

