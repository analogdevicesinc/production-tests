#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh

JIG_NAME="$(jigname)"

while true ; do

	# take the first `autosave_logs` folder
	dir=$(sudo find /media -type d -name SAVE_LOGS | head -1)
	[ -z "$dir" ] || {
		FILENAME="${dir}/${JIG_NAME}.$(date +%Y-%m-%d_%H-%M).tar.gz"
		save_logfiles_to "$SCRIPT_DIR/log" "$FILENAME" &> /dev/null
		pushd ${dir} &> /dev/null
		# keep only 5 files
		rm -f $(ls -1t . | tail -n +6)
		popd &> /dev/null
		sync &> /dev/null
		sleep 60
	}

	sleep 5
done
