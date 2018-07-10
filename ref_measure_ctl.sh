#!/bin/bash
  
# Wrapper script for controlling the reference measurement for M2k.
#
# Can be called with:  ./ref_measure_ctl.sh <op>
# 'op' is 'ref10v' or 'ref2.5v' or 'disable'
#

source config.sh

ref_measure_ctl "$1"
