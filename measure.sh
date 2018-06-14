#!/bin/bash

# Wrapper script for doing a measurement with the AD7616 ADC on the
#  production board.
#
# Can be called with:  ./measure.sh [chan]
#   Where `chan` can be V0A, V1A, ... V7A, V0B, V1B, .. V7B or `all`
#   If unspecified, `all` is used

source config.sh

measure_voltage $1
