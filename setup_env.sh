#!/bin/bash
set -e

#----------------------------------#
# Global definitions section       #
#----------------------------------#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh
source $SCRIPT_DIR/lib/update_release.sh

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

setup_apt_install_prereqs() {
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
		wget unzip curl \
		libusb-dev libusb-1.0-0-dev htpdate xfce4-terminal \
		openssh-server gpg
	/etc/init.d/htpdate restart
	EOF
}

build_openocd_0_10_0() {
	local url=https://sourceforge.net/projects/openocd/files/openocd/0.10.0/openocd-0.10.0.tar.gz/download

	mkdir -p work
	wget "$url" -O work/openocd-0.10.0.tar.gz

	sudo apt-get -y install libjim-dev

	pushd work/
	tar -xvf openocd-0.10.0.tar.gz
	pushd openocd-0.10.0

	./configure --enable-ftdi --disable-internal-jimtcl --prefix="$(pwd)/installed"
	make -j3
	make install

	popd
	popd
}

setup_openocd() {
	openocd_is_minimum_required || {
		echo_red "OpenOCD needs to be at least version 0.10.0"
		# if  we have apt-get, we can try to build it and install deps too
		type apt-get &> /dev/null || exit 1
		build_openocd_0_10_0
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
setup_sync_udev_rules_file() {
	sudo_required
	check_udev_on_system || exit 1
	sudo -s <<-EOF
		echo -n "$UDEV_SECTION" > "/etc/udev/rules.d/$UDEV_RULES_FILE"
		echo "$UDEV_SECTION_PINS" >> "/etc/udev/rules.d/$UDEV_RULES_FILE"
		udevadm control --reload-rules
		udevadm trigger
	EOF
	return $?
}

__common_build_tool() {
	local c_files
	mkdir -p work

	for c_file in $tool_c ; do
		cp -f "src/$c_file" "work/$c_file"
		c_files="$c_files work/$c_file"
	done
	gcc $c_files -o "work/$tool" $cflags $ldflags
}

setup_ft4232h_tool() {
	local tool="ft4232h_pin_ctrl"
	local tool_c="${tool}.c ad7616.c platform_drivers.c"
	local cflags="-I./src -Werror -Wall"
	local ldflags="-lftdi"

	tool_c="${tool_c} ft4232h_bitbang.c ft4232h_spi_adc.c ft4232h_spi_eeprom.c"
	tool_c="${tool_c} ft4232h_spi_gpio_exp.c"

	__common_build_tool
}

__download_github_common() {
	local gh_prj="$1"
	mkdir -p work

	local ver=$(get_latest_release analogdevicesinc/$gh_prj)
	[ -d work/$gh_prj ] || {
		if [ -z "$ver" ] ; then
			echo_red "Could not get $gh_prj release tag; cloning repo"
			git clone https://github.com/analogdevicesinc/$gh_prj work/$gh_prj
		else
			echo_green "Using latest released version '$ver' of '$gh_prj'"
			download_and_unzip_to "https://github.com/analogdevicesinc/$gh_prj/archive/${ver}.zip" "work" || {
				echo_red "Could not download $gh_prj..."
				exit 1
			}
			mv -f work/${gh_prj}* work/$gh_prj
		fi
	}
}

build_libiio() {
	__download_github_common libiio

	pushd work/libiio
	mkdir -p build
	pushd build

	cmake ..
	make -j3

	popd
	popd
}

setup_plutosdr_scripts() {
	local cflags="-I../libiio -Wall -Wextra"
	local ldflags="-L../libiio/build -lfftw3 -lpthread -liio -lm"

	if [ "${BOARD}" != "pluto" ] ; then
		echo_blue "Not installing plutosdr_scripts ; board needs to be 'pluto'"
		return 0
	fi

	build_libiio

	[ -d work/plutosdr_scripts ] || \
		git clone \
			https://github.com/analogdevicesinc/plutosdr_scripts \
			work/plutosdr_scripts

	pushd work/plutosdr_scripts

	gcc -g -o cal_ad9361 cal_ad9361.c $cflags $ldflags

	popd
}

setup_scopy() {
	if [ "${BOARD}" != "m2k" ] ; then
		echo_blue "Not installing scopy ; board needs to be 'm2k'"
		return 0
	fi

	__download_github_common scopy

	pushd work/scopy

	./CI/travis/before_install_linux.sh
	./CI/travis/make.sh

	popd
}

setup_write_autostart_config() {
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

	local font_size="16"
	if [ "$BOARD" == "pluto" ] ; then
		font_size=14
	fi

	# FIXME: see about generalizing this to other desktops [Gnome, MATE, LXDE, etc]
	cat > $autostart_path/test-jig-tool.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=test-jig-tool
Comment=test-jig-tool
Exec=sudo xfce4-terminal --font="DejaVu Sans Mono $font_size" --fullscreen --hide-borders --hide-scrollbar --hide-menubar -x $SCRIPT_DIR/production_${BOARD}.sh
OnlyShowIn=XFCE;LXDE
StartupNotify=false
Terminal=false
Hidden=false
	EOF

	if type ufw &> /dev/null ; then
		sudo ufw enable
		sudo ufw allow ssh
	fi

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

	cat > $autostart_path/auto-upload-logs.desktop <<-EOF
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=auto-save-logs
Comment=auto-save-logs
Exec=/bin/bash $SCRIPT_DIR/autoupload_logs.sh
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

xfconf_has_cap() {
	type xfconf-query &> /dev/null || return 1
	if xfconf-query -l | grep -q xfce4-power-manager ; then
		return 0
	fi
	return 1
}

setup_xfce4_power_manager_settings() {
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
	xfconf_has_cap xfce4-power-manager || return 0
	for sett in $pm_sett ; do
		local key="$(echo $sett | cut -d'=' -f1)"
		local val="$(echo $sett | cut -d'=' -f2)"
		xfconf-query -c xfce4-power-manager -p $key -s $val
	done
}

setup_disable_sudo_passwd() {
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
	xfconf_has_cap thunar-volman || return 0
	for sett in $configs ; do
		local key="$(echo $sett | cut -d'=' -f1)"
		local val="$(echo $sett | cut -d'=' -f2)"
		xfconf-query -c thunar-volman -p $key -s $val
	done
}

setup_disable_lxde_automount() {
	[ -d "$HOME/.config/pcmanfm" ] || return 0

	pushd "$HOME/.config/pcmanfm/"
	for cfg_file in $(find . -name pcmanfm.conf) ; do
		sed 's/autorun=1/autorun=0/g' -i $cfg_file
	done

	popd
}

setup_pi_boot_config() {
	[ "$BOARD" == "pluto" ] || return 0

	[ -f /boot/config.txt ] || return 0

	local tmp=$(mktemp)
	cat >> $tmp <<-EOF
# --- added by setup_env.sh
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=1
max_usb_current=1

dtoverlay=pi3-disable-wifi
dtoverlay=pi3-disable-bt
# --- end setup_env.sh
	EOF

	sudo -s <<-EOF
		sed -i -e "/^# --- added by setup_env.sh/,/^# --- end setup_env.sh/d" /boot/config.txt
		cat $tmp >> /boot/config.txt
		rm -f $tmp
	EOF
}

setup_disable_pi_screen_blanking() {
	local pi_serial="$(pi_serial)"
	[ -n "$pi_serial" ] || return 0

	local tmp=$(mktemp)
	cat >> $tmp <<-EOF
# --- added by setup_env.sh
[SeatDefaults]
xserver-command=X -s 0 -dpms
# --- end setup_env.sh
	EOF

	sudo -s <<-EOF
		sed -i -e "/^# --- added by setup_env.sh/,/^# --- end setup_env.sh/d" /etc/lightdm/lightdm.conf
		cat $tmp >> /etc/lightdm/lightdm.conf
	EOF
}

setup_raspi_config() {
	sudo -s <<-EOF
		if type raspi-config &> /dev/null ; then
			raspi-config nonint do_ssh 0 # enable SSH
		fi
	EOF
}

setup_misc_profile_cleanup() {
	touch $HOME/.hushlogin # tell login to not print system info
	sudo -s <<-EOF
		# Kind of hacky, but it works ; this will remove the warnings
		# about the SSH password & Wi-Fi on console login
		[ ! -f /etc/profile.d/sshpwd.sh ] || echo -n > /etc/profile.d/sshpwd.sh
		[ ! -f /etc/profile.d/wifi-country.sh ] || echo -n > /etc/profile.d/wifi-country.sh
		[ ! -f /etc/xdg/lxsession/LXDE-pi/sshpwd.sh ] || echo -n > /etc/xdg/lxsession/LXDE-pi/sshpwd.sh
	EOF
}

setup_release_files() {
	./update_${BOARD}_release.sh
}

setup_usbreset_tool() {
	local tool="usbreset"
	local tool_c="${tool}.c"
	local cflags="-I./src -Werror -Wall"
	local ldflags=""

	__common_build_tool
}

setup_zerotier_vpn() {
	if ! curl -s 'https://pgp.mit.edu/pks/lookup?op=get&search=0x1657198823E52A61' | gpg --import ; then
		return 1
	fi
	local z="$(curl -s https://install.zerotier.com/ | gpg)"
	[ -n "$z" ] || return 1
	echo "$z" | sudo bash
	sudo zerotier-cli join d3ecf5726dcec114
}

#----------------------------------#
# Main section                     #
#----------------------------------#

BOARD="$1"
TARGET="$2"

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

STEPS="disable_sudo_passwd misc_profile_cleanup raspi_config xfce4_power_manager_settings"
STEPS="$STEPS thunar_volman disable_lxde_automount apt_install_prereqs openocd ft4232h_tool"
STEPS="$STEPS scopy plutosdr_scripts sync_udev_rules_file write_autostart_config"
STEPS="$STEPS pi_boot_config disable_pi_screen_blanking usbreset_tool release_files"
STEPS="$STEPS zerotier_vpn"

RAN_ONCE=0
for step in $STEPS ; do
	if [ "$TARGET" == "$step" ] || [ "$TARGET" == "jig" ] ; then
		setup_$step
		RAN_ONCE=1
	fi
done

if [ "$RAN_ONCE" == "0" ] ; then
	echo_red "Invalid build target '$TARGET'; valid targets are 'jig' or:"
	for step in $STEPS ; do
		echo_red "    $step"
	done
fi

popd
