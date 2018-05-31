#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source config.sh

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
		exit 1
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
			exit 1
		}
		let cnt='cnt + 1'
	done
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
	echo_green "   Measuring voltages with board off"
	disable_all_usb_ports
	power_cycle_sleep
	check_voltage_ranges "BOARD_OFF"
	echo_green "   .Done"
}

power_on_usb_1_and_measure() {
	echo_green "   Measuring voltages with USB port 1 enabled"
	disable_all_usb_ports
	power_cycle_sleep
	enable_usb_port_1
	power_cycle_sleep
	check_voltage_ranges "BOARD_ON"
	echo_green "   .Done"
}

power_on_usb_2_and_measure() {
	echo_green "   Measuring voltages with USB port 2 enabled"
	disable_all_usb_ports
	power_cycle_sleep
	enable_usb_port_2
	power_cycle_sleep
	check_voltage_ranges "BOARD_ON"
	echo_green "   .Done"
}

#----------------------------------#
# Main section                     #
#----------------------------------#

BOARD="$1"

[ -f "config/$BOARD/values.sh" ] || {
	echo_red "File 'config/$BOARD/values.sh' does not exist"
	exit 1
}

source config/$BOARD/values.sh

for ranges in BOARD_OFF BOARD_ON ; do
	validate_range_values 16 $ranges || exit 1
done

for measure_cnt in $(seq 1 $MEASUREMENT_CYCLES); do
	echo_blue "Running measurement cycle $measure_cnt"
	power_off_and_measure
	power_on_usb_1_and_measure
	power_on_usb_2_and_measure
done

exit 0
