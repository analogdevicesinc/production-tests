#!/bin/bash
set -e

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source lib/utils.sh

UDEV_RULES_FILE="50-ftdi-test.rules"

UDEV_SECTION='
SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", ATTRS{serial}==\"Test-Slot-A\", SYMLINK+=\"ttyTest-A%n\"
SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", ATTRS{serial}==\"Test-Slot-B\", SYMLINK+=\"ttyTest-B%n\"
SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", ATTRS{serial}==\"Test-Slot-C\", SYMLINK+=\"ttyTest-C%n\"
SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", ATTRS{serial}==\"Test-Slot-D\", SYMLINK+=\"ttyTest-D%n\"
SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", GROUP=\"plugdev\"
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


build_ft4232h_tool() {
	local tool="ft4232h_pin_ctrl"
	local tool_c="${tool}.c"
	local tool_c="${tool}.c ad7616.c platform_drivers.c"
	local c_files
	local cflags="-I./src -Werror -Wall"
	local ldflags="-lftdi"

	[ -d "work" ] || mkdir -p work

	for c_file in $tool_c ; do
		cp -f "src/$c_file" "work/$c_file"
		c_files="$c_files work/$c_file"
	done
	gcc $c_files -o "work/$tool" $cflags $ldflags
}

build_libiio() {
	[ -d work ] || mkdir -p work
	[ -d work/libiio ] || \
		git clone \
			https://github.com/analogdevicesinc/libiio \
			work/libiio
	pushd work/libiio
	mkdir -p build
	pushd build

	cmake ..
	make

	popd
	popd
}

build_plutosdr_scripts() {
	local cflags="-I../libiio -Wall -Wextra"
	local ldflags="-L../libiio/build -lfftw3 -lpthread -liio -lm"

	[ -d work ] || mkdir -p work

	build_libiio

	[ -d work/plutosdr_scripts ] || \
		git clone \
			https://github.com/analogdevicesinc/plutosdr_scripts \
			work/plutosdr_scripts

	pushd work/plutosdr_scripts

	gcc -g -o cal_ad9361 cal_ad9361.c $cflags $ldflags

	popd
}

#----------------------------------#
# Main section                     #
#----------------------------------#

enforce_root

build_ft4232h_tool

build_plutosdr_scripts

check_open_ocd_on_system

check_udev_on_system

sync_udev_rules_file
