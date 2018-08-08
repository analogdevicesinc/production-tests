#!/bin/bash
set -e

#----------------------------------#
# Global definitions section       #
#----------------------------------#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh

SUPPORTED_BOARDS="pluto m2k"

PATH="$SCRIPT_DIR/work/openocd-0.10.0/installed/bin:$PATH"

UDEV_RULES_FILE="50-ftdi-test.rules"

INIT_PINS_SCRIPT="$SCRIPT_DIR"/init.sh

UDEV_SECTION='
SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", ATTRS{serial}==\"Test-Slot-A\", SYMLINK+=\"ttyTest-A%n\"
SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", ATTRS{serial}==\"Test-Slot-B\", SYMLINK+=\"ttyTest-B%n\"
SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", ATTRS{serial}==\"Test-Slot-C\", SYMLINK+=\"ttyTest-C%n\"
SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", ATTRS{serial}==\"Test-Slot-D\", SYMLINK+=\"ttyTest-D%n\"
SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"0456\", ATTRS{idProduct}==\"f001\", MODE=\"660\", GROUP=\"plugdev\"
'

UDEV_SECTION_PINS="SUBSYSTEM==\\\"usb\\\", ATTRS{idVendor}==\\\"0456\\\", ATTRS{idProduct}==\\\"f001\\\", MODE=\\\"660\\\", RUN+=\\\"$INIT_PINS_SCRIPT\\\""

#----------------------------------#
# Functions section                #
#----------------------------------#

sudo_required() {
	type sudo &> /dev/null || {
		echo_red "'sudo' utility required"
		exit 1
	}
}

apt_install_prereqs() {
	type apt-get &> /dev/null || {
		echo "No 'apt-get' found; cannot install dependencies"
		return 0
	}
	sudo_required
	sudo -s <<-EOF
	apt-get -y update
	apt-get -y install libftdi-dev bc sshpass openocd \
		cmake build-essential git libxml2-dev bison flex \
		libfftw3-dev expect usbutils dfu-util screen \
		wget unzip curl qt5-default qttools5-dev \
		qtdeclarative5-dev libqt5svg5-dev libqt5opengl5-dev
	EOF
}

build_openocd_0_10_0() {
	local url=https://sourceforge.net/projects/openocd/files/openocd/0.10.0/openocd-0.10.0.tar.gz/download

	mkdir -p work
	wget "$url" -O work/openocd-0.10.0.tar.gz

	apt-get -y install libjim-dev

	pushd work/
	tar -xvf openocd-0.10.0.tar.gz
	pushd openocd-0.10.0

	./configure --enable-ftdi --disable-internal-jimtcl --prefix="$(pwd)/installed"
	make -j3
	make install

	popd
	popd
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
	sudo_required
	sudo -s <<-EOF
		echo -n "$UDEV_SECTION" > "/etc/udev/rules.d/$UDEV_RULES_FILE"
		echo "$UDEV_SECTION_PINS" >> "/etc/udev/rules.d/$UDEV_RULES_FILE"
		udevadm control --reload-rules
		udevadm trigger
	EOF
	return $?
}


build_ft4232h_tool() {
	local tool="ft4232h_pin_ctrl"
	local tool_c="${tool}.c ad7616.c platform_drivers.c"
	local c_files
	local cflags="-I./src -Werror -Wall"
	local ldflags="-lftdi"

	tool_c="${tool_c} ft4232h_bitbang.c ft4232h_spi_adc.c ft4232h_spi_eeprom.c"
	tool_c="${tool_c} ft4232h_spi_gpio_exp.c"

	mkdir -p work

	for c_file in $tool_c ; do
		cp -f "src/$c_file" "work/$c_file"
		c_files="$c_files work/$c_file"
	done
	gcc $c_files -o "work/$tool" $cflags $ldflags
}

build_libiio() {
	mkdir -p work
	[ -d work/libiio ] || \
		git clone \
			https://github.com/analogdevicesinc/libiio \
			work/libiio
	pushd work/libiio
	mkdir -p build
	pushd build

	cmake ..
	make -j3

	popd
	popd
}

build_plutosdr_scripts() {
	local cflags="-I../libiio -Wall -Wextra"
	local ldflags="-L../libiio/build -lfftw3 -lpthread -liio -lm"

	mkdir -p work

	build_libiio

	[ -d work/plutosdr_scripts ] || \
		git clone \
			https://github.com/analogdevicesinc/plutosdr_scripts \
			work/plutosdr_scripts

	pushd work/plutosdr_scripts

	gcc -g -o cal_ad9361 cal_ad9361.c $cflags $ldflags

	popd
}

build_scopy() {
	mkdir -p work
	[ -d work/scopy ] || \
		git clone \
			https://github.com/analogdevicesinc/scopy \
			work/scopy
	pushd work/scopy

	./CI/travis/before_install_linux.sh
	./CI/travis/make.sh

	popd
}

write_autostart_config() {
	local autostart_path="$HOME/.config/autostart"

	# FIXME: see about generalizing this to other desktops [Gnome, MATE, LXDE, etc]
	cat > $autostart_path/test-jig-tool.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=test-jig-tool
Comment=test-jig-tool
Exec=sudo xfce4-terminal --fullscreen --hide-borders --hide-scrollbar --hide-menubar -x $SCRIPT_DIR/production_${BOARD}.sh
OnlyShowIn=XFCE;
StartupNotify=false
Terminal=false
Hidden=false
	EOF

}

board_is_supported() {
	local board="$1"
	[ -n "$board" ] || return 1
	for b in $SUPPORTED_BOARDS ; do
		[ "$b" != "$board" ] || return 0
	done
	return 1
}

#----------------------------------#
# Main section                     #
#----------------------------------#

BOARD="$1"

board_is_supported "$BOARD" || {
	echo_red "Board '$BOARD' is not supported by this script"
	echo_red "   Supported boards are '$SUPPORTED_BOARDS'"
	exit 1
}

pushd $SCRIPT_DIR

apt_install_prereqs

openocd_is_minimum_required || {
	echo_red "OpenOCD needs to be at least version 0.10.0"
	# if  we have apt-get, we can try to build it and install deps too
	type apt-get &> /dev/null || exit 1
	build_openocd_0_10_0
}

build_ft4232h_tool

build_plutosdr_scripts

build_scopy

check_udev_on_system

sync_udev_rules_file

./update_${BOARD}_release.sh

write_autostart_config

popd
