#!/bin/bash
set -e

#----------------------------------#
# Global definitions section       #
#----------------------------------#

SCRIPT_DIR="$(readlink -f $(dirname $0))"

source $SCRIPT_DIR/lib/utils.sh

SUPPORTED_BOARDS="FMCBRIDGE"

INIT_PINS_SCRIPT="$SCRIPT_DIR"/init.sh

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
	apt-get -y install bc sshpass libfftw3-dev librsvg2-dev libgtk-3-dev \
		cmake build-essential git libxml2 libxml2-dev bison flex \
		expect usbutils dfu-util screen libaio-dev libglib2.0-dev picocom \
		wget unzip curl cups cups-bsd intltool itstool libxml2-utils \
		libusb-dev libusb-1.0-0-dev htpdate xfce4-terminal libiec16022-dev \
		openssh-server gpg dnsmasq libcurl4-gnutls-dev libqrencode-dev pv \
		python3-pytest python3-libiio python3-scapy python3-scipy
	/etc/init.d/htpdate restart
	EOF
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


setup_bashrc_update() {
	sed -i -e "/^# --- added by setup_env.sh/,/^# --- end setup_env.sh/d" "$HOME/.bashrc"

	cat >> $HOME/.bashrc <<-EOF
# --- added by setup_env.sh
export SCRIPT_DIR="$SCRIPT_DIR"
source "$SCRIPT_DIR/vars.sh"
export IIOD_REMOTE=analog.local
export PATH=/usr/lib/:$PATH
# --- end setup_env.sh
	EOF
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

STEPS="bashrc_update disable_sudo_passwd misc_profile_cleanup raspi_config xfce4_power_manager_settings"
STEPS="$STEPS thunar_volman disable_lxde_automount apt_install_prereqs"
STEPS="$STEPS write_autostart_config"
STEPS="$STEPS pi_boot_config disable_pi_screen_blanking"

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
