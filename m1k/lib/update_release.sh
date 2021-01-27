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

download_to() {
	local url="$1"
	local file="$2"

	wget "$url" -O "$file" || {
		echo_red "Download has failed..."
		rm -f "$file"
		return 1
	}

	return 0
}

download_and_unzip_to() {
	local url="$1"
	local dir="$2"

	local tmp_file="$(mktemp)"

	download_to "$url" "$tmp_file" || return 1

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

update_release() {
	check_system_requirements || return 1

	local RELEASE_DIR="$1"

	# make sure the path is absolute
	RELEASE_DIR="$(readlink -f $RELEASE_DIR)"

	[ -d "$RELEASE_DIR" ] || {
		echo_red "No valid release dir provided"
		return 1
	}

	local VERSION="$2"

	[ -n "$VERSION" ] || {
		echo_red "No version provided"
		return 1
	}

	local FW_URL="$3"

	[ -n "$FW_URL" ] || {
		echo_red "No download URL provided for firmware package"
		return 1
	}

	local FW_FILE="$4"

	[ -n "$FW_FILE" ] || {
		echo_red "No firmware file-name provided"
		return 1
	}

	echo_green "Note: using release dir '$RELEASE_DIR'"
	echo_red "Warning: your current release files will be removed from '$RELEASE_DIR'"
	echo_red "Press Ctrl + C to quit"
	sleep 3

	local temp_dir="$(mktemp -d)"

	for url in $FW_URL ; do
		echo_green "Downloading from '$url' to '$temp_dir'"
		download_to "$url" "$temp_dir/$FW_FILE" || return 1
	done

	# Sanity check that we have all release files, before going forward
	rm -f $RELEASE_DIR/*
	mv -f $temp_dir/* $RELEASE_DIR
	rmdir $temp_dir
	echo "$VERSION" > "$RELEASE_DIR/version"

	return 0
}
