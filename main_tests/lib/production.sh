#!/bin/bash

source $SCRIPT_DIR/config.sh

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

	/home/analog/production-tests/main_tests/${BOARD,,}/production.sh $MODE

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

