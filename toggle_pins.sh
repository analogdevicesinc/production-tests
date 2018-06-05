#!/bin/bash

source config.sh

valid_ftdi_channel "$1" || {
	echo_red "Invalid FTDI channel '$1'"
	exit 1
}

toggle_pins $@
