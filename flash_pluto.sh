#!/bin/bash

# Wrapper script for flashing a Pluto board
# This script only handles flashing, no extra steps.
#
# Can be called with:  ./flash_pluto.sh
#
# The ./update_pluto_release.sh must be called to update release files

source lib/utils.sh

#----------------------------------#
# Main section                     #
#----------------------------------#

init_pins A

./lib/flash.sh "pluto"
