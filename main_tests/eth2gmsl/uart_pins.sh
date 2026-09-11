#!/bin/bash
# This file needs to be on the board

SCRIPT_DIR="$(readlink -f $(dirname $0))"
source $SCRIPT_DIR/../lib/utils.sh

if ! ls /dev/ttyU* | grep -q "ttyUL0"; then
	echo "Error /dev/ttyUL0 does not exist. Exiting"
       exit 1
fi

cat /dev/ttyUL0 > log &

CAT_PID=$!

sleep 1

echo 10 > /dev/ttyUL0
sleep 1

kill $CAT_PID
wait $CAT_PID 2>/dev/null

if grep -q "10" log;then
	echo_green "PASSED"
	rm -f log
	exit 0
else
	echo_red "FAILED"
	rm -f log
	exit 1
fi
