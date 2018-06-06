#!/bin/bash

#----------------------------------#
# Main section                     #
#----------------------------------#

./lib/preflash.sh "pluto" || exit 1

./lib/flash.sh "pluto" || exit 1
