#!/bin/bash

echo_red()   { printf "\033[1;31m$*\033[m\n"; }

#----------------------------------#
# Main section                     #
#----------------------------------#

./common_flash.sh "m2k"
