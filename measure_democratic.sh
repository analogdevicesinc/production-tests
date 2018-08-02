#!/bin/bash

# Wrapper script for doing a measurement with the AD7616 ADC on the
#  production board.
# Similar to measure.sh, but with the option to do a "democratic" election
#  of a value, given a certain sample size.
# The idea is that measurements are not always consistent on some channels
#  due to electrical conditions, however some values do come out as predominant
#  so we take those values are "democratically" elected.
# Only allowed for a single channel.
#
# Can be called with:  ./measure_democratic.sh [chan] [no-samples] [device_or_ranges] [min_cnt] 
#   Where `chan` can be V0A, V1A, ... V7A, V0B, V1B, .. V7B 
#   If unspecified, it's an error
#   The number of samples can be specified, to do multiple measurement
#   and average them. If unspecified, the NUM_SAMPLES in config.sh is used
#
#   The 3rd parameter can be either 'device' (only m2k for now)
#   or the voltage ranges for each channel.
#   Example: ./measure.sh all "2.5V 2.5V 10V 5V 10V 10V 2.5V 5V 2.5V 2.5V 10V 5V 10V 5V 5V 10V"

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/config.sh

measure_voltage_democratic $@
