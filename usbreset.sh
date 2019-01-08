#!/bin/bash

# Wrapper script for resetting USB devices
#
# Can be called with:  ./usbreset.sh [vid] [did]
#
# If [vid] is all, then all devices will be reset.
# Otherwise all devices matching [vid] and [did], i.e.
# Vendor ID and Device ID.

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh

#----------------------------------#
# Main section                     #
#----------------------------------#

usbreset $@
