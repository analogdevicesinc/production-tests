#!/bin/bash

echo_red()   { printf "\033[1;31m$*\033[m\n"; }

#----------------------------------#
# Main section                     #
#----------------------------------#

./common_flash.sh "$(pwd)/release/m2k" "m2k.dfu"
