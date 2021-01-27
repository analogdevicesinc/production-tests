#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh

SRV_DST=jig@testjig.hopto.org

JIG_NAME="$(jigname)"
CNT=0

while true ; do

	tempfile="$(mktemp)"

	save_logfiles_to "$SCRIPT_DIR/log" "$tempfile" &> /dev/null

	if [ -n "$oldfile" ] && diff "$oldfile" "$tempfile" &> /dev/null ; then
		rm -f "$tempfile"
		sleep 300
		continue
	fi

	FILENAME="${JIG_NAME}.$(date +%Y-%m-%d_%H-%M).${CNT}.tar.gz"
	if ! scp -o StrictHostKeyChecking=no -i "$SCRIPT_DIR/config/jig_id" -P 2222 $tempfile ${SRV_DST}:jiglogs/${FILENAME} &> /dev/null ; then
		sleep 300
		continue
	fi

	ssh -o StrictHostKeyChecking=no -i "$SCRIPT_DIR/config/jig_id" -p 2222 ${SRV_DST} "cd jiglogs && rm -f \$(ls -1t ${JIG_NAME}.* | tail -n +6)" &> /dev/null

	let CNT='CNT + 1'
	rm -f "$oldfile"
	oldfile="$tempfile"

	sleep 300
done
