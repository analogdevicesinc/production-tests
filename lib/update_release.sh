#!/bin/bash

#----------------------------------#
# Global definitions section       #
#----------------------------------#

source $SCRIPT_DIR/lib/utils.sh

#----------------------------------#
# Functions section                #
#----------------------------------#

check_system_requirements() {
	type wget &> /dev/null || {
                echo_red "You need the 'wget' utility on your system"
		return 1
	}
	type unzip &> /dev/null || {
		echo_red "You need the 'unzip' utility on your system"
		return 1
	}
}

download_and_unzip_to() {
	local url="$1"
	local dir="$2"

	local tmp_file="$(mktemp)"

	wget "$url" -O "$tmp_file" || {
		echo_red "Download has failed..."
		rm -f "$tmp_file"
		return 1
	}

	unzip "$tmp_file" -d "$dir" || {
		echo_red "Unzip has failed..."
		rm -f "$tmp_file"
		return 1
	}
	rm -f "$tmp_file"

	return 0
}

get_latest_release() {
	curl --silent "https://api.github.com/repos/$1/releases/latest" |
	grep '"tag_name":' |
	sed -E 's/.*"([^"]+)".*/\1/'
}

#----------------------------------#
# Main section                     #
#----------------------------------#

update_release() {

	check_system_requirements || return 1

	local RELEASE_DIR="$1"

	# make sure the path is absolute
	RELEASE_DIR="$(readlink -f $RELEASE_DIR)"

	[ -d "$RELEASE_DIR" ] || {
		echo_red "No valid release dir provided"
		return 1
	}

	local FIRMWARE_DFU_FILE="$2"

	[ -n "$FIRMWARE_DFU_FILE" ] || {
		echo_red "No firmware DFU filename provided"
		return 1
	}

	local FW_URL="$3"

	[ -n "$FW_URL" ] || {
		echo_red "No download URL provided for firmware package"
		return 1
	}

	local FW_BOOTSTRAP_URL="$4"

	[ -n "$FW_BOOTSTRAP_URL" ] || {
		echo_red "No download URL provided for jtag bootstrap package"
		return 1
	}

	echo_green "Note: using release dir '$RELEASE_DIR'"
	echo_red "Warning: your current release files will be removed from '$RELEASE_DIR'"
	echo_red "Press Ctrl + C to quit"
	sleep 3

	local temp_dir="$(mktemp -d)"

	for url in $FW_URL $FW_BOOTSTRAP_URL ; do
		echo_green "Downloading and unzipping from '$url' to '$temp_dir'"
		download_and_unzip_to "$url" "$temp_dir" || return 1
	done

	# Sanity check that we have all release files, before going forward
	rm -f $RELEASE_DIR/*
	mv -f $temp_dir/* $RELEASE_DIR
	rmdir $temp_dir

	# Patch ps7_init.tcl
	sed -i -e "s/variable PCW_SILICON_VER_1_0/set PCW_SILICON_VER_1_0 \"0x0\"/g" \
		-e "s/variable PCW_SILICON_VER_2_0/set PCW_SILICON_VER_2_0 \"0x1\"/g" \
		-e "s/variable PCW_SILICON_VER_3_0/set PCW_SILICON_VER_3_0 \"0x2\"/g" \
		-e "/configparams/d" \
		-e "s/variable APU_FREQ/set APU_FREQ 666666666/g" $RELEASE_DIR/ps7_init.tcl

	return 0
}
