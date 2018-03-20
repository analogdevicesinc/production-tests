#!/bin/bash
set -e

#----------------------------------#
# Global definitions section       #
#----------------------------------#

UDEV_RULES_FILE="50-ftdi-test.rules"

UDEV_SECTION='
SUBSYSTEM=="tty", ATTRS{idVendor}=="0456", ATTRS{idProduct}=="f001", MODE="660", ATTRS{serial}=="Test-Slot-A", SYMLINK+="ttyTest-A%n"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0456", ATTRS{idProduct}=="f001", MODE="660", ATTRS{serial}=="Test-Slot-B", SYMLINK+="ttyTest-B%n"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0456", ATTRS{idProduct}=="f001", MODE="660", ATTRS{serial}=="Test-Slot-C", SYMLINK+="ttyTest-C%n"
SUBSYSTEM=="tty", ATTRS{idVendor}=="0456", ATTRS{idProduct}=="f001", MODE="660", ATTRS{serial}=="Test-Slot-D", SYMLINK+="ttyTest-D%n"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0456", ATTRS{idProduct}=="f001", MODE="660", GROUP="plugdev"
'

#----------------------------------#
# Functions section                #
#----------------------------------#

check_open_ocd_on_system() {
	type openocd &> /dev/null || {
		echo "Your system does not have openocd installed"
		exit 1
	}
}

check_udev_on_system() {
	[ -d "/etc/udev/rules.d" ] || {
		echo "Your system does not have a '/etc/udev/rules.d'"
		exit 1
	}

	type udevadm &> /dev/null || {
		echo "No 'udevadm' found on system"
		exit 1
	}

	return 0
}

# sync udev rules file
sync_udev_rules_file() {
	sudo -s <<-EOF
		echo -n "$UDEV_SECTION" > "/etc/udev/rules.d/$UDEV_RULES_FILE"
		udevadm control --reload-rules
		udevadm trigger
	EOF
	return $?
}

#----------------------------------#
# Main section                     #
#----------------------------------#

check_open_ocd_on_system

check_udev_on_system

sync_udev_rules_file
