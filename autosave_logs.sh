#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/config.sh

[ -n "$JIG_NAME" ] || {
	echo_red "No name for test-jig define; define one in config.sh"
	exit 1
}

while true ; do

	# take the first `autosave_logs` folder
	dir=$(sudo find /media -type d -name autosave_logs | head -1)
	[ -z "$dir" ] || {
		savefile="${dir}/${JIG_NAME}.$(date +%Y-%m-%d).tar.gz"
		tmpfile="/tmp/${JIG_NAME}.$(date +%Y-%m-%d).tar.gz"
		tar -C "$SCRIPT_DIR/log" -zcvf "$tmpfile" .
		mv -f "$tmpfile" "$savefile"
		sync
		sleep 60
	}

	sleep 5
done
