#!/bin/bash

source $SCRIPT_DIR/config.sh

check_pos_range() {
	local meas="$1"
	[ -n "$meas" ] || return 1
	if value_in_range "$meas" "0.085" "0.115" ; then
		return 0
	fi
	if value_in_range "$meas" "4.4" "4.6" ; then
		return 0
	fi
	return 1
}

check_neg_range() {
	local meas="$1"
	[ -n "$meas" ] || return 1
	if value_in_range "$meas" "-0.115" "0.085" ; then
		return 0
	fi
	if value_in_range "$meas" "-4.6" "-4.4" ; then
		return 0
	fi
	return 1
}

m2k_power_calib_meas() {
	local ch="$1"
	local pos="${2:-pos}"
	local SAMPLES=128
	local meas
	local timeout=20

	if [ "$pos" != "neg" ] && [ "$pos" != "pos" ] ; then
		echo "failed - invalid pos/neg arg"
		return 1
	fi

	meas=$(measure_voltage_democratic "$ch" "$SAMPLES" m2k 64)
	while ! check_${pos}_range "$meas" && [ "$timeout" -gt 0 ] ; do
		meas=$(measure_voltage_democratic "$ch" "$SAMPLES" m2k 64)
		let timeout='timeout - 1'
	done

	if ! check_${pos}_range "$meas" ; then
		echo "failed - out of range '$meas'"
		return 1
	fi

	echo $meas
	return 0
}
