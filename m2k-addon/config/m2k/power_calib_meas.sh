#!/bin/bash

source $SCRIPT_DIR/config.sh

check_pos_range() {
	local meas="$1"
	local after_calibration="$2"
	[ -n "$meas" ] || return 1

	if $after_calibration == "true" ; then
		if value_in_range "$meas" "0.090" "0.110" ; then
			return 0
		fi
		if value_in_range "$meas" "4.4" "4.6" ; then
			return 0
		fi
	else
		if value_in_range "$meas" "0.050" "0.150" ; then
			return 0
		fi
		if value_in_range "$meas" "4.3" "4.7" ; then
			return 0
		fi
	fi
	return 1
}

check_neg_range() {
	local meas="$1"
	local after_calibration="$2"
	[ -n "$meas" ] || return 1

	if $after_calibration == "true" ; then
		if value_in_range "$meas" "-0.110" "-0.090" ; then
			return 0
		fi
		if value_in_range "$meas" "-4.6" "-4.4" ; then
			return 0
		fi
	else
		if value_in_range "$meas" "-0.150" "-0.050" ; then
			return 0
		fi
		if value_in_range "$meas" "-4.7" "-4.3" ; then
			return 0
		fi
	fi
	return 1
}

m2k_power_calib_meas() {
	local ch="$1"
	local pos="${2:-pos}"
	local meas
	local timeout=20
	local after_calibration="${3:-false}"

	if [ "$pos" != "neg" ] && [ "$pos" != "pos" ] ; then
		echo "failed - invalid pos/neg arg"
		return 1
	fi

	meas=$(measure_voltage "$ch" 1 m2k)
	while ! check_${pos}_range "$meas" "$after_calibration" && [ "$timeout" -gt 0 ] ; do
		meas=$(measure_voltage "$ch" 1 m2k)
		let timeout='timeout - 1'
	done

	if ! check_${pos}_range "$meas" "$after_calibration" ; then
		echo "failed - out of range '$meas'"
		return 1
	fi

	echo $meas
	return 0
}

