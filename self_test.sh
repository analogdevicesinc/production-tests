#!/bin/bash

# Wrapper script for calling the ADC self-test functionality.
# Maybe later more stuff can be added.
#
# Can be called with:  ./self_test.sh

source config.sh

self_test || {
	echo_red "Self test failed"
	exit 1
}
exit 0
