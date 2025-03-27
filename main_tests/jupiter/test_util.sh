#!/bin/bash

RED='\033[0;31m\033[1m'
GREEN='\033[0;32m\033[1m'
NC='\033[0m'
YELLOW="\033[0;33m\033[1m"

TIMED_LOG_SUFFIX=""
function date_time() {
echo $(date --iso-8601=seconds)
}

function timed_log() {

timestamp=$(date_time)
echo "------------------------------------------------------------------------------------"
echo -e "${YELLOW}$TEST_NAME${NC}"
echo "------------------------------------------------------------------------------------"
echo -e [ $timestamp ] -- $TIMED_LOG_SUFFIX - "${YELLOW}$1${NC}"

}

function timed_log_no_newline() {

timestamp=$(date_time)
echo -n -e [ $timestamp ] -- $TIMED_LOG_SUFFIX - $1
}

function YES_no() {
if [ -z "$1" ]
then
	str="Are you sure ?"
else
	str="$1"
fi
timed_log_no_newline "$str"
read -r -p "[Y/n]" response
case "$response" in
    [nN][oO]|[nN])
	return 1
	;;
    *)
	return 0
	;;
esac
}

function wait_enter() {
# echo -e "\033[5mPress Enter when ready\033[0m"
read -r -p "Press Enter when ready"
}

wait_for_board_online(){
	while true; do
		if timeout 30 bash -c "until ping -q -c3 analogdut.local &>/dev/null; do false; done"
		then
			echo "Connection to DUT OK"
			break
		else
			echo "Check ethernet connection to DUT"
		fi
	done
}

function proceed_if_ok() {
if [ -z "$1" ]
then
	echo "NO PARAM"
	return
fi

if [ $1 -ne 0 ]
then
	if [ -z "$2" ]
	then
		str="An error occurred"
	else
		str=$2
	fi
	timed_log "$str"
fi
if [ -n "$3" ] && [ $1 -eq 0 ]
then
	timed_log "$3"
fi
}


ssh_cmd() {
	local USER=analog
	local CLIENT=analogdut.local
	local PASS=analog
	local CMD="$1"

	[ -n "$CMD" ] || {
		echo "failed - no command"
	exit 1
	}

	[ -z "$2" ] || {
		$USER = $2
	}

	[ -z "$3" ] || {
		$CLIENT = $3
	}

	[ -z "$4" ] || {
		$PASS = $4
	}

	sshpass -p${PASS} ssh -q -t -oConnectTimeout=10 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oCheckHostIP=no "$USER"@"$CLIENT" "$CMD"
}

function run_test() { # params test_number short_desc test_cmd not_retest
TIMED_LOG_SUFFIX=$TEST_NAME"_"$1
timed_log "$2"
eval "$3"
answer=$?

if [ "$answer" -ne 0 ] && [ -z "$4" ]
then
	until [ "$answer" -eq 0 ]
	do
		echo -e "${RED}TEST FAILED${NC}"
		YES_no "Do you want to repeat test?"
		if [ $? -eq 1 ]
		then
			YES_no "Do you want to close the test?"
			if [ $? -eq 0 ]
			then
				FAIL_COUNT=255
				exit 255
			else
				FAIL_COUNT+=1
				break
			fi
		fi
		eval "$3"
		answer=$?
	done
fi

proceed_if_ok $answer "${RED}FAIL${NC}" "${GREEN}OK${NC}"
}

function failed_no(){
	return $FAIL_COUNT
}