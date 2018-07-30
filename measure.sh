#!/bin/bash

# Wrapper script for doing a measurement with the AD7616 ADC on the
#  production board.
#
# Can be called with:  ./measure.sh [chan] [no-samples]
#   Where `chan` can be V0A, V1A, ... V7A, V0B, V1B, .. V7B or `all`
#   If unspecified, `all` is used
#   The number of samples can be specified, to do multiple measurement
#   and average them. If unspecified, the NUM_SAMPLES in config.sh is used

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/config.sh

measure_voltage $@
