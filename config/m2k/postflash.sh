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
	terminate_any_lingering scopy
	terminate_any_lingering wait_pins
}

reboot_via_ssh() {
	sshpass -panalog ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oCheckHostIP=no root@192.168.2.1 /sbin/reboot
}

#----------------------------------#
# Main section                     #
#----------------------------------#

post_flash() {
	force_terminate_programs
	terminate_any_lingering_stuff

	# FIXME: see why this doesn't work
	#echo_green "0. Enabling USB data port"
	#enable_usb_data_port

	echo_green "0. Enabling all USB ports"
	enable_all_usb_ports

	echo_green "1. Waiting for board to come online (timeout $BOARD_ONLINE_TIMEOUT seconds)"
	wait_for_board_online || {
		terminate_any_lingering_stuff
		echo_red "Board did not come online"
		return 1
	}

	BOARD_SERIAL=$(get_hwserial 20)
	[ -n "$BOARD_SERIAL" ] || {
		echo_red "Could not get device serial number"
		return 1
	}
	export BOARD_SERIAL

	echo_green "2. Testing Linux"
	retry 4 expect $SCRIPT_DIR/config/m2k/linux.exp "$TTYUSB" || {
		echo
		echo_red "   Linux test failed"
		return 1
	}

	echo_green "3. Testing Scopy -- Part 1"
	scopy --nogui --script $SCRIPT_DIR/config/m2k/scopy1.js || {
		terminate_any_lingering_stuff
		echo_red "Scopy tests have failed..."
		return 1
	}

	echo_green "3.1. Ejecting M2K to apply calibration parameters..."
	umount "/media/jig/M2k" || {
		terminate_any_lingering_stuff
		echo_red "Scopy tests have failed..."
		return 1
	}

	echo_green "3.2. Waiting for board to come online (timeout $BOARD_ONLINE_TIMEOUT seconds)"
	wait_for_board_online || {
		terminate_any_lingering_stuff
		echo_red "Board did not come online"
		return 1
	}

	echo_green "4. Testing Scopy -- Part 2"
	scopy --script $SCRIPT_DIR/config/m2k/scopy2.js || {
		terminate_any_lingering_stuff
		echo_red "Scopy tests have failed..."
		return 1
	}

	terminate_any_lingering_stuff

	echo
	echo_green "PASSED ALL TESTS"
	return 0
}
