#!/bin/bash

# Wrapper script for flashing a SidekiqZ2 board
# This script only handles flashing, no extra steps.
#
# Can be called with:  ./flash_sidekiqz2.sh
#
# The files need to be present in the ./release/sidekiqz2 folder

#----------------------------------#
# Main section                     #
#----------------------------------#

source lib/flash.sh

flash "sidekiqz2" "DFU_ONLY"
