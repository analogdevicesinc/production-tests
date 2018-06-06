#!/bin/bash

#----------------------------------#
# Main section                     #
#----------------------------------#

./lib/preflash.sh "pluto" || exit 1

./lib/flash.sh "pluto" || exit 1

./config/pluto/postflash.sh "dont_power_cycle_on_start" || exit 1
