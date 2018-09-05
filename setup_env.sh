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
		qtdeclarative5-dev libqt5svg5-dev libqt5opengl5-dev libusb-dev \
		openssh-server
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
	local configs_disable="blueman light-locker polkit-gnome-authentication-agent-1"

	configs_disable="$configs_disable print-applet pulseaudio snap-userd-autostart"
	configs_disable="$configs_disable spice-vdagent update-notifier user-dirs-update-gtk xdg-user-dirs"

	mkdir -p $autostart_path

	for cfg in $configs_disable ; do
		cat > $autostart_path/$cfg.desktop <<-EOF
[Desktop Entry]
Hidden=true
		EOF
	done

	# FIXME: see about generalizing this to other desktops [Gnome, MATE, LXDE, etc]
	cat > $autostart_path/test-jig-tool.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=test-jig-tool
Comment=test-jig-tool
Exec=sudo xfce4-terminal --font="DejaVu Sans Mono 16" --fullscreen --hide-borders --hide-scrollbar --hide-menubar -x $SCRIPT_DIR/production_${BOARD}.sh
OnlyShowIn=XFCE;
StartupNotify=false
Terminal=false
Hidden=false
	EOF

	sudo ufw enable
	sudo ufw allow ssh

	mkdir -p "$HOME/.ssh"
	cat "$SCRIPT_DIR/config/jig_id.pub" >> "$HOME/.ssh/authorized_keys"
	sudo chown "$USER.$USER" "$HOME/.ssh/authorized_keys"
	chmod 0600 "$HOME/.ssh/authorized_keys"

	sudo chown "$USER.$USER" "$SCRIPT_DIR/config/jig_id"
	chmod 0600 "$SCRIPT_DIR/config/jig_id"
	cat > $autostart_path/call-home.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=call-home
Comment=call-home
Exec=/bin/bash $SCRIPT_DIR/call_home
StartupNotify=false
Terminal=false
Hidden=false
	EOF

	cat > $autostart_path/auto-save-logs.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=auto-save-logs
Comment=auto-save-logs
Exec=sudo /bin/bash $SCRIPT_DIR/autosave_logs.sh
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

xfce4_power_manager_settings() {
	local pm_sett="/xfce4-power-manager/blank-on-ac=0
		/xfce4-power-manager/blank-on-battery=0
		/xfce4-power-manager/brightness-switch=0
		/xfce4-power-manager/brightness-switch-restore-on-exit=1
		/xfce4-power-manager/dpms-enabled=false
		/xfce4-power-manager/dpms-on-ac-off=60
		/xfce4-power-manager/dpms-on-ac-sleep=20
		/xfce4-power-manager/dpms-on-battery-off=30
		/xfce4-power-manager/dpms-on-battery-sleep=15
		/xfce4-power-manager/lock-screen-suspend-hibernate=true
		/xfce4-power-manager/logind-handle-lid-switch=false
		/xfce4-power-manager/power-button-action=4
		/xfce4-power-manager/show-panel-label=0"
	for sett in $pm_sett ; do
		local key="$(echo $sett | cut -d'=' -f1)"
		local val="$(echo $sett | cut -d'=' -f2)"
		xfconf-query -c xfce4-power-manager -p $key -s $val
	done
}

disable_sudo_passwd() {
	sudo_required
	sudo -s <<-EOF
		if ! grep -q $USER /etc/sudoers ; then
			echo "$USER	ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
		fi
	EOF
}

setup_thunar_volman() {
	local configs="/autobrowse/enabled=false
		/autoburn/enabled=false
		/autoipod/enabled=false
		/autokeyboard/enabled=false
		/automount-drives/enabled=true
		/automount-media/enabled=true
		/automouse/enabled=false
		/autoopen/enabled=false
		/autophoto/enabled=false
		/autoplay-audio-cds/enabled=false
		/autoplay-video-cds/enabled=false
		/autoprinter/enabled=false
		/autorun/enabled=false
		/autotablet/enabled=false"
	for sett in $configs ; do
		local key="$(echo $sett | cut -d'=' -f1)"
		local val="$(echo $sett | cut -d'=' -f2)"
		xfconf-query -c thunar-volman -p $key -s $val
	done
}

#----------------------------------#
# Main section                     #
#----------------------------------#

BOARD="$1"

if [ `id -u` == "0" ]
then
	echo_red "This script should not be run as root" 1>&2
	exit 1
fi

board_is_supported "$BOARD" || {
	echo_red "Board '$BOARD' is not supported by this script"
	echo_red "   Supported boards are '$SUPPORTED_BOARDS'"
	exit 1
}

pushd $SCRIPT_DIR

disable_sudo_passwd

xfce4_power_manager_settings

setup_thunar_volman

apt_install_prereqs

openocd_is_minimum_required || {
	echo_red "OpenOCD needs to be at least version 0.10.0"
	# if  we have apt-get, we can try to build it and install deps too
	type apt-get &> /dev/null || exit 1
	build_openocd_0_10_0
}

build_ft4232h_tool

build_scopy

build_plutosdr_scripts

check_udev_on_system

sync_udev_rules_file

./update_${BOARD}_release.sh

write_autostart_config

popd
