#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

if [ ! -t 1 ] ; then
	echo "Not in a terminal"
	exit 1
fi

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh

# If we're supposed to run in TTY mode-only, and we're in shell,
# exit gracefully here with exit 1
if [ "$1" == "tty" ] && [ -n "$SSH_TTY" ] ; then
	echo_red "This looks like an SSH context, will not run script"
	exit 1
fi

M1000_BIN="$SCRIPT_DIR/release/m1k/m1000.bin"

# Export these ; we may need them in the Python scripts
export LOGDIR=$SCRIPT_DIR/log
export LOGFILE=$LOGDIR/temp.log # temp log to store stuff, before we know the S/N of device
export STATSFILE=$LOGDIR/_stats.log # stats ; how many passes/fails
export RESULTSFILE=$LOGDIR/_results.log # format is "<BOARD S/N> = OK/FAILED"

if [ -f $STATSFILE ] ; then
	source $STATSFILE
fi
[ -n "$PASSED_CNT" ] || PASSED_CNT=0
[ -n "$FAILED_CNT" ] || FAILED_CNT=0

#----------------------------------#
# Functions section                #
#----------------------------------#

inc_fail_stats() {
	local serial="$1"
	let FAILED_CNT='FAILED_CNT + 1'
	echo "PASSED_CNT=$PASSED_CNT" > $STATSFILE
	echo "FAILED_CNT=$FAILED_CNT" >> $STATSFILE
	console_ascii_failed
	if [ -n "$serial" ] ; then
		mkdir -p "$LOGDIR/${serial}_${RUN_TIMESTAMP}"
		cat "$LOGFILE" > "$LOGDIR/${serial}_${RUN_TIMESTAMP}/execlog.txt"
		echo "FAILED $serial - ${RUN_TIMESTAMP}" >> $RESULTSFILE
		mv -f "$LOGDIR/${serial}_${RUN_TIMESTAMP}" \
			"$LOGDIR/failed_${serial}_${RUN_TIMESTAMP}"
	else
		cat "$LOGFILE" > "$LOGDIR/_errors_${RUN_TIMESTAMP}.log"
	fi
	cat /dev/null > "$LOGFILE"
}

inc_pass_stats() {
	local serial="$1"
	let PASSED_CNT='PASSED_CNT + 1'
	echo "PASSED_CNT=$PASSED_CNT" > $STATSFILE
	echo "FAILED_CNT=$FAILED_CNT" >> $STATSFILE
	echo "PASSED $serial - ${RUN_TIMESTAMP}" >> $RESULTSFILE
	clear
	console_ascii_passed
	mkdir -p "$LOGDIR/${serial}_${RUN_TIMESTAMP}"
	cat "$LOGFILE" > "$LOGDIR/${serial}_${RUN_TIMESTAMP}/execlog.txt"
	cat /dev/null > "$LOGFILE"
	mv -f "$LOGDIR/${serial}_${RUN_TIMESTAMP}" \
		"$LOGDIR/passed_${serial}_${RUN_TIMESTAMP}"
}

console_ascii_passed() {
	echo_green "$(cat $SCRIPT_DIR/lib/passed.ascii)"
}

console_ascii_failed() {
	echo_red "$(cat $SCRIPT_DIR/lib/failed.ascii)"
}

wait_for_firmware_files() {
	local FW_VER_FILE="$SCRIPT_DIR/release/m1k/version"
	FW_VERSION="$(cat $FW_VER_FILE)"
	if [ ! -f "$M1000_BIN" ] || [ -z "$FW_VERSION" ] ; then
		echo_red "Firmware files not found, please add them to continue..."
		while [ ! -f "$M1000_BIN" ] || [ ! -f "$FW_VER_FILE" ]
		do
			sleep 1
		done
	fi
	FW_VERSION="$(cat $FW_VER_FILE)"
}

turn_display() {
	local on="$1" # 1 - on , 0 - off
	sudo -s <<-EOF
		echo 18 > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio18/direction
		echo "$on" > /sys/class/gpio/gpio18/value
	EOF
}

handle_button() {
	local btn_message="$1"
	echo
	echo_yellow "Button '$btn_message' pressed"
	if [ "$btn_message" == "SHUTDOWN" ] ; then
		echo
		echo_green "Shutting down device..."
		echo
		sleep 2
		clear
		sudo poweroff
		exit 0
	fi

	if [ "$btn_message" == "RESTART" ] ; then
		echo
		echo_green "Restart device..."
		echo
		sleep 2
		clear
		sudo reboot
		exit 0
	fi
}

update_serial() {
	serial="$(get_device_serial_num)"
	[ -n "$serial" ] || return 1
	export serial
}

#----------------------------------#
# Main section                     #
#----------------------------------#

$SCRIPT_DIR/call_home &
$SCRIPT_DIR/autosave_logs.sh &
$SCRIPT_DIR/autoupload_logs.sh &

mkdir -p "$LOGDIR"
if [ -f "$LOGFILE" ] ; then
	export RUN_TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
	cat "$LOGFILE" > "$LOGDIR/_errors_${RUN_TIMESTAMP}.log"
fi

# reboot machine if we get a SIGTERM, or finish somehow
# trap reboot INT

exec &> >(tee -a "$LOGFILE")

pushd $SCRIPT_DIR &> /dev/null
while :
do
	wait_for_firmware_files
	echo_green "ADALM-1000 firmware version: $FW_VERSION"
	echo_green "  #23 for REBOOT      #27 for SHUTDOWN  "
	echo_yellow "Press button #17 to start."
	printf "   \033[1;32m$PASSED_CNT\033[m   \033[1;31m$FAILED_CNT\033[m"
	sync
	[ -z "$LAST_TIME" ] || {
		NOW="$(date +%s)"
		let ELAPSED='NOW - LAST_TIME'
		echo
		echo_blue "Last run took '$ELAPSED' seconds total"
	}
	button="$(${PYTHON} wait_button_pressed.py 2> /dev/null)"
	LAST_TIME="$(date +%s)"
	[ -n "$button" ] || {
		echo_red "Error while for button to be pressed"
		inc_fail_stats
		sleep 2
		continue
	}
	handle_button "$button"
	export RUN_TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
	run_with_timeout 25.0 ${PYTHON} main_measure_voltage.py "$M1000_BIN" || {
		echo_red "Measure voltage step failed..."
		inc_fail_stats
		sleep 2
		continue
	}
	retry 10 update_serial || {
		echo_red "Failed to obtain device serial number"
		inc_fail_stats
		sleep 2
		continue
	}
	run_with_timeout 20.0 ${PYTHON} main_source_voltage.py || {
		echo_red "Source voltage step failed..."
		inc_fail_stats "$serial"
		sleep 2
		continue
	}
	run_with_timeout 20.0 ${PYTHON} main_measure_current.py || {
		echo_red "Measure current step failed..."
		inc_fail_stats "$serial"
		sleep 2
		continue
	}
	run_with_timeout 20.0 ${PYTHON} main_source_current.py || {
		echo_red "Source current step failed..."
		inc_fail_stats "$serial"
		sleep 2
		continue
	}
	clear
	run_with_timeout 35.0 ${PYTHON} main_check_performances.py "$FW_VERSION" || {
		echo_red "Performance check step failed..."
		inc_fail_stats "$serial"
		sleep 2
		continue
	}
	inc_pass_stats "$serial"
done
# reboot
popd &> /dev/null
