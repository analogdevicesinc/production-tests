#!/bin/bash

source config.sh

#----------------------------------#
# Main section                     #
#----------------------------------#

init_pins

./lib/preflash.sh "pluto" || exit 1

./lib/flash.sh "pluto" || exit 1

./config/pluto/postflash.sh "dont_power_cycle_on_start" || exit 1
