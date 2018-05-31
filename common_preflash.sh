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
			echo_red "Value ($cnt) '$m' is not in range '$min..$max', or is invalid"
			exit 1
		}
		let cnt='cnt + 1'
	done
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

for measure_cnt in $(seq 1 $MEASUREMENT_CYCLES); do
	echo_blue "Running measurement cycle $measure_cnt"
	power_off_and_measure
	power_on_usb_1_and_measure
	power_on_usb_2_and_measure
done

exit 0
