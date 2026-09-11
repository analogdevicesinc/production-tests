#!/bin/bash

RED='\033[0;31m\033[1m'
GREEN='\033[0;32m\033[1m'
NC='\033[0m'

TIMED_LOG_SUFFIX=""
function date_time() {
echo $(date --iso-8601=seconds)
}

function timed_log() {

timestamp=$(date_time)
echo -e [ $timestamp ] -- $TIMED_LOG_SUFFIX - $1

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
read -r -p "Press Enter when ready"
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

function run_test() { # params test_number short_desc test_cmd not_retest
echo $TEST_NAME"_"$1
TIMED_LOG_SUFFIX=$TEST_NAME"_"$1
timed_log "$2"
eval "$3"
answer=$?

if [ "$answer" -ne 0 ] && [ -z "$4" ]
then
	until [ "$answer" -eq 0 ]
	do
		YES_no "${RED}TEST FAILED${NC} - Do you want to repeat test?"
		if [ $? -eq 1 ]
		then
			YES_no "Do you want to close the test?"
			if [ $? -eq 0 ]
			then
				FAIL_COUNT=255
				exit 255
			else
				let "FAIL_COUNT+=1"
				break
			fi
		fi
		eval "$3"
		answer=$?
	done
fi

proceed_if_ok $answer "${RED}FAIL${NC}" "${GREEN}OK${NC}"
echo "----------------------------------------------------------------------------------"
}

function failed_no(){
	return $FAIL_COUNT
}