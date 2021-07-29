#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source $SCRIPT_DIR/config.sh

#----------------------------------#
# Functions section                #
#----------------------------------#

terminate_pgrep() {
	for pid in $(pgrep $1) ; do
		kill -9 "$pid"
	done
}

terminate_any_lingering() {
	local pname="$1" # full or partial process name
	local pids
	terminate_pgrep $pname
	pids="$(pgrep $pname)"
	while [ -n "$pids" ] ; do
		terminate_pgrep $pname
		pids="$(pgrep $pname)"
		for pid in $pids ; do
			local ppid="$(ps -o ppid= $pid)"
			[ -n "$ppid" ] || continue
			# try to terminate parent pid in case zombie process
			kill -9 "$ppid"
		done
	done
}

terminate_any_lingering_stuff() {
	terminate_any_lingering ad-m2kpwr-ebz-test.py
	terminate_any_lingering ad-m2kbnc-ebz-test.py
}

#----------------------------------#
# Main section                     #
#----------------------------------#

addon_test_pwr() {
	force_terminate_programs
	terminate_any_lingering_stuff

	echo_green "2. Testing AD-M2KPWR-EBZ board"
	powercycle_board_wait
	python3 -u $SCRIPT_DIR/config/ad-m2kpwr-ebz-test.py || {
		terminate_any_lingering_stuff
		echo_red "AD-M2KPWR-EBZ tests have failed..."
		return 1
	}
	
	terminate_any_lingering_stuff
	return 0
}

addon_test_bnc() {
	force_terminate_programs
	terminate_any_lingering_stuff

	echo_green "2. Testing AD-M2KBNC-EBZ board"
	powercycle_board_wait
	python3 -u $SCRIPT_DIR/config/ad-m2kbnc-ebz-test.py || {
		terminate_any_lingering_stuff
		echo_red "AD-M2KBNC-EBZ tests have failed..."
		return 1
	}

	terminate_any_lingering_stuff
	return 0
}
