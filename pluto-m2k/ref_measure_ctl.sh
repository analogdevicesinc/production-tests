#!/bin/bash
  
# Wrapper script for controlling the reference measurement for M2k.
#
# Can be called with:  ./ref_measure_ctl.sh <op>
# 'op' is 'ref10v' or 'ref2.5v' or 'disable'
#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/config.sh

ref_measure_ctl "$1"
