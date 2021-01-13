#!/bin/bash

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/config/m2k/power_calib_meas.sh

m2k_power_calib_meas $@
