#!/bin/bash
set -e

#----------------------------------#
# Global definitions section       #
#----------------------------------#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh
source $SCRIPT_DIR/lib/update_release.sh

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
		echo_red "No 'apt-get' found; cannot install dependencies"
		return 0
	}
	sudo_required
	sudo -s <<-EOF
	apt-get -y update
	apt-get -y install bc sshpass unzip \
		cmake build-essential git bison flex \
		expect usbutils screen python-smbus python-matplotlib \
		cython wget curl libusb-dev libusb-1.0-0-dev \
		libboost-dev openssh-server i2c-tools pmount htpdate
	EOF
	sudo /etc/init.d/htpdate restart
}

setup_raspi_config() {
	sudo -s <<-EOF
		if type raspi-config &> /dev/null ; then
			raspi-config nonint do_i2c 0 # enable I2C
			raspi-config nonint do_ssh 0 # enable SSH
		fi
	EOF
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

__build_cmake() {
	local prj="$1"
	local args="$2"

	pushd work/$prj
	mkdir -p build
	pushd build

	cmake $args ..
	make -j3

	popd
	popd
}

setup_build_libsmu() {
	__download_github_common libsmu
	__build_cmake libsmu
}

# Note: this is no longer used; but we're keeping around as a reference in case
#       it's needed again
__disabled_jig_ssh_key_setup() {
	mkdir -p "$HOME/.ssh"
	cat "$SCRIPT_DIR/config/jig_id.pub" >> "$HOME/.ssh/authorized_keys"
	sudo chown "$USER.$USER" "$HOME/.ssh/authorized_keys"
	chmod 0600 "$HOME/.ssh/authorized_keys"

	sudo chown "$USER.$USER" "$SCRIPT_DIR/config/jig_id"
	chmod 0600 "$SCRIPT_DIR/config/jig_id"
}

setup_autostart_config() {
	if type ufw &> /dev/null ; then
		sudo ufw enable
		sudo ufw allow ssh
	fi

	sed -i -e "/^# --- added by setup_env.sh/,/^# --- end setup_env.sh/d" "$HOME/.bashrc"

	cat >> $HOME/.bashrc <<-EOF
# --- added by setup_env.sh

export SCRIPT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/lib/utils.sh"

if [ -z "\$SSH_TTY" ] ; then
	sudo screen -S M1k  $SCRIPT_DIR/adalm_1000_factory.sh tty
else
	echo_red "This looks like an SSH context, will not run M1k script"
fi
# --- end setup_env.sh
	EOF
}

setup_disable_sudo_passwd() {
	sudo_required
	sudo -s <<-EOF
		usermod -aG sudo $USER
		sed -i 's/%sudo.*/%sudo   ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
	EOF
}

setup_adafruit_pitft_install() {
	# Select configuration:
	# 1. PiTFT 2.4", 2.8" or 3.2" resistive (240x320)
	# 2. PiTFT 2.2" no touch (240x320)
	# 3. PiTFT 2.8" capacitive touch (240x320)
	# 4. PiTFT 3.5" resistive touch (320x480)
	# 5. Quit without installing
	local pitft_entry=2

	# SELECT 1-5: Select rotation:
	# 1. 90 degrees (landscape)
	# 2. 180 degrees (portait)
	# 3. 270 degrees (landscape)
	# 4. 0 degrees (portait)
	local rotation=2

	# Would you like the console to appear on the PiTFT display?"
	local console_pitft=y

	# Would you like the HDMI display to mirror to the PiTFT display?"; (requires `console_pitfy=n`)
	local hdmi_mirror=y

	# Reboot at the end
	local reboot=n

	local cmd_seq="${pitft_entry}\n${rotation}\n${console_pitft}\n"
	if [ "$console_pitft" == "n" ] ; then
		cmd_seq="${cmd_seq}${hdmi_mirror}\n"
	fi

	cmd_seq="${cmd_seq}${reboot}\n"

	local tmpfile=$(mktemp)
	# lock version of script, so that the menu commands we automate are the same
	local ver=407c4089f46c9e6e49b08418786a4b846d80e384
	sudo -s <<-EOF
		wget https://raw.githubusercontent.com/adafruit/Raspberry-Pi-Installer-Scripts/${ver}/adafruit-pitft.sh -O $tmpfile
		chmod +x $tmpfile
		printf "${cmd_seq}" | $tmpfile -u $HOME
		rm -f $tmpfile
	EOF
}

setup_misc_profile_cleanup() {
	touch $HOME/.hushlogin # tell login to not print system info
	sudo -s <<-EOF
		# Kind of hacky, but it works ; this will remove the warnings
		# about the SSH password & Wi-Fi on console login
		if [ -f /etc/profile.d/sshpwd.sh ] ; then
			echo -n > /etc/profile.d/sshpwd.sh
			echo -n > /etc/profile.d/wifi-country.sh
		fi
	EOF
}

setup_usb_automount() {
	sudo -s <<-EOF
		cp $SCRIPT_DIR/config/usbstick-handler@.service /lib/systemd/system/
		cp $SCRIPT_DIR/config/automount /usr/local/bin/automount
		cp $SCRIPT_DIR/config/usbstick.rules /etc/udev/rules.d/usbstick.rules
		chmod +x /usr/local/bin/automount
	EOF
}

setup_release_files() {
	$SCRIPT_DIR/update_${BOARD}_release.sh
}

setup_zerotier_vpn() {
	curl -s https://install.zerotier.com/ | sudo bash
	sudo zerotier-cli join d3ecf5726dcec114
}

#----------------------------------#
# Main section                     #
#----------------------------------#

# FIXME: board is hard-coded for this script
BOARD=m1k
TARGET="$1"

if [ `id -u` == "0" ]
then
	echo_red "This script should not be run as root" 1>&2
	exit 1
fi

pushd $SCRIPT_DIR

STEPS="disable_sudo_passwd usb_automount misc_profile_cleanup apt_install_prereqs"
STEPS="$STEPS raspi_config build_libsmu autostart_config adafruit_pitft_install"
STEPS="$STEPS release_files zerotier_vpn"

RAN_ONCE=0
for step in $STEPS ; do
	if [ "$TARGET" == "$step" ] || [ -z "$TARGET" ] ; then
		setup_$step
		RAN_ONCE=1
	fi
done

if [ "$RAN_ONCE" == "0" ] ; then
	echo_red "Invalid build target '$TARGET'; valid targets are:"
	for step in $STEPS ; do
		echo_red "    $step"
	done
fi

popd
