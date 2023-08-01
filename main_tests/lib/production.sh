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
		read BOARD_SERIAL_TEMP
		BOARD_SERIAL=${BOARD_SERIAL_TEMP// /}
		echo $BOARD_SERIAL | grep "S[0-9][0-9]" | grep "SN" &>/dev/null
		IS_OKBOARD=$?
	done
}

get_fmcomms_serial() {
	BOARD_SERIAL=$(ssh_cmd "sudo fru-dump -i /sys/devices/soc0/fpga-axi@0/41600000.i2c/i2c-0/i2c-7/7-0050/eeprom -b | grep 'Serial Number' | cut -d' ' -f3 | tr -d '[:cntrl:]'")
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

check_conn(){
	while true; do
		if ping -q -c3 -w50 analogdut.local &>/dev/null
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

        case $MODE in
		"Test Jupiter Main Board")
			ssh_cmd " sudo /home/analog/jupiter/test_poe.sh";
			ssh_cmd "sudo reboot";
			sleep 10;
			ssh_cmd " sudo /home/analog/jupiter/test_power_usb1.sh";
			ssh_cmd "sudo reboot";
			sleep 10;
                        ssh_cmd "sudo /home/analog/jupiter/main_board_test.sh $BOARD_SERIAL";
			
			$SCRIPT_DIR/test_uart.sh;
			$SCRIPT_DIR/test_usb_periph.sh;
                        if [ $? -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi
                        ;;
		"Test Jupiter Add-On Board")
                        $SCRIPT_DIR/jupiter/addon_rf_test.sh $BOARD_SERIAL
                        if [ $? -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi
                        ;;
		"FMCOMMS5 Test")
                        $SCRIPT_DIR/fmcomms5/rf_test.sh $BOARD_SERIAL
                        if [ $? -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi
                        ;;
                "FMCOMMS4 Test")
			ssh_cmd "sudo fru-dump -i /sys/devices/soc0/fpga-axi@0/41600000.i2c/i2c-0/i2c-7/7-0050/eeprom -b | grep 'Tuning' | cut -d' ' -f4 | tr -d '[:cntrl:]'"
			CALIB_DONE=$?

			if [ $CALIB_DONE -ne 0 ]; then
				printf "\033[1;31mPlease run calibration first\033[m\n"
				handle_error_state "$BOARD_SERIAL"
			fi
                        $SCRIPT_DIR/fmcomms4/rf_test.sh
                        if [ $? -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi
                        ;;
		"DCXO Calibration Test")
                        $SCRIPT_DIR/fmcomms4/dcxo_test.sh
						res=$?
                        if [ $res -eq 2 ]; then
                                handle_skipped_state "$BOARD_SERIAL"
						else
							if [ $res -eq 1 ]; then
								handle_error_state "$BOARD_SERIAL"
							else
								echo_red "Now please procced with the FMCOMMS4 tests (2)"
							fi
                        fi
                        ;;
		"ADRV1 Carrier Test")
                        $SCRIPT_DIR/adrv1_crr_test/test_usb_periph.sh
						FAILED_USB=$?
						if [ $FAILED_USB -ne 255 ]; then
                        	$SCRIPT_DIR/adrv1_crr_test/test_uart.sh
							FAILED_UART=$?
							if [ $FAILED_UART -ne 255 ]; then
                        		ssh_cmd "sudo /home/analog/adrv1_crr_test/crr_test.sh"
							fi
						fi
						FAILED_TESTS=$?
                        if [ $FAILED_TESTS -ne 0 ] || [ $FAILED_USB -ne 0 ] || [ $FAILED_UART -ne 0 ]; then
                                handle_error_state "$BOARD_SERIAL"
                        fi
                        ;;
		"Synchrona Production Test")
			ssh_cmd "sudo /home/analog/synch/synch_test.sh $BOARD_SERIAL"
			FAILED_TESTS=$?
			if [ $FAILED_TESTS -ne 255 ]; then
				$SCRIPT_DIR/synch/uart_test.sh 
				FAILED_UART=$?
				if [ $FAILED_UART -ne 255 ]; then
					$SCRIPT_DIR/synch/spi_test.sh
					FAILED_SPI=$?
					if [ $FAILED_SPI -ne 255 ]; then
						$SCRIPT_DIR/synch/misc_test.sh
						FAILED_MISC=$?
					fi
				fi
			fi
			if [ $FAILED_TESTS -ne 0 ] || [ $FAILED_UART -ne 0 ] || [ $FAILED_SPI -ne 0 ] || [ $FAILED_MISC -ne 0 ]; then
					handle_error_state "$BOARD_SERIAL"
			fi

			BIN_PATH="/lib/firmware/raspberrypi/bootloader/stable/pieeprom-2021-07-06.bin" #latest rpi stable image
			;;
		"ADRV9361 Test")
			$SCRIPT_DIR/adrv9361_bob/init_board.sh;
			wait_for_board_online
			ssh_cmd "sudo /home/analog/adrv9361_bob/breakout_test.sh"
			FAILED_MISC=$?
			if [ $FAILED_MISC -ne 255 ]; then
				$SCRIPT_DIR/adrv9361_bob/test_uart.sh
				FAILED_UART=$?
				if [ $FAILED_UART -ne 255 ]; then
					$SCRIPT_DIR/adrv9361_bob/rf_test.sh
					FAILED_TESTS=$?
				fi
			fi
			if [ $FAILED_TESTS -ne 0 ] || [ $FAILED_UART -ne 0 ] || [ $FAILED_MISC -ne 0 ]; then
								handle_error_state "$BOARD_SERIAL"
						fi
                        ;;
		"ADRV9364 Test")
			$SCRIPT_DIR/adrv9364_bob/dcxo_test.sh
			FAILED_DCXO=$?
			if [ $FAILED_DCXO -ne 255 ]; then
				$SCRIPT_DIR/adrv9364_bob/rf_test.sh
				FAILED_TESTS=$?
	
				if [ $FAILED_TESTS -ne 255 ]; then
					$SCRIPT_DIR/adrv9364_bob/test_uart.sh
					FAILED_UART=$?
					if [ $FAILED_UART -ne 255 ]; then
						ssh_cmd "sudo /home/analog/adrv9364_bob/adrv9364_test.sh"
						FAILED_MISC=$?
					fi
				fi
				if [ $FAILED_TESTS -ne 0 ] || [ $FAILED_UART -ne 0 ] || [ $FAILED_MISC -ne 0 ] || [ $FAILED_DCXO -ne 0 ]; then
					handle_error_state "$BOARD_SERIAL"
				else
					$SCRIPT_DIR/adrv9364_bob/write_mac_env.sh;
					wait_for_board_online
				fi
			fi
			;;
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
		console_ascii_passed
		if [ $SYNCHRONIZATION -eq 0 ]; then
			cat "$LOGFILE" > "$LOGDIR/passed_${BOARD_SERIAL}_${RUN_TIMESTAMP}.log"
		else
			cat "$LOGFILE" > "$LOGDIR/no_date_passed_${BOARD_SERIAL}_${RUN_TIMESTAMP}.log"
		fi
		cat /dev/null > "$LOGFILE"
	fi
	telemetry prod-logs-upload --tdir $LOGDIR > $SCRIPT_DIR/telemetry_out.txt
	cat $SCRIPT_DIR/telemetry_out.txt | grep "Authentication failed"
	if [ $? -eq 0 ]; then
		rm -rf $SCRIPT_DIR/password.txt
	fi
	rm -rf $SCRIPT_DIR/telemetry_out.txt
}

