#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

PYTHON="/usr/bin/python -u"

[ ! -d "$SCRIPT_DIR/work/libsmu/bindings/python/build" ] || \
	PYSMU_LIBDIR="$(readlink -f $SCRIPT_DIR/work/libsmu/bindings/python/build/lib*/pysmu/..)"
SMU_CLI_PATH="$SCRIPT_DIR/work/libsmu/build/src/cli"

PYTHONPATH="$(${PYTHON} -c "import sys; print(':'.join(sys.path))")"
PYTHONPATH="${PYTHONPATH}:${PYSMU_LIBDIR}"

export PYTHONPATH="$PYTHONPATH"
export LD_LIBRARY_PATH="$SCRIPT_DIR/work/libsmu/build/src/"
export PATH="$SMU_CLI_PATH:$PATH"
export PYTHONDONTWRITEBYTECODE=1

#----------------------------------#
# Functions section                #
#----------------------------------#

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }
echo_yellow() { printf "\033[1;33m$*\033[m\n"; }

__retry_common() {
	while [ "$retries" -gt 0 ] ; do
		# run the commands
		$@
		[ "$?" == "0" ] && return 0
		[ -z "$failfunc" ] || $failfunc
		echo_blue "   Retrying command ($retries): $@"
		sleep 1
		let retries='retries - 1'
	done
	echo_red "Command failed after $r1 retries: $@"
	return 1
}

retry() {
	local retries="$1"
	local r1="$retries"
	shift
	__retry_common $@
}

run_with_timeout() {
	local timeout="$1"
	shift
	local start end elapsed rc
	start="$(date +%s)"
	timeout $timeout $*
	rc=$?
	end="$(date +%s)"
	let elapsed='end - start'
	echo_blue "Elapsed '$elapsed' seconds"
	return $rc
}

get_item_from_list() {
	local idx=$1
	shift

	while [ "$idx" -gt 0 ] ; do
		let idx='idx - 1'
		shift
	done
	echo $1
}

get_device_serial_num() {
	get_item_from_list 2 $(smu -l | head -1)
}

get_device_fw_version() {
	get_item_from_list 5 $(smu -l | head -1)
}

__get_phys_netdevs() {
	for dev in /sys/class/net/*/device ; do echo $dev | cut -d'/' -f5 ; done
}

jigname() {
	local nm="$(cat /etc/hostname 2> /dev/null)"
	[ -n "$nm" ] || nm="jig1"
	local pi_serial="$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2)"
	if [ -n "$pi_serial" ] ; then
		echo "${nm}-${pi_serial}"
		return
	fi
	local dev="$(__get_phys_netdevs | sort | head -1)"
	if [ -z "$dev" ] ; then
		echo $nm
		return
	fi
	local addr=$(cat /sys/class/net/$dev/address | sed  's/://g')
	if [ -n "$addr" ] ; then
		echo "${nm}-${addr}"
		return
	fi
	echo $nm
}

save_logfiles_to() {
	local log_dir="$1"
	local savefile="$2"

	local tmpfile="$(mktemp)"
	tar -C "$log_dir" -zcvf "$tmpfile" .
	mv -f "$tmpfile" "$savefile"
}

