#!/bin/bash

#----------------------------------#
# Main section                     #
#----------------------------------#

./common_preflash.sh "pluto" || exit 1

./common_flash.sh "pluto" || exit 1
