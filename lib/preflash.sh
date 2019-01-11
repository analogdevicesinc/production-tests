#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source $SCRIPT_DIR/config.sh

# For now, do a single measurement cycle (i.e. power-off board,
# measure, power on USB1, measure, power on USB2 measure, etc
MEASUREMENT_CYCLES=1

#----------------------------------#
# Functions section                #
#----------------------------------#

get_label() {
	local idx="$1"
	get_item_from_list $idx $VLABELS
}

get_target_voltage() {
	local idx="$1"
	get_item_from_list $idx $TARGET_VOLTAGES
}

check_voltage_ranges() {
	# Use double indirection to get the variables
	eval "local voltages_min=\"\$$1_VMIN\""
	eval "local voltages_max=\"\$$1_VMAX\""
	local cnt=0

	local measured="$(measure_voltage all)"
	echo_blue "Values on channels: '$measured'"
	valid_numbers 16 $measured || {
		echo_red "Error when attempting to read voltages; did not get 16 values"
		return 1
	}

	for m in $measured ; do
		local label="$(get_label $cnt)"
		local target_voltage="$(get_target_voltage $cnt)"
		local min="$(get_item_from_list $cnt $voltages_min)"
		[ "$min" == "N/A" ] && {
			let cnt='cnt + 1'
			continue # skip this
		}
		local max="$(get_item_from_list $cnt $voltages_max)"
		[ "$max" == "N/A" ] && {
			let cnt='cnt + 1'
			continue # skip this
		}

		value_in_range "$m" "$min" "$max" || {
			echo_red "Value ($label) '$m' is not in range '$min..$max', or is invalid"
			echo_red "   Target voltage is '$target_voltage'"
			return 1
		}
		let cnt='cnt + 1'
	done
	return 0
}

validate_range_values() {
	local cnt=$1
	eval "local voltages_min=\"\$$2_VMIN\""
	eval "local voltages_max=\"\$$2_VMAX\""

	let cnt='cnt - 1'
	for cnt in $(seq 0 $cnt) ; do
		local label=$(get_label $cnt)
		local min="$(get_item_from_list $cnt $voltages_min)"
		if [ "$min" != "N/A" ] && ! is_valid_number "$min" ; then
			echo_red "Invalid number ($cnt) '$min' for $label in $2_VMIN"
			return 1
		fi
		local max="$(get_item_from_list $cnt $voltages_max)"
		if [ "$max" != "N/A" ] && ! is_valid_number "$max" ; then
			echo_red "Invalid number ($cnt) '$max' for $label in $2_VMAX"
			return 1
		fi
		let cnt='cnt - 1'
        done
        return 0

}

power_off_and_measure() {
	local retries="${1:-4}"
	echo_green "   Measuring voltages with board off"
	disable_all_usb_ports
	power_cycle_sleep
	retry "$retries" check_voltage_ranges "BOARD_OFF" || return 1
	echo_green "   .Done - values are within range"
}

power_on_usb_1_and_measure() {
	local retries="${1:-4}"
	echo_green "   Measuring voltages with USB port 1 enabled (Data cable)"
	disable_all_usb_ports
	power_cycle_sleep
	enable_usb_data_port
	power_cycle_sleep
	retry "$retries" check_voltage_ranges "BOARD_ON" || return 1
	echo_green "   .Done - values are within range"
}

power_on_usb_2_and_measure() {
	local retries="${1:-4}"
	echo_green "   Measuring voltages with USB port 2 enabled (Power cable)"
	disable_all_usb_ports
	power_cycle_sleep
	enable_usb_power_port
	power_cycle_sleep
	retry "$retries" check_voltage_ranges "BOARD_ON" || return 1
	echo_green "   .Done - values are within range"
}

call_hook() {
	if [ "$(type -t "$1")" == 'function' ] ; then
		$1
	fi
}

#----------------------------------#
# Main section                     #
#----------------------------------#

pre_flash() {
	BOARD="$1"

	[ -f "$SCRIPT_DIR/config/$BOARD/values.sh" ] || {
		echo_red "File 'config/$BOARD/values.sh' does not exist"
		return 1
	}

	source $SCRIPT_DIR/config/$BOARD/values.sh

	force_terminate_programs

	for ranges in BOARD_OFF BOARD_ON ; do
		validate_range_values 16 $ranges || return 1
	done

	call_hook pre_measure

	for measure_cnt in $(seq 1 $MEASUREMENT_CYCLES); do
		echo_blue "Running measurement cycle $measure_cnt"
		power_off_and_measure 10 || return 1
		power_on_usb_1_and_measure 10 || return 1
		power_on_usb_2_and_measure 10 || return 1
	done

	call_hook post_measure

	return 0
}
