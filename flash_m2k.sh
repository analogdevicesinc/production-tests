#!/bin/bash

source lib/utils.sh

#----------------------------------#
# Main section                     #
#----------------------------------#

init_pins A

./lib/flash.sh "m2k"
