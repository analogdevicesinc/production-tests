#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

COMMON_RELEASE_FILES="boot.dfu u-boot.elf uboot-env.dfu ps7_init.tcl"

# HOST x86 Config
TTYUSB=ttyUSB0

# RPI Config
#havegpio=1
#GDB=gdb
#TTYUSB=ttyS0

FT4232H_SERIAL="Test-Slot-A"

#----------------------------------#
# Functions section                #
#----------------------------------#

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

is_ft4232h() {
	lsusb -v -d 0456:f001 &> /dev/null
}

disable_all_usb_ports() {
	./work/ft4232h_pin_ctrl --serial "$FT4232H_SERIAL" --channel A # will set all pins to low
}

enable_all_usb_ports() {
	./work/ft4232h_pin_ctrl --serial "$FT4232H_SERIAL" --channel A pin5 pin6
}

enable_usb_port_1() {
	./work/ft4232h_pin_ctrl --serial "$FT4232H_SERIAL" --channel A pin5
}

enable_usb_port_2() {
	./work/ft4232h_pin_ctrl --serial "$FT4232H_SERIAL" --channel A pin6
}

