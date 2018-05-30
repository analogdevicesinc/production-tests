#!/bin/bash

source config.sh

reset_adc || {
	echo_red "Failed to reset ADC"
	exit 1
}

# Do a dummy conversion
measure_voltage &> /dev/null || {
	echo_red "Failed during dummy conversion"
	exit 1
}

exit 0
